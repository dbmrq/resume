# CV

My CV as code—a single Markdown source rendered to both a responsive web page and a print-ready PDF.

**[View Live →](https://daniel.leio.co)**

## Stack

- **Source:** Markdown with YAML frontmatter
- **PDF:** Pandoc + LuaLaTeX with a custom template
- **Web:** Vanilla JavaScript that renders the same Markdown client-side
- **CI/CD:** GitHub Actions builds and deploys to GitHub Pages on every push

## Structure

```
├── cv.md                   # CV content (single source of truth)
├── keywords.yaml           # ATS keywords injected at build time
├── build.sh                # Build script for PDF and HTML
├── templates/
│   ├── template.tex        # LaTeX template for PDF
│   └── index-template.html # HTML shell with contact info placeholders
└── assets/
    ├── style.css           # Web styles
    └── qrcode/             # QR code for print version
```

## Build

```bash
./build.sh
```

Requires Pandoc, LuaLaTeX, and the Inter font. Contact info is injected from `contact-private.json` (local) or GitHub Secrets (CI).
