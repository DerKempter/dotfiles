#!/usr/bin/env python3
"""Agnostic GPU temperature and status reporter for Waybar.

Supports AMD (amdgpu, radeon), Intel (i915, xe), and NVIDIA (proprietary & nouveau).
Outputs Waybar-compatible JSON.
"""

import glob
import json
import os
import subprocess
import sys


def _read_sysfs(path: str) -> str | None:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read().strip()
    except Exception:
        return None


def get_drm_gpus() -> list[dict]:
    """Detect AMD, Intel, and Nouveau GPUs exposing Linux DRM hwmon interfaces."""
    gpus = []
    for card in sorted(glob.glob("/sys/class/drm/card[0-9]*")):
        if "-" in os.path.basename(card):
            continue

        dev_dir = os.path.join(card, "device")
        hwmon_dirs = glob.glob(os.path.join(dev_dir, "hwmon/hwmon*"))
        for hwmon in hwmon_dirs:
            name = _read_sysfs(os.path.join(hwmon, "name"))
            if not name:
                continue
            name_lower = name.lower()
            if any(k in name_lower for k in ["amdgpu", "radeon", "i915", "xe", "nouveau"]):
                temp_c = None
                for t_name in ["temp1_input", "temp2_input"]:
                    t_val = _read_sysfs(os.path.join(hwmon, t_name))
                    if t_val and t_val.isdigit():
                        temp_c = int(t_val) // 1000
                        break

                if temp_c is not None:
                    busy = _read_sysfs(os.path.join(dev_dir, "gpu_busy_percent"))
                    load_str = f"{busy}%" if busy else "N/A"

                    vram_used = _read_sysfs(os.path.join(dev_dir, "mem_info_vram_used"))
                    vram_total = _read_sysfs(os.path.join(dev_dir, "mem_info_vram_total"))
                    vram_str = ""
                    if vram_used and vram_total and vram_used.isdigit() and vram_total.isdigit():
                        u_gb = int(vram_used) / (1024**3)
                        t_gb = int(vram_total) / (1024**3)
                        vram_str = f"\nVRAM: {u_gb:.1f}GiB / {t_gb:.1f}GiB"

                    display_name = name.upper()
                    tooltip = f"GPU: {display_name}\nTemp: {temp_c}°C\nUsage: {load_str}{vram_str}"
                    gpus.append({
                        "name": display_name,
                        "temp": temp_c,
                        "tooltip": tooltip,
                        "discrete": "amdgpu" in name_lower or "nouveau" in name_lower,
                    })
    return gpus


def get_nvidia_gpus() -> list[dict]:
    """Detect NVIDIA GPUs running the proprietary driver via nvidia-smi."""
    gpus = []
    try:
        out = subprocess.check_output(
            [
                "nvidia-smi",
                "--query-gpu=gpu_name,temperature.gpu,utilization.gpu,memory.used,memory.total",
                "--format=csv,noheader,nounits",
            ],
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
        if out:
            for line in out.splitlines():
                parts = [p.strip() for p in line.split(",")]
                if len(parts) >= 5:
                    gpu_name, temp_s, util_s, mem_u_s, mem_t_s = parts[:5]
                    temp_c = int(temp_s)
                    tooltip = (
                        f"GPU: {gpu_name}\n"
                        f"Temp: {temp_c}°C\n"
                        f"Usage: {util_s}%\n"
                        f"VRAM: {mem_u_s}MiB / {mem_t_s}MiB"
                    )
                    gpus.append({
                        "name": gpu_name,
                        "temp": temp_c,
                        "tooltip": tooltip,
                        "discrete": True,
                    })
    except Exception:
        pass
    return gpus


def main():
    gpus = get_drm_gpus() + get_nvidia_gpus()

    if not gpus:
        print(json.dumps({
            "text": "N/A",
            "tooltip": "No supported GPU detected",
            "class": "error",
        }))
        return

    # Prioritize discrete GPUs over integrated ones if multiple GPUs exist
    selected = next((g for g in gpus if g.get("discrete")), gpus[0])

    temp = selected["temp"]
    if temp >= 85:
        css_class = "critical"
    elif temp >= 75:
        css_class = "warning"
    else:
        css_class = "normal"

    print(json.dumps({
        "text": f"{temp}°C",
        "tooltip": selected["tooltip"],
        "class": css_class,
        "percentage": temp,
    }))


if __name__ == "__main__":
    main()
