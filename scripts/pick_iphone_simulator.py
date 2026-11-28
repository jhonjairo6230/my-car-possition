#!/usr/bin/env python3
"""Imprime el UDID de un simulador de iPhone con la versión de iOS más nueva.

Los nombres de los simuladores cambian con cada versión de Xcode, así que el
CI no puede fijar uno ("iPhone 16 Pro"…). Este script pregunta a `simctl`
cuáles hay y elige uno.

Uso:  xcrun simctl list devices available -j | python3 scripts/pick_iphone_simulator.py
"""
import json
import re
import sys


def runtime_version(runtime_id: str) -> tuple:
    """'com.apple.CoreSimulator.SimRuntime.iOS-18-2' -> (18, 2)."""
    match = re.search(r"iOS-([\d-]+)$", runtime_id)
    return tuple(int(part) for part in match.group(1).split("-")) if match else ()


def main() -> int:
    devices_by_runtime = json.load(sys.stdin)["devices"]
    ios_runtimes = sorted(
        (runtime for runtime in devices_by_runtime if runtime_version(runtime)),
        key=runtime_version,
        reverse=True,
    )
    for runtime in ios_runtimes:
        for device in devices_by_runtime[runtime]:
            if device["name"].startswith("iPhone") and device.get("isAvailable", True):
                print(device["udid"])
                return 0
    print("No hay ningún simulador de iPhone disponible", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
