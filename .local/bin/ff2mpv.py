#!/usr/bin/env python3
"""
ff2mpv native messaging host.
Bridges Firefox extension requests to launch mpv with a specified URL.
"""

import json
import os
import struct
import sys
import subprocess

def get_message():
    # Read the 4-byte length prefix (native byte order)
    raw_length = sys.stdin.buffer.read(4)
    if not raw_length:
        sys.exit(0)
    length = struct.unpack("@I", raw_length)[0]
    # Read the JSON payload
    message = sys.stdin.buffer.read(length).decode("utf-8")
    return json.loads(message)

def main():
    message = get_message()
    url = message.get("url")
    if not url:
        sys.exit(1)

    # Core execution arguments
    args = ["mpv", "--player-operation-mode=pseudo-gui", "--", url]

    # Spawn mpv as a background process decoupled from Firefox
    subprocess.Popen(
        args,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True
    )

    # Respond to Firefox extension to complete the native messaging handshake
    response = json.dumps({"status": "ok"}).encode("utf-8")
    sys.stdout.buffer.write(struct.pack("@I", len(response)))
    sys.stdout.buffer.write(response)
    sys.stdout.buffer.flush()

if __name__ == "__main__":
    main()
