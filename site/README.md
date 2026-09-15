# The CleanMenuBar site

Static HTML for https://monobit.com.br/cleanmenubar — nine languages, three
pages each. **Do not edit these files by hand**: they are generated, and the
next build will overwrite your changes.

## Editing

Copy lives in [`../Tools/site_content.py`](../Tools/site_content.py), one
dictionary per language, no HTML in sight — a translator can work there without
touching markup. Rebuild with:

```sh
python3 Tools/build-site.py
```

The build refuses to run if any language is missing a key, so a half-translated
page can never reach the site.

## Why static pages instead of a JavaScript toggle

An earlier version kept every language in one page and switched with JavaScript.
It was replaced because legal documents should be linkable, indexable and
archivable on their own: a regulator, an App Store reviewer or a user following
a privacy URL should land on the text, not on a page that has to run code before
it says anything. Each translation now has a real URL, and the pages work with
JavaScript disabled.

## Publishing

Upload the contents of this folder to the `/cleanmenubar` path. There is no
build step on the server, no dependencies and no framework — plain files.

```
site/
├── index.html          English, at the root
├── privacy.html
├── terms.html
├── style.css
├── icon.svg
├── pt-br/  es/  fr/  de/  ja/  zh-hans/  zh-hant/  ru/
└── (index, privacy, terms in each)
```

The privacy policy must be reachable at
`https://monobit.com.br/cleanmenubar/privacy.html` before submitting to the Mac
App Store — Apple requires a working privacy URL for every app, including those
that collect nothing.

## Download link

The Download button points at
`https://github.com/atilac/CleanMenuBar/releases/latest`, so it follows whatever
the newest release is without the site needing a rebuild.
