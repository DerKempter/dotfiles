#!/usr/bin/env python3
import json
import os
import sys
import time
import urllib.request

CACHE_FILE = "/tmp/waybar_weather_cache.json"
CACHE_DURATION = 900  # 15 minutes cache to avoid rate limiting

WEATHER_ICONS = {
    "113": "󰖙",  # Clear / Sunny
    "116": "󰖕",  # Partly cloudy
    "119": "󰖐",  # Cloudy
    "122": "󰖐",  # Overcast
    "143": "󰖑",  # Mist
    "176": "󰖖",  # Patchy rain possible
    "179": "󰖘",  # Patchy snow possible
    "182": "󰖘",  # Patchy sleet possible
    "185": "󰖘",  # Patchy freezing drizzle
    "200": "󰖓",  # Thundery outbreaks possible
    "227": "󰖘",  # Blowing snow
    "230": "󰖘",  # Blizzard
    "248": "󰖑",  # Fog
    "260": "󰖑",  # Freezing fog
    "263": "󰖖",  # Patchy light drizzle
    "266": "󰖖",  # Light drizzle
    "281": "󰖘",  # Freezing drizzle
    "284": "󰖘",  # Heavy freezing drizzle
    "293": "󰖖",  # Patchy light rain
    "296": "󰖖",  # Light rain
    "299": "󰖖",  # Moderate rain at times
    "302": "󰖖",  # Moderate rain
    "305": "󰖖",  # Heavy rain at times
    "308": "󰖖",  # Heavy rain
    "311": "󰖘",  # Light freezing rain
    "314": "󰖘",  # Moderate/heavy freezing rain
    "317": "󰖘",  # Light sleet
    "320": "󰖘",  # Moderate/heavy sleet
    "323": "󰖘",  # Patchy light snow
    "326": "󰖘",  # Light snow
    "329": "󰖘",  # Patchy moderate snow
    "332": "󰖘",  # Moderate snow
    "335": "󰖘",  # Patchy heavy snow
    "338": "󰖘",  # Heavy snow
    "350": "󰖘",  # Ice pellets
    "353": "󰖖",  # Light rain shower
    "356": "󰖖",  # Moderate/heavy rain shower
    "359": "󰖖",  # Torrential rain shower
    "362": "󰖘",  # Light sleet showers
    "365": "󰖘",  # Moderate/heavy sleet showers
    "368": "󰖘",  # Light snow showers
    "371": "󰖘",  # Heavy snow showers
    "374": "󰖘",  # Light showers of ice pellets
    "377": "󰖘",  # Moderate/heavy ice pellets
    "386": "󰖓",  # Patchy light rain with thunder
    "389": "󰖓",  # Moderate/heavy rain with thunder
    "392": "󰖓",  # Patchy light snow with thunder
    "395": "󰖓",  # Moderate/heavy snow with thunder
}

def get_weather():
    if os.path.exists(CACHE_FILE):
        mtime = os.path.getmtime(CACHE_FILE)
        if time.time() - mtime < CACHE_DURATION:
            try:
                with open(CACHE_FILE, "r") as f:
                    return json.load(f)
            except Exception:
                pass

    try:
        req = urllib.request.Request(
            "https://wttr.in/?format=j1",
            headers={"User-Agent": "Mozilla/5.0 (Waybar Weather Client)"},
        )
        with urllib.request.urlopen(req, timeout=4) as resp:
            data = json.loads(resp.read().decode())
            with open(CACHE_FILE, "w") as f:
                json.dump(data, f)
            return data
    except Exception:
        if os.path.exists(CACHE_FILE):
            try:
                with open(CACHE_FILE, "r") as f:
                    return json.load(f)
            except Exception:
                pass
        return None

def main():
    data = get_weather()
    if not data or "current_condition" not in data or not data["current_condition"]:
        print(json.dumps({"text": "󰖐 --°C", "tooltip": "Weather data currently unavailable"}))
        return

    current = data["current_condition"][0]
    temp = current.get("temp_C", "--")
    feels_like = current.get("FeelsLikeC", temp)
    code = current.get("weatherCode", "")
    desc = current.get("weatherDesc", [{}])[0].get("value", "Unknown").strip()
    humidity = current.get("humidity", "--")
    wind_kmph = current.get("windspeedKmph", "--")
    wind_dir = current.get("winddir16Point", "")

    area_name = ""
    if "nearest_area" in data and data["nearest_area"]:
        area = data["nearest_area"][0]
        name = area.get("areaName", [{}])[0].get("value", "")
        country = area.get("country", [{}])[0].get("value", "")
        if name and country:
            area_name = f"{name}, {country}"

    icon = WEATHER_ICONS.get(code, "󰖐")

    forecast_lines = []
    if "weather" in data:
        for day in data["weather"][:2]:
            date = day.get("date", "")
            max_t = day.get("maxtempC", "--")
            min_t = day.get("mintempC", "--")
            forecast_lines.append(f"📅 {date}: {min_t}°C – {max_t}°C")

    tooltip_parts = [
        f"📍 {area_name}" if area_name else "📍 Current Location",
        f"{icon} {desc}, {temp}°C (Feels like {feels_like}°C)",
        f"💧 Humidity: {humidity}%",
        f"💨 Wind: {wind_kmph} km/h {wind_dir}",
    ]
    if forecast_lines:
        tooltip_parts.append("\n" + "\n".join(forecast_lines))

    output = {
        "text": f"{icon} {temp}°C",
        "alt": desc,
        "tooltip": "\n".join(tooltip_parts),
        "class": "weather",
    }
    print(json.dumps(output))

if __name__ == "__main__":
    main()
