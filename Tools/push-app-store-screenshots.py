#!/usr/bin/env python3
"""Uploads docs/app-store/screenshots/ to App Store Connect.

Twenty-seven images across nine languages, and the web form takes them one drag
at a time. Uploading is a three-step handshake rather than a POST: reserve a
slot and get back a list of upload operations, send the bytes to each, then
confirm with a checksum. Apple discards a reservation that is never confirmed,
so a half-finished run leaves rubbish behind — hence the cleanup pass.

Usage:  python3 Tools/push-app-store-screenshots.py [--replace]
"""
import base64, hashlib, json, os, subprocess, sys, time

KEY_PATH = os.path.expanduser("~/Developer/CleanMenuBar-signing/AuthKey_H62S9X5DTG.p8")
KEY_ID   = "H62S9X5DTG"
ISSUER   = "0f395b89-aeaf-403e-ad15-c3d5558be79b"
APP_ID   = "6815842748"
# macOS listings take one display type. iOS would need a set per device size.
DISPLAY  = "APP_DESKTOP"
REPLACE  = "--replace" in sys.argv

LOCALES = {"en": "en-US", "pt-BR": "pt-BR", "es": "es-ES", "fr": "fr-FR",
           "de": "de-DE", "ja": "ja", "zh-Hans": "zh-Hans",
           "zh-Hant": "zh-Hant", "ru": "ru"}


def token():
    def b64u(b): return base64.urlsafe_b64encode(b).rstrip(b"=")
    now = int(time.time())
    head = b64u(json.dumps({"alg": "ES256", "kid": KEY_ID, "typ": "JWT"},
                           separators=(",", ":")).encode())
    body = b64u(json.dumps({"iss": ISSUER, "iat": now, "exp": now + 1200,
                            "aud": "appstoreconnect-v1"},
                           separators=(",", ":")).encode())
    si = head + b"." + body
    der = subprocess.run(["openssl", "dgst", "-sha256", "-sign", KEY_PATH],
                         input=si, capture_output=True).stdout
    i = 2 if der[1] < 0x80 else 3
    def take(buf, i):
        assert buf[i] == 0x02
        ln = buf[i + 1]
        return buf[i + 2:i + 2 + ln].lstrip(b"\x00").rjust(32, b"\x00"), i + 2 + ln
    r, i = take(der, i)
    s, _ = take(der, i)
    return (si + b"." + b64u(r + s)).decode()


TOK = token()


def api(method, path, payload=None):
    cmd = ["curl", "-sS", "-X", method, "-H", f"Authorization: Bearer {TOK}",
           "-H", "Content-Type: application/json"]
    if payload is not None:
        cmd += ["-d", json.dumps(payload)]
    cmd.append(f"https://api.appstoreconnect.apple.com{path}")
    out = subprocess.run(cmd, capture_output=True, text=True).stdout
    if not out.strip():
        return {}
    try:
        return json.loads(out)
    except json.JSONDecodeError:
        return {"errors": [{"detail": out[:200]}]}


version_id = api("GET", f"/v1/apps/{APP_ID}/appStoreVersions?limit=1")["data"][0]["id"]
locs = {l["attributes"]["locale"]: l["id"] for l in
        api("GET", f"/v1/appStoreVersions/{version_id}"
                   "/appStoreVersionLocalizations?limit=50")["data"]}

for folder, locale in LOCALES.items():
    loc_id = locs.get(locale)
    if not loc_id:
        print(f"  {locale}: sem localização, pulando")
        continue

    sets = api("GET", f"/v1/appStoreVersionLocalizations/{loc_id}"
                      "/appScreenshotSets").get("data", [])
    sset = next((s for s in sets
                 if s["attributes"]["screenshotDisplayType"] == DISPLAY), None)
    if sset is None:
        r = api("POST", "/v1/appScreenshotSets",
                {"data": {"type": "appScreenshotSets",
                          "attributes": {"screenshotDisplayType": DISPLAY},
                          "relationships": {"appStoreVersionLocalization":
                              {"data": {"type": "appStoreVersionLocalizations",
                                        "id": loc_id}}}}})
        if "errors" in r:
            print(f"  {locale}: {r['errors'][0].get('detail','')[:80]}")
            continue
        sset = r["data"]
    set_id = sset["id"]

    have = api("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots").get("data", [])
    if have and not REPLACE:
        print(f"  {locale}: já tem {len(have)}, pulando (use --replace)")
        continue
    for h in have:
        api("DELETE", f"/v1/appScreenshots/{h['id']}")

    files = sorted(f for f in os.listdir(f"docs/app-store/screenshots/{folder}")
                   if f.endswith(".png"))
    ok = 0
    for fname in files:
        path = f"docs/app-store/screenshots/{folder}/{fname}"
        blob = open(path, "rb").read()
        r = api("POST", "/v1/appScreenshots",
                {"data": {"type": "appScreenshots",
                          "attributes": {"fileSize": len(blob), "fileName": fname},
                          "relationships": {"appScreenshotSet":
                              {"data": {"type": "appScreenshotSets", "id": set_id}}}}})
        if "errors" in r:
            print(f"  {locale} {fname}: {r['errors'][0].get('detail','')[:80]}")
            continue
        shot_id = r["data"]["id"]

        # Apple hands back a list of byte ranges rather than one URL. Small files
        # come back as a single operation; the loop is what makes that an
        # implementation detail instead of an assumption.
        for op in r["data"]["attributes"]["uploadOperations"]:
            cmd = ["curl", "-sS", "-X", op["method"], op["url"]]
            for h in op.get("requestHeaders", []):
                cmd += ["-H", f"{h['name']}: {h['value']}"]
            chunk = blob[op["offset"]:op["offset"] + op["length"]]
            cmd += ["--data-binary", "@-"]
            subprocess.run(cmd, input=chunk, capture_output=True)

        r = api("PATCH", f"/v1/appScreenshots/{shot_id}",
                {"data": {"type": "appScreenshots", "id": shot_id,
                          "attributes": {"uploaded": True,
                                         "sourceFileChecksum": hashlib.md5(blob).hexdigest()}}})
        if "errors" in r:
            print(f"  {locale} {fname}: confirmação falhou — "
                  f"{r['errors'][0].get('detail','')[:60]}")
        else:
            ok += 1
    print(f"  {locale}: {ok}/{len(files)} enviados")

print("\nfeito")
