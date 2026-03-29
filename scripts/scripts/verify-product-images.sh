#!/bin/bash
# Verify all product images exist

echo "🔍 Checking for product images..."
echo ""

IMAGES_DIR="/opt/Smokeshop/public/images/products"
MISSING=0
FOUND=0

# List of all product SKUs
SKUS=(
  "GLASS-001" "GLASS-002" "GLASS-003" "GLASS-004"
  "VAPE-001" "VAPE-002" "VAPE-003" "VAPE-004"
  "ROLL-001" "ROLL-002" "ROLL-003" "ROLL-004"
  "ACC-001" "ACC-002" "ACC-003" "ACC-004"
  "CBD-001" "CBD-002" "CBD-003" "CBD-004"
  "CANN-001" "CANN-002" "CANN-003" "CANN-004"
)

for SKU in "${SKUS[@]}"; do
  FILE="${IMAGES_DIR}/${SKU}.jpg"
  if [ -f "$FILE" ]; then
    SIZE=$(du -h "$FILE" | cut -f1)
    echo "✅ ${SKU}.jpg (${SIZE})"
    ((FOUND++))
  else
    echo "❌ ${SKU}.jpg - MISSING"
    ((MISSING++))
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Found: ${FOUND}/24"
echo "Missing: ${MISSING}/24"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $MISSING -eq 0 ]; then
  echo ""
  echo "🎉 All product images are in place!"
  echo ""
  echo "Next steps:"
  echo "1. Run scripts/016_update_product_images.sql in Supabase"
  echo "2. Restart app: pm2 restart smokeshop"
  echo "3. Visit http://localhost:3000/shop to see images"
else
  echo ""
  echo "⚠️  Some images are missing. Please generate and upload them."
  echo ""
  echo "See PRODUCT_IMAGE_LIST.md for product descriptions."
fi

exit $MISSING
