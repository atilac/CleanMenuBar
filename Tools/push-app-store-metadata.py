#!/usr/bin/env python3
"""Pushes the listing text in docs/app-store/ to App Store Connect.

The listing is nine languages wide and a dozen fields deep, which is well past
the point where filling it by hand stays accurate. Keeping it in the repository
and pushing from there means the text under review is the text that ships, and
a correction is a diff rather than a hunt through a web form.

Needs a key with App Manager access: a read-only key can fetch all of this but
writes come back "forbidden for security reasons", which reads like an account
problem and is not one.

Usage:  python3 Tools/push-app-store-metadata.py [--dry-run]
"""
import base64, json, os, re, subprocess, sys, time

KEY_PATH = os.path.expanduser("~/Developer/CleanMenuBar-signing/AuthKey_H62S9X5DTG.p8")
KEY_ID   = "H62S9X5DTG"
ISSUER   = "0f395b89-aeaf-403e-ad15-c3d5558be79b"
APP_ID   = "6815842748"
SITE     = "https://monobit.com.br/cleanmenubar"
DRY      = "--dry-run" in sys.argv

# Locale as the store names it, then the directory the site publishes it under.
# The two disagree often enough that pairing them here is safer than deriving
# one from the other: pt-BR is the site's root and has no prefix at all.
LOCALES = {
    "en.md":      ("en-US",   "en"),
    "pt-BR.md":   ("pt-BR",   ""),
    "es.md":      ("es-ES",   "es"),
    "fr.md":      ("fr-FR",   "fr"),
    "de.md":      ("de-DE",   "de"),
    "ja.md":      ("ja",      "ja"),
    "zh-Hans.md": ("zh-Hans", "zh-hans"),
    "zh-Hant.md": ("zh-Hant", "zh-hant"),
    "ru.md":      ("ru",      "ru"),
}
LIMITS = {"name": 30, "subtitle": 30, "keywords": 100,
          "promotionalText": 170, "description": 4000}


def token():
    def b64u(b): return base64.urlsafe_b64encode(b).rstrip(b"=")
    now = int(time.time())
    head = b64u(json.dumps({"alg": "ES256", "kid": KEY_ID, "typ": "JWT"},
                           separators=(",", ":")).encode())
    body = b64u(json.dumps({"iss": ISSUER, "iat": now, "exp": now + 900,
                            "aud": "appstoreconnect-v1"},
                           separators=(",", ":")).encode())
    si = head + b"." + body
    der = subprocess.run(["openssl", "dgst", "-sha256", "-sign", KEY_PATH],
                         input=si, capture_output=True).stdout
    # DER SEQUENCE { INTEGER r, INTEGER s } -> the raw r||s pair JWS wants.
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
    cmd = ["curl", "-sS", "-X", method,
           "-H", f"Authorization: Bearer {TOK}",
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


def parse(path):
    """Reads one listing file. Sections are matched by position, not by their
    heading: pt-BR's headings are in Portuguese, and translating the parser's
    vocabulary every time a language is added is a worse trade than relying on
    an order every file already shares."""
    raw = open(path, encoding="utf-8").read()
    blocks = re.split(r"^## .*$", raw, flags=re.M)[1:]
    # Blockquotes in these files are notes to ourselves about why a word was
    # dropped or a line rewritten. They are not part of the listing, and one of
    # them is longer than the keyword field it sits above.
    vals = ["\n".join(l for l in b.splitlines() if not l.lstrip().startswith(">")).strip()
            for b in blocks]
    keys = ["name", "subtitle", "keywords", "promotionalText", "description", "whatsNew"]
    return dict(zip(keys, vals))


def check(loc, field, text):
    limit = LIMITS.get(field)
    if limit and len(text) > limit:
        print(f"    {loc} {field}: {len(text)}/{limit} — EXCEDE, não enviado")
        return False
    return True


version = api("GET", f"/v1/apps/{APP_ID}/appStoreVersions?limit=1")["data"][0]
version_id = version["id"]
app_info_id = api("GET", f"/v1/apps/{APP_ID}/appInfos")["data"][0]["id"]
print(f"versão {version['attributes']['versionString']} ({version['attributes']['appStoreState']})")

existing_v = {l["attributes"]["locale"]: l["id"] for l in
              api("GET", f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=50").get("data", [])}
existing_i = {l["attributes"]["locale"]: l["id"] for l in
              api("GET", f"/v1/appInfos/{app_info_id}/appInfoLocalizations?limit=50").get("data", [])}

for fname, (locale, prefix) in LOCALES.items():
    text = parse(f"docs/app-store/{fname}")
    base = f"{SITE}/{prefix}/" if prefix else f"{SITE}/"
    print(f"\n  {locale}")

    # Name, subtitle and the privacy link live on the app, not the version:
    # they outlive any single release and App Store Connect models them apart.
    info = {k: text[k] for k in ("name", "subtitle") if check(locale, k, text[k])}
    info["privacyPolicyUrl"] = f"{base}privacy.html"
    if DRY:
        print(f"    (dry-run) appInfo: {info}")
    elif locale in existing_i:
        r = api("PATCH", f"/v1/appInfoLocalizations/{existing_i[locale]}",
                {"data": {"type": "appInfoLocalizations", "id": existing_i[locale],
                          "attributes": info}})
        print("    nome/subtítulo:", "erro: " + r["errors"][0].get("detail", "")[:90]
              if "errors" in r else "ok")
    else:
        r = api("POST", "/v1/appInfoLocalizations",
                {"data": {"type": "appInfoLocalizations",
                          "attributes": {**info, "locale": locale},
                          "relationships": {"appInfo": {"data": {"type": "appInfos",
                                                                 "id": app_info_id}}}}})
        print("    nome/subtítulo:", "erro: " + r["errors"][0].get("detail", "")[:90]
              if "errors" in r else "criado")
        if "data" in r:
            existing_i[locale] = r["data"]["id"]

    # Re-read: creating an appInfoLocalization makes App Store Connect create
    # the matching appStoreVersionLocalization too, so the list captured before
    # the loop is already stale and a POST here comes back "already exists".
    existing_v = {l["attributes"]["locale"]: l["id"] for l in
                  api("GET", f"/v1/appStoreVersions/{version_id}"
                             "/appStoreVersionLocalizations?limit=50").get("data", [])}

    ver = {k: text[k] for k in ("description", "keywords", "promotionalText")
           if check(locale, k, text[k])}
    ver["supportUrl"] = base
    ver["marketingUrl"] = base
    if DRY:
        print(f"    (dry-run) versão: {len(ver['description'])} chars de descrição")
    elif locale in existing_v:
        r = api("PATCH", f"/v1/appStoreVersionLocalizations/{existing_v[locale]}",
                {"data": {"type": "appStoreVersionLocalizations",
                          "id": existing_v[locale], "attributes": ver}})
        print("    descrição:", "erro: " + r["errors"][0].get("detail", "")[:90]
              if "errors" in r else "ok")
    else:
        r = api("POST", "/v1/appStoreVersionLocalizations",
                {"data": {"type": "appStoreVersionLocalizations",
                          "attributes": {**ver, "locale": locale},
                          "relationships": {"appStoreVersion":
                                            {"data": {"type": "appStoreVersions",
                                                      "id": version_id}}}}})
        print("    descrição:", "erro: " + r["errors"][0].get("detail", "")[:90]
              if "errors" in r else "criada")
        if "data" in r:
            existing_v[locale] = r["data"]["id"]

print("\nfeito")
