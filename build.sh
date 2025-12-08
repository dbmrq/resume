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
EMAIL=$(jq -r '.email' contact-private.json)
PHONE=$(jq -r '.phone' contact-private.json)
WHATSAPP=$(jq -r '.whatsapp' contact-private.json)

# --- PDF Generation ---
# Create temp cv.md with real contact info substituted
sed -e "s|{{EMAIL_LINK}}|[$EMAIL](mailto:$EMAIL)|g" \
    -e "s|{{PHONE_LINK}}|[$PHONE]($WHATSAPP)|g" \
    cv.md > cv-temp.md

pandoc cv-temp.md \
  -o cv.pdf \
  --pdf-engine=xelatex \
  --template=template.tex \
  -V geometry:"top=4cm, bottom=2.5cm, left=4cm, right=4cm"

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

sed -e "s|{{EMAIL_CODES}}|$email_codes|g" \
    -e "s|{{PHONE_CODES}}|$phone_codes|g" \
    -e "s|{{WHATSAPP_CODES}}|$whatsapp_codes|g" \
    index-template.html > index.html

echo "index.html generated with obfuscated contact info"