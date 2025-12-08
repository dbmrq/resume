#!/bin/bash
set -e

# Read contact info from private file
EMAIL=$(jq -r '.email' contact-private.json)
PHONE=$(jq -r '.phone' contact-private.json)
WHATSAPP=$(jq -r '.whatsapp' contact-private.json)

# Create temp cv.md with real contact info for PDF
sed -e "s|{{EMAIL_LINK}}|[$EMAIL](mailto:$EMAIL)|g" \
    -e "s|{{PHONE_LINK}}|[$PHONE]($WHATSAPP)|g" \
    cv.md > cv-temp.md

# Generate PDF
pandoc cv-temp.md \
  -o cv.pdf \
  --pdf-engine=xelatex \
  --template=template.tex \
  -V geometry:"top=4cm, bottom=2.5cm, left=4cm, right=4cm"

rm cv-temp.md
echo "PDF generated: cv.pdf"

# Generate obfuscated contact info for index.html
# Convert strings to character code arrays
email_codes=$(echo -n "$EMAIL" | od -An -tu1 | tr -s ' \n' ',' | sed 's/^,//;s/,$//')
phone_codes=$(echo -n "$PHONE" | od -An -tu1 | tr -s ' \n' ',' | sed 's/^,//;s/,$//')
whatsapp_codes=$(echo -n "$WHATSAPP" | od -An -tu1 | tr -s ' \n' ',' | sed 's/^,//;s/,$//')

# Wrap in brackets
email_codes="[$email_codes]"
phone_codes="[$phone_codes]"
whatsapp_codes="[$whatsapp_codes]"

# Update index.html with obfuscated values
sed -e "s|{{EMAIL_CODES}}|$email_codes|g" \
    -e "s|{{PHONE_CODES}}|$phone_codes|g" \
    -e "s|{{WHATSAPP_CODES}}|$whatsapp_codes|g" \
    index-template.html > index.html

echo "index.html generated with obfuscated contact info"
