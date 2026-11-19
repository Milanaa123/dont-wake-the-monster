#!/usr/bin/env python3
"""Upload an .rbxlx place to an EXISTING Roblox place using the official Assets API.

This script is only called by a manually triggered workflow. GitHub Secrets inject the
API key; no key, place ID or response body is written back to the repository.
"""
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

def main():
    place_id = os.environ.get("ROBLOX_PLACE_ID", "")
    api_key = os.environ.get("ROBLOX_API_KEY", "")
    upload_mode = os.environ.get("UPLOAD_MODE", "Saved")
    path = Path("dist/dont-wake-the-monster.rbxlx")

    if not place_id.isdecimal() or int(place_id) <= 0:
        raise SystemExit("A positive numeric Roblox Place ID is required.")
    if not api_key:
        raise SystemExit("Missing GitHub Actions secret ROBLOX_API_KEY.")
    if upload_mode not in ("Saved", "Published"):
        raise SystemExit("Invalid upload mode; use Saved or Published.")
    if not path.is_file() or path.stat().st_size == 0:
        raise SystemExit("No non-empty Rojo-generated .rbxlx file was found.")

    published = upload_mode == "Published"
    request = {"assetId": int(place_id), "assetType": "Place", "published": published}
    url = "https://apis.roblox.com/assets/v1/assets/" + place_id
    print("Uploading Roblox place", place_id, "mode:", upload_mode, "(manual workflow)")
    # Do not print full curl arguments: those include the secret header.
    command = [
        "curl", "--silent", "--show-error", "--fail-with-body",
        "--request", "PATCH", "--url", url,
        "--header", "x-api-key: " + api_key,
        "--form", "request=" + json.dumps(request, separators=(",", ":")),
        "--form", "fileContent=@" + str(path) + ";type=application/xml",
    ]
    result = subprocess.run(command, capture_output=True, text=True, timeout=90)
    if result.returncode:
        print("Roblox upload HTTP request failed:", result.stderr.strip(), file=sys.stderr)
        try:
            error = json.loads(result.stdout)
            print("Roblox response:", error.get("message", error.get("error", "HTTP error")), file=sys.stderr)
        except (json.JSONDecodeError, AttributeError):
            print(result.stdout[:500], file=sys.stderr)
        raise SystemExit(1)
    try:
        upload_response = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise SystemExit("Roblox returned an invalid upload response.") from exc
    operation_path = upload_response.get("path", "")
    if not isinstance(operation_path, str) or not operation_path.startswith("operations/"):
        raise SystemExit("Roblox did not return an Assets API operation path.")

    operation_url = ("https://apis.roblox.com/assets/v1/" +
                     urllib.parse.quote(operation_path, safe="/"))
    for attempt in range(24):
        request_obj = urllib.request.Request(operation_url, headers={"x-api-key": api_key})
        try:
            with urllib.request.urlopen(request_obj, timeout=30) as response:
                operation = json.loads(response.read().decode("utf-8"))
        except (urllib.error.URLError, TimeoutError) as exc:
            print("Operation status not yet available:", type(exc).__name__)
            time.sleep(5)
            continue
        if operation.get("done") is True:
            if operation.get("error"):
                error = operation["error"]
                raise SystemExit("Roblox place operation failed: " + str(error.get("message", error)))
            payload = operation.get("response") or {}
            actual_published = payload.get("isPublished")
            if actual_published is not published:
                raise SystemExit("Publish mode mismatch in Roblox response. Check Creator Dashboard.")
            print("SUCCESS. Roblox place:", place_id)
            print("Version:", payload.get("revisionId", "not provided"))
            print("Published:", actual_published)
            return
        if attempt % 4 == 0:
            print("Roblox is processing the place upload...")
        time.sleep(5)
    raise SystemExit("Timed out awaiting Roblox operation completion. Verify status in Creator Dashboard.")

if __name__ == "__main__":
    main()
