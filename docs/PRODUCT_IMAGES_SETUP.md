# Product Images Setup Guide

This guide explains how to add product images to your Smokeshop application.

## Overview

The application is already configured to display product images. You just need to:
1. Generate the images using AI
2. Place them in the correct folder
3. Update the database with image URLs

---

## Step 1: Generate Product Images

### Using the Product List

Open [PRODUCT_IMAGE_LIST.md](../PRODUCT_IMAGE_LIST.md) - this file contains:
- All 24 products with detailed descriptions
- Image specifications (1000x1000px, JPG format, white/light gray background)
- Proper naming convention for each file

### Recommended AI Image Generators

- **DALL-E 3** (via ChatGPT Plus or API)
- **Midjourney**
- **Stable Diffusion** (RunwayML, DreamStudio)
- **Adobe Firefly**
- **Leonardo.ai**

### Example Prompts

For best results, use prompts like:

```
Product photography of a [PRODUCT NAME], [DESCRIPTION], 
studio lighting, white background, professional e-commerce photo, 
1000x1000px, centered composition, high quality
```

Example for GLASS-001:
```
Product photography of a crystal clear beaker bong, 14 inches tall with 
ice catcher and percolator, thick borosilicate glass, transparent glass 
with visible internal percolator system, studio lighting, white background, 
professional e-commerce photo, centered composition, high quality
```

---

## Step 2: Save and Place Images

### File Naming Convention

Each image MUST be named exactly as the SKU with `.jpg` extension:

```
GLASS-001.jpg
GLASS-002.jpg
VAPE-001.jpg
ACC-001.jpg
CBD-001.jpg
CANN-001.jpg
...etc
```

### Directory Location

Place all generated images in:
```
/opt/Smokeshop/public/images/products/
```

This folder has been created for you.

### Upload Methods

**Option 1: Direct Upload (if using VS Code or file access)**
- Simply copy all JPG files to `/opt/Smokeshop/public/images/products/`

**Option 2: Using SCP/SFTP**
```bash
scp /local/path/to/images/*.jpg user@your-vps:/opt/Smokeshop/public/images/products/
```

**Option 3: Using wget/curl (if images are hosted)**
```bash
cd /opt/Smokeshop/public/images/products/
wget https://your-domain.com/images/GLASS-001.jpg
# Repeat for each image
```

---

## Step 3: Update Database with Image URLs

Once all images are in place, run this SQL script in your Supabase SQL Editor:

**File:** `scripts/016_update_product_images.sql`

This script updates all products with the correct image paths like:
```sql
UPDATE public.products SET image_url = '/images/products/GLASS-001.jpg' WHERE sku = 'GLASS-001';
```

### Running the Script

1. Open Supabase Dashboard: https://supabase.com/dashboard
2. Navigate to your project: `nckaphoqwlikocvpsscr`
3. Go to **SQL Editor**
4. Copy and paste the contents of `scripts/016_update_product_images.sql`
5. Click **Run**

---

## Step 4: Verify Images are Working

### Check the Shop Page

1. Visit: `http://localhost:3000/shop`
2. You should see product images on all product cards
3. If you see a placeholder package icon, the image is missing

### Check Individual Product Pages

1. Click on any product
2. Visit: `http://localhost:3000/shop/GLASS-001` (or any SKU)
3. Product images should display in the large preview area

### Check the Cart

1. Add items to cart
2. Visit: `http://localhost:3000/cart`
3. Cart items should show product thumbnails

---

## Troubleshooting

### Images Not Showing?

**Check file names:**
```bash
cd /opt/Smokeshop/public/images/products/
ls -la
```

Ensure files are named exactly: `GLASS-001.jpg` (case-sensitive, no spaces)

**Check file permissions:**
```bash
chmod 644 /opt/Smokeshop/public/images/products/*.jpg
```

**Restart the application:**
```bash
cd /opt/Smokeshop
pm2 restart smokeshop
```

**Check browser console:**
- Open DevTools (F12)
- Look for 404 errors on image URLs
- Verify the image path is `/images/products/SKU.jpg`

**Verify database URLs:**
```sql
SELECT sku, image_url FROM public.products LIMIT 5;
```

Should return URLs like: `/images/products/GLASS-001.jpg`

---

## Image Specifications Summary

| Attribute | Value |
|-----------|-------|
| Format | JPG (preferred), PNG, or WebP |
| Dimensions | 1000x1000px (square) |
| Aspect Ratio | 1:1 |
| Background | White or light gray |
| File Size | < 500KB per image (optimize for web) |
| Naming | `{SKU}.jpg` (e.g., `GLASS-001.jpg`) |
| Location | `/opt/Smokeshop/public/images/products/` |

---

## Next.js Static Assets

In Next.js, files in the `public/` directory are served at the root level.

- File location: `/opt/Smokeshop/public/images/products/GLASS-001.jpg`
- URL in app: `/images/products/GLASS-001.jpg`
- Full URL: `http://localhost:3000/images/products/GLASS-001.jpg`

You can test image access directly:
```
http://localhost:3000/images/products/GLASS-001.jpg
```

---

## Complete Checklist

- [ ] Review [PRODUCT_IMAGE_LIST.md](../PRODUCT_IMAGE_LIST.md)
- [ ] Generate 24 product images using AI
- [ ] Save images with correct naming: `SKU.jpg`
- [ ] Upload all images to `/opt/Smokeshop/public/images/products/`
- [ ] Run `scripts/016_update_product_images.sql` in Supabase
- [ ] Restart application: `pm2 restart smokeshop`
- [ ] Visit `/shop` to verify images display
- [ ] Test product detail pages
- [ ] Test cart thumbnail images

---

## File Paths Reference

```
/opt/Smokeshop/
├── PRODUCT_IMAGE_LIST.md              # Product descriptions for AI
├── public/
│   └── images/
│       └── products/
│           ├── GLASS-001.jpg          # Place images here
│           ├── GLASS-002.jpg
│           ├── VAPE-001.jpg
│           └── ...
└── scripts/
    └── 016_update_product_images.sql  # Database update script
```

---

## Optional: Image Optimization

For better performance, optimize images before uploading:

**Using ImageMagick:**
```bash
mogrify -resize 1000x1000 -quality 85 *.jpg
```

**Using online tools:**
- TinyPNG: https://tinypng.com/
- Squoosh: https://squoosh.app/
- ImageOptim (Mac): https://imageoptim.com/

Target: ~100-200KB per image for fast loading.
