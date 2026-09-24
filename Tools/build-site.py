#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Builds the CleanMenuBar site: nine languages, three pages each.

Static HTML per language rather than one page switched by JavaScript. Legal
documents should be linkable, archivable and readable without scripts — and a
reviewer or a regulator following a URL should land on the text itself, not on
a page that needs to run code before it says anything.

    python3 Tools/build-site.py
"""

import os, shutil, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from site_content import C, LANGUAGES, UPDATED

OUT = "site"
REPO = "https://github.com/atilac/CleanMenuBar"
DOWNLOAD = REPO + "/releases/latest"
SITE = "https://monobit.com.br/cleanmenubar"
ENTITY = "MONOBIT (ATILA VITAL CAVALCANTE DA SILVA LTDA)"
CONTAINER = "~/Library/Containers/com.atilac.CleanMenuBar/"

ICON_SVG = """<svg viewBox="0 0 100 100" aria-hidden="true">
      <!-- The same geometry Tools/GenerateAppIcon.swift draws: a C cut in three
           places, mouth at 105 degrees against 18-degree cuts. Computed rather
           than eyeballed — hand-written arcs did not read as a letter. No plate
           inset here: the surrounding div is the plate. -->
      <g fill="none" stroke="#fff" stroke-width="12.50" stroke-linecap="butt">
        <path d="M 70.35 27.39 A 28.50 28.50 0 0 0 46.71 22.20"/>
        <path d="M 38.43 25.51 A 28.50 28.50 0 0 0 24.85 45.54"/>
        <path d="M 24.85 54.46 A 28.50 28.50 0 0 0 38.43 74.49"/>
        <path d="M 46.71 77.80 A 28.50 28.50 0 0 0 70.35 72.61"/>
      </g>
    </svg>"""


def rel(depth, path):
    """Links are relative so the site works at any prefix, including a local
    folder opened with file://."""
    return ("../" * depth) + path


def language_switcher(current, page, depth):
    links = []
    for code, label, folder in LANGUAGES:
        target = rel(depth, page) if folder is None else rel(depth, f"{folder}/{page}")
        cls = ' class="current"' if code == current else ""
        links.append(f'<a{cls} href="{target}" hreflang="{code}" lang="{code}">{label}</a>')
    return '<nav class="lang">' + "".join(links) + "</nav>"


def alternates(page, depth):
    """hreflang tells search engines these pages are translations of each other
    rather than duplicates competing with one another."""
    out = []
    for code, _, folder in LANGUAGES:
        href = f"{SITE}/{page}" if folder is None else f"{SITE}/{folder}/{page}"
        out.append(f'<link rel="alternate" hreflang="{code}" href="{href}">')
    # x-default is the page served to anyone whose language we do not carry.
    # It has to be the root, whichever language sits there.
    out.append(f'<link rel="alternate" hreflang="x-default" href="{SITE}/{page}">')
    return "\n".join(out)


def canonical(code, page):
    """The absolute URL of this exact translation. Used for og:url and
    rel=canonical, both of which are wrong — and actively harmful for indexing —
    if every language claims the English URL."""
    folder = next(f for c, _, f in LANGUAGES if c == code)
    return f"{SITE}/{page}" if folder is None else f"{SITE}/{folder}/{page}"


def head(t, code, page, depth, description=""):
    desc = f'<meta name="description" content="{description}">' if description else ""
    url = canonical(code, page)
    social = f"""<link rel="canonical" href="{url}">
<meta property="og:title" content="{t}">
<meta property="og:image" content="{SITE}/icon-512.png">
<meta property="og:url" content="{url}">
<meta property="og:type" content="website">""" + (
        f'\n<meta property="og:description" content="{description}">' if description else "")
    return f"""<!DOCTYPE html>
<html lang="{code}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{t}</title>
{desc}
{social}
<link rel="stylesheet" href="{rel(depth, 'style.css')}">
<link rel="icon" href="{rel(depth, 'icon.svg')}" type="image/svg+xml">
<link rel="icon" href="{rel(depth, 'favicon-32.png')}" sizes="32x32" type="image/png">
<link rel="apple-touch-icon" href="{rel(depth, 'apple-touch-icon.png')}">
<meta name="theme-color" content="#ec4899">
{alternates(page, depth)}
</head>
<body>
<div class="wrap">"""


def footer(t, code, page_depth, active):
    home = rel(page_depth, "index.html")
    privacy = rel(page_depth, "privacy.html")
    terms = rel(page_depth, "terms.html")
    items = []
    if active != "index":
        items.append(f'<a href="{home}">{t["nav_home"]}</a>')
    if active != "privacy":
        items.append(f'<a href="{privacy}">{t["nav_privacy"]}</a>')
    if active != "terms":
        items.append(f'<a href="{terms}">{t["nav_terms"]}</a>')
    items.append(f'<a href="{REPO}">GitHub</a>')
    items.append('<a href="mailto:apps@monobit.com.br">apps@monobit.com.br</a>')
    return f"""<footer>
  <nav>{"".join(items)}</nav>
  <p>{ENTITY} · {t["licence_short"]}</p>
</footer>
</div>
</body>
</html>"""


def index(code, t, depth):
    features = "".join(
        f'<li><strong>{t[f"f{i}_t"]}</strong><span>{t[f"f{i}_d"]}</span></li>'
        for i in range(1, 7)
    )
    steps = "".join(f"<li>{t[f's{i}']}</li>" for i in range(1, 5))
    return f"""{head(t['title'], code, 'index.html', depth, t['description'])}
<header>
  <div class="icon">{ICON_SVG}</div>
  <h1>CleanMenuBar</h1>
  <p class="tagline">{t['tagline']}</p>
  <a class="download" href="{DOWNLOAD}">{t['download']}</a>
  <p class="requirements">{t['requirements']}</p>
  {language_switcher(code, 'index.html', depth)}
</header>

<section>
  <h2>{t['why_h']}</h2>
  <p>{t['why_1']}</p>
  <p>{t['why_2']}</p>
</section>

<section>
  <h2>{t['what_h']}</h2>
  <ul class="features">{features}</ul>
</section>

<section>
  <h2>{t['how_h']}</h2>
  <ol class="steps">{steps}</ol>
  <p class="note">{t['how_note']}</p>
</section>

<section>
  <h2>{t['install_h']}</h2>
  <p>{t['install_1']}</p>
  <p class="note">{t['install_note']}</p>
</section>

{footer(t, code, depth, 'index')}"""


def privacy(code, t, depth):
    nots = "".join(f"<li>{t[f'pp_n{i}']}</li>" for i in range(1, 6))
    return f"""{head(t['pp_title'] + ' — CleanMenuBar', code, 'privacy.html', depth)}
<div class="legal">
  {language_switcher(code, 'privacy.html', depth)}
  <h1>{t['pp_title']}</h1>
  <p class="meta">{t['pp_meta'].format(date=UPDATED)}</p>

  <h2>{t['pp_short_h']}</h2>
  <p>{t['pp_short_1']}</p>
  <p class="note">{t['pp_short_note']}</p>

  <h2>{t['pp_store_h']}</h2>
  <p>{t['pp_store_1']}</p>
  <p><code>{CONTAINER}</code></p>
  <p>{t['pp_store_2']}</p>
  <p>{t['pp_store_3']}</p>

  <h2>{t['pp_not_h']}</h2>
  <ul>{nots}</ul>

  <h2>{t['pp_perm_h']}</h2>
  <p>{t['pp_perm_1']}</p>
  <p>{t['pp_perm_2']}</p>

  <h2>{t['pp_kids_h']}</h2>
  <p>{t['pp_kids_1']}</p>

  <h2>{t['pp_src_h']}</h2>
  <p>{t['pp_src_1']} <a href="{REPO}">{REPO.replace('https://', '')}</a></p>

  <h2>{t['pp_chg_h']}</h2>
  <p>{t['pp_chg_1']}</p>

  <h2>{t['contact_h']}</h2>
  <p>{ENTITY}<br><a href="mailto:apps@monobit.com.br">apps@monobit.com.br</a></p>
</div>
{footer(t, code, depth, 'privacy')}"""


def terms(code, t, depth):
    privacy_link = rel(depth, "privacy.html")
    return f"""{head(t['tu_title'] + ' — CleanMenuBar', code, 'terms.html', depth)}
<div class="legal">
  {language_switcher(code, 'terms.html', depth)}
  <h1>{t['tu_title']}</h1>
  <p class="meta">{t['tu_meta'].format(date=UPDATED)}</p>

  <h2>{t['tu_who_h']}</h2>
  <p>{t['tu_who_1']}</p>

  <h2>{t['tu_lic_h']}</h2>
  <p>{t['tu_lic_1']}</p>
  <p>{t['tu_lic_2']} <a href="{REPO}/blob/main/LICENSE">LICENSE</a></p>
  <p>{t['tu_lic_3']}</p>

  <h2>{t['tu_war_h']}</h2>
  <p>{t['tu_war_1']}</p>
  <p>{t['tu_war_2']}</p>

  <h2>{t['tu_lia_h']}</h2>
  <p>{t['tu_lia_1']}</p>
  <p>{t['tu_lia_2']}</p>
  <p>{t['tu_lia_3']}</p>

  <h2>{t['tu_risk_h']}</h2>
  <p>{t['tu_risk_1']}</p>
  <p>{t['tu_risk_2']}</p>

  <h2>{t['tu_priv_h']}</h2>
  <p>{t['tu_priv_1']} <a href="{privacy_link}">{t['nav_privacy']}</a></p>

  <h2>{t['tu_chg_h']}</h2>
  <p>{t['tu_chg_1']}</p>

  <h2>{t['tu_law_h']}</h2>
  <p>{t['tu_law_1']}</p>
</div>
{footer(t, code, depth, 'terms')}"""


def main():
    # English stays the reference for which keys must exist, regardless of which
    # language is published at the root — it is where new copy is written first.
    missing = {
        code: sorted(set(C["en"]) - set(C.get(code, {})))
        for code, _, _ in LANGUAGES
        if set(C["en"]) - set(C.get(code, {}))
    }
    if missing:
        for code, keys in missing.items():
            print(f"  {code} is missing: {', '.join(keys)}", file=sys.stderr)
        sys.exit("refusing to build a site with untranslated strings")

    for code, _, folder in LANGUAGES:
        depth = 0 if folder is None else 1
        directory = OUT if folder is None else os.path.join(OUT, folder)
        os.makedirs(directory, exist_ok=True)
        t = C[code]
        for name, render in (("index", index), ("privacy", privacy), ("terms", terms)):
            path = os.path.join(directory, f"{name}.html")
            with open(path, "w", encoding="utf-8") as f:
                f.write(render(code, t, depth))
        print(f"  {code:8s} -> {directory}/")

    # Everything in site/ gets published verbatim, so nothing that is not meant
    # for the public may live there. Documentation belongs in docs/.
    publishable = {".html", ".css", ".svg", ".png", ".ico", ".txt", ".webmanifest"}
    strays = sorted(
        os.path.join(root, name)
        for root, _, names in os.walk(OUT)
        for name in names
        if os.path.splitext(name)[1].lower() not in publishable
    )
    if strays:
        for path in strays:
            print(f"  not publishable: {path}", file=sys.stderr)
        sys.exit("site/ may contain only files meant to be served")

    print(f"\n  {len(LANGUAGES)} languages x 3 pages = {len(LANGUAGES) * 3} files")


if __name__ == "__main__":
    main()
