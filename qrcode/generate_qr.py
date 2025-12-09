#!/usr/bin/env python3
import qrcode
import qrcode.image.svg

# URL to encode
url = "http://daniel.leio.co"

# Create QR code instance with settings optimized for small size
qr = qrcode.QRCode(
    version=1,  # Smallest version (21x21 modules)
    error_correction=qrcode.constants.ERROR_CORRECT_L,  # Lowest error correction for simplest pattern
    box_size=10,  # Size of each box in pixels
    border=4,  # Minimum border size (4 is the minimum per spec)
)

# Add data
qr.add_data(url)
qr.make(fit=True)

print(f"Generating QR codes for: {url}")
print(f"QR Code version: {qr.version}")
print(f"Matrix size: {qr.version * 4 + 17}x{qr.version * 4 + 17} modules")
print()

# Generate original PNG (box_size=10, no border)
qr_png = qrcode.QRCode(
    version=1,
    error_correction=qrcode.constants.ERROR_CORRECT_L,
    box_size=10,
    border=0,
)
qr_png.add_data(url)
qr_png.make(fit=True)
img = qr_png.make_image(fill_color="black", back_color="white")
img.save("qrcode_leio.png")
print(f"✓ Generated: qrcode_leio.png (box_size=10, no border)")

# Generate SVG version (no border)
factory = qrcode.image.svg.SvgPathImage
qr_svg = qrcode.QRCode(
    version=1,
    error_correction=qrcode.constants.ERROR_CORRECT_L,
    image_factory=factory,
    border=0,
)
qr_svg.add_data(url)
qr_svg.make(fit=True)
img_svg = qr_svg.make_image(fill_color="black", back_color="white")
img_svg.save("qrcode_leio.svg")
print(f"✓ Generated: qrcode_leio.svg (vector, no border)")

print("\nAll QR codes generated successfully!")

