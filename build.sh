#!/bin/bash
#
# Build script for CV website and PDF
#
# Generates:
#   - cv.pdf: PDF version with real contact info (for download/print)
#   - index.html: Web version with obfuscated contact info
#
# Contact info obfuscation:
#   Email/phone are stored as character code arrays in index.html and decoded
#   at runtime via JavaScript. This defeats simple text scrapers and regex-based
#   email harvesters while remaining accessible to real users.
#
set -e

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

pandoc cv-temp.md \
  -o cv.pdf \
  --pdf-engine=lualatex \
  --template=templates/template.tex \
  -V geometry:"top=4cm, bottom=2.5cm, left=4cm, right=4cm" \
  -V interfont:"$INTER_FONT"

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

# Extract keywords from keywords.yaml as comma-separated string
keywords_string=$(grep -E '^\s*-\s' keywords.yaml | sed 's/^\s*-\s*//' | tr '\n' ',' | sed 's/,$//')

sed -e "s|{{EMAIL_CODES}}|$email_codes|g" \
    -e "s|{{PHONE_CODES}}|$phone_codes|g" \
    -e "s|{{WHATSAPP_CODES}}|$whatsapp_codes|g" \
    -e "s|{{KEYWORDS}}|$keywords_string|g" \
    templates/index-template.html > index.html

echo "index.html generated with obfuscated contact info"