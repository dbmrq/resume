# CV

A semantic CV generator that produces both a responsive website and a print-ready PDF from a single YAML source.

## Usage

1. Fork this repo
2. Edit `cv-data.yaml` with your information
3. Push — GitHub Actions builds and deploys to GitHub Pages

For local builds:
```bash
pip install -r requirements.txt  # or use a venv
./build.sh                       # requires Pandoc, LuaLaTeX, Inter font
```

For private contact info, create `contact-private.json` (avoids bots):
```json
{"email": "you@example.com", "phone": "+1 555 123 4567", "whatsapp": "https://wa.me/..."}
```

## License

MIT — use freely with attribution. Link back to this repo or credit the original author.
