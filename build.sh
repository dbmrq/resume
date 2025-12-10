#!/bin/bash
#
# Build script for CV website and PDF
#
# Generates:
#   - cv.md: Markdown from cv-data.yaml (intermediate)
#   - cv.pdf: PDF version with real contact info (for download/print)
#   - index.html: Web version with obfuscated contact info
#
# Contact info obfuscation:
#   Email/phone are stored as character code arrays in index.html and decoded
#   at runtime via JavaScript. This defeats simple text scrapers and regex-based
#   email harvesters while remaining accessible to real users.
#
set -e

# --- Check dependencies ---
check_dependency() {
  if ! command -v "$1" &> /dev/null; then
    echo "Error: $1 is required but not installed."
    echo "$2"
    exit 1
  fi
}

check_dependency "pandoc" "Install Pandoc from https://pandoc.org"
check_dependency "jq" "Install jq: brew install jq (macOS) or apt install jq (Linux)"

# Use virtual environment if available, otherwise system Python
if [ -f ".venv/bin/python3" ]; then
  PYTHON=".venv/bin/python3"
else
  PYTHON="python3"
fi

# Check for PyYAML
if ! $PYTHON -c "import yaml" 2>/dev/null; then
  echo "Error: PyYAML is required but not installed."
  echo ""
  echo "Option 1 (recommended): Create a virtual environment"
  echo "  python3 -m venv .venv"
  echo "  .venv/bin/pip install -r requirements.txt"
  echo ""
  echo "Option 2: Install globally (if your system allows)"
  echo "  pip install -r requirements.txt"
  exit 1
fi

# --- Generate cv.md and read config from cv-data.yaml ---
echo "Generating cv.md from cv-data.yaml..."
$PYTHON build/generate.py cv

# Read all config values in one Python call
eval "$($PYTHON -c "
import yaml
d = yaml.safe_load(open('cv-data.yaml'))
print(f'CV_NAME=\"{d[\"name\"]}\"')
print(f'GITHUB_URL=\"{d.get(\"links\",{}).get(\"github\",\"\")}\"')
print(f'WEBSITE_URL=\"{d.get(\"website\",{}).get(\"url\",\"\")}\"')
print(f'WEBSITE_DISPLAY=\"{d.get(\"website\",{}).get(\"display\",\"\")}\"')
")"

# Read contact info from private file (created from GitHub secrets in CI)
# If contact-private.json doesn't exist, use placeholders for local testing
if [ -f "contact-private.json" ]; then
  EMAIL=$(jq -r '.email' contact-private.json)
  PHONE=$(jq -r '.phone' contact-private.json)
  WHATSAPP=$(jq -r '.whatsapp' contact-private.json)
else
  echo "Note: contact-private.json not found, using placeholders for local testing"
  EMAIL="email@example.com"
  PHONE="+1 (555) 123-4567"
  WHATSAPP="https://wa.me/15551234567"
fi

# --- PDF Generation ---
# Create temp cv.md with real contact info and keywords merged
# First, extract frontmatter and body from cv.md
{
  # Read cv.md and inject keywords from keywords.yaml into the frontmatter
  awk '
    BEGIN { in_frontmatter = 0; frontmatter_end = 0 }
    /^---$/ && !in_frontmatter { in_frontmatter = 1; print; next }
    /^---$/ && in_frontmatter {
      # Inject keywords before closing frontmatter
      print "keywords:"
      while ((getline line < "keywords.yaml") > 0) {
        if (line ~ /^[[:space:]]*-/) print line
      }
      close("keywords.yaml")
      print "---"
      in_frontmatter = 0
      frontmatter_end = 1
      next
    }
    { print }
  ' cv.md
} | sed -e "s|{{EMAIL_LINK}}|[$EMAIL](mailto:$EMAIL)|g" \
        -e "s|{{PHONE_LINK}}|[$PHONE]($WHATSAPP)|g" > cv-temp.md

# Detect Inter font name (differs between local and CI)
if fc-list | grep -q "Inter Variable"; then
  INTER_FONT="Inter Variable"
else
  INTER_FONT="Inter"
fi

# Build pandoc variable flags
PANDOC_VARS="-V geometry:\"top=4cm, bottom=2.5cm, left=4cm, right=4cm\" -V interfont:\"$INTER_FONT\""

if [ -n "$WEBSITE_URL" ]; then
  PANDOC_VARS="$PANDOC_VARS -V website:\"$WEBSITE_URL\" -V website-display:\"$WEBSITE_DISPLAY\""
fi

if [ -n "$GITHUB_URL" ]; then
  GITHUB_DISPLAY="${GITHUB_URL#https://}"
  PANDOC_VARS="$PANDOC_VARS -V github:\"$GITHUB_URL\" -V github-display:\"$GITHUB_DISPLAY\""
fi

eval pandoc cv-temp.md \
  -o cv.pdf \
  --pdf-engine=lualatex \
  --template=build/template.tex \
  --lua-filter=build/date-range.lua \
  "$PANDOC_VARS"

rm cv-temp.md
echo "PDF generated: cv.pdf"

# --- HTML Generation with Obfuscated Contact Info ---
# Convert each string to an array of ASCII character codes
# e.g., "hi" becomes [104,105] - decoded in browser via String.fromCharCode()
email_codes=$(echo -n "$EMAIL" | od -An -tu1 | tr -s ' \n' ',' | sed 's/^,//;s/,$//')
phone_codes=$(echo -n "$PHONE" | od -An -tu1 | tr -s ' \n' ',' | sed 's/^,//;s/,$//')
whatsapp_codes=$(echo -n "$WHATSAPP" | od -An -tu1 | tr -s ' \n' ',' | sed 's/^,//;s/,$//')

email_codes="[$email_codes]"
phone_codes="[$phone_codes]"
whatsapp_codes="[$whatsapp_codes]"

# Extract keywords from keywords.yaml as comma-separated string (to temp file)
grep -E '^\s*-\s' keywords.yaml | sed 's/^\s*-\s*//' | tr '\n' ',' | sed 's/,$//' > .keywords-temp.txt

# Generate header icons HTML from cv-data.yaml (to temp file for multi-line content)
$PYTHON build/generate.py icons > .header-icons-temp.html

# Generate GitHub footer link (always links to original repo for attribution)
github_footer="The source is available on <a href=\"https://github.com/dbmrq/resume\" target=\"_blank\" rel=\"noopener\">GitHub</a>."

# Build index.html using awk for multi-line replacements
# Read keywords and icons from files to avoid shell escaping issues
awk -v email_codes="$email_codes" \
    -v phone_codes="$phone_codes" \
    -v whatsapp_codes="$whatsapp_codes" \
    -v cv_name="$CV_NAME" \
    -v github_footer="$github_footer" \
    '
    BEGIN {
      while ((getline line < ".header-icons-temp.html") > 0) icons = icons line "\n"
      getline keywords < ".keywords-temp.txt"
      # Escape & for gsub replacement (& means matched text in awk)
      gsub(/&/, "\\\\&", keywords)
      gsub(/&/, "\\\\&", icons)
    }
    {
      gsub(/\{\{EMAIL_CODES\}\}/, email_codes)
      gsub(/\{\{PHONE_CODES\}\}/, phone_codes)
      gsub(/\{\{WHATSAPP_CODES\}\}/, whatsapp_codes)
      gsub(/\{\{KEYWORDS\}\}/, keywords)
      gsub(/\{\{CV_NAME\}\}/, cv_name)
      gsub(/\{\{GITHUB_FOOTER\}\}/, github_footer)
      gsub(/\{\{HEADER_ICONS\}\}/, icons)
      print
    }
    ' build/index-template.html > index.html

rm .header-icons-temp.html .keywords-temp.txt

echo "index.html generated with obfuscated contact info"