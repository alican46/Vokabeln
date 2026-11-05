#!/usr/bin/env python3
"""Erzeugt die SideStore/AltStore-Quelle (source.json) für ein Release."""
import json
import os
import sys
from datetime import datetime, timezone

version, build, ipa_path, out_path = sys.argv[1:5]
repo = os.environ["GITHUB_REPOSITORY"]
notes = os.environ.get("RELEASE_NOTES", "").strip() or f"Version {version}"
base = f"https://github.com/{repo}/releases/download/v{version}"

source = {
    "name": "Ferheng",
    "identifier": "com.alican.ferheng.source",
    "subtitle": "Kurdisch lernen",
    "description": "Updates für die Ferheng-App.",
    "sourceURL": f"https://github.com/{repo}/releases/latest/download/source.json",
    "iconURL": f"{base}/icon.png",
    "tintColor": "#0D8C80",
    "apps": [
        {
            "name": "Ferheng",
            "bundleIdentifier": "com.alican.ferheng",
            "developerName": "Ferheng",
            "subtitle": "Kurdisch lernen mit System",
            "localizedDescription": (
                "Vokabeltrainer für Kurdisch: Ordner & Unterordner, Ordner zusammenfügen, "
                "Spaced Repetition, Verb-Trainer, Statistik und Grammatik-Spickzettel."
            ),
            "iconURL": f"{base}/icon.png",
            "tintColor": "#0D8C80",
            "category": "education",
            "versions": [
                {
                    "version": version,
                    "buildVersion": build,
                    "date": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                    "localizedDescription": notes,
                    "downloadURL": f"{base}/Ferheng.ipa",
                    "size": os.path.getsize(ipa_path),
                    "minOSVersion": "17.0",
                }
            ],
            "appPermissions": {"entitlements": [], "privacy": {}},
        }
    ],
    "news": [],
}

with open(out_path, "w", encoding="utf-8") as f:
    json.dump(source, f, ensure_ascii=False, indent=2)
print(f"source.json für Version {version} ({build}) geschrieben")
