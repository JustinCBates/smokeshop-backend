-- Seed sample products across all 6 categories
INSERT INTO public.products (sku, product_name, product_description, category, price_in_cents, delivery_eligible, featured, tags) VALUES
  ('GLASS-001', 'Crystal Clear Beaker Bong', 'Premium 14" beaker bong with ice catcher and percolator. Thick borosilicate glass for durability.', 'glass-pipes-bongs', 7999, true, true, ARRAY['bong', 'beaker', 'glass', 'percolator']),
  ('GLASS-002', 'Emerald Spoon Pipe', 'Hand-blown 4.5" spoon pipe with deep emerald green swirl pattern.', 'glass-pipes-bongs', 2499, true, false, ARRAY['pipe', 'spoon', 'hand pipe']),
  ('GLASS-003', 'Mini Bubbler', 'Compact 6" bubbler with built-in downstem. Perfect for smooth on-the-go hits.', 'glass-pipes-bongs', 3499, true, false, ARRAY['bubbler', 'mini', 'glass']),
  ('GLASS-004', 'Quartz Dab Rig', '8" recycler dab rig with quartz banger included. Medical-grade borosilicate.', 'glass-pipes-bongs', 12999, false, true, ARRAY['dab rig', 'quartz', 'recycler']),

  ('VAPE-001', 'Cloud Chaser Pen', 'Sleek variable voltage vape pen. 510 thread compatible. USB-C charging.', 'vapes-e-cigarettes', 2999, true, true, ARRAY['vape pen', '510 thread', 'battery']),
  ('VAPE-002', 'Ceramic Cartridge 1g', '1 gram empty ceramic cartridge. Lead-free, food-grade materials.', 'vapes-e-cigarettes', 999, true, false, ARRAY['cartridge', 'ceramic', '1g']),
  ('VAPE-003', 'Box Mod 200W', 'Dual 18650 box mod with temperature control. OLED display.', 'vapes-e-cigarettes', 5999, true, false, ARRAY['box mod', '200w', 'temperature control']),
  ('VAPE-004', 'Mango E-Liquid 60ml', 'Premium mango-flavored e-liquid. 70/30 VG/PG. Available in 3mg and 6mg nicotine.', 'vapes-e-cigarettes', 1999, true, false, ARRAY['e-liquid', 'mango', '60ml']),

  ('ROLL-001', 'RAW Classic King Size', 'Unrefined, unbleached king size rolling papers. 32 leaves per pack.', 'rolling-papers-wraps', 399, true, false, ARRAY['rolling papers', 'king size', 'RAW']),
  ('ROLL-002', 'Hemp Blunt Wraps 2-Pack', 'Organic hemp blunt wraps. Slow-burning with natural flavor.', 'rolling-papers-wraps', 299, true, false, ARRAY['blunt wraps', 'hemp', 'organic']),
  ('ROLL-003', 'Pre-Rolled Cones 6-Pack', 'King size pre-rolled cones. Just fill and twist. No rolling skill needed.', 'rolling-papers-wraps', 599, true, true, ARRAY['cones', 'pre-rolled', 'king size']),
  ('ROLL-004', 'Bamboo Rolling Tray', 'Premium bamboo rolling tray with magnetic lid. 7x11 inches.', 'rolling-papers-wraps', 2499, true, false, ARRAY['rolling tray', 'bamboo', 'magnetic']),

  ('ACC-001', '4-Piece Herb Grinder', 'Aircraft-grade aluminum 4-piece grinder with kief catcher. 2.5" diameter.', 'accessories', 1999, true, true, ARRAY['grinder', 'aluminum', 'kief catcher']),
  ('ACC-002', 'Torch Lighter', 'Refillable butane torch lighter with adjustable flame. Wind resistant.', 'accessories', 1499, true, false, ARRAY['lighter', 'torch', 'butane']),
  ('ACC-003', 'Smell-Proof Stash Jar', 'UV-protected glass stash jar with airtight silicone seal. 4oz capacity.', 'accessories', 1299, true, false, ARRAY['storage', 'jar', 'smell-proof']),
  ('ACC-004', 'Silicone Ashtray', 'Heat-resistant silicone ashtray with built-in snuffer. Unbreakable design.', 'accessories', 899, true, false, ARRAY['ashtray', 'silicone', 'heat-resistant']),

  ('CBD-001', 'CBD Gummies 30ct', 'Full-spectrum CBD gummies. 25mg per gummy. Mixed fruit flavors.', 'cbd-delta-products', 3999, true, true, ARRAY['CBD', 'gummies', 'full-spectrum', 'edibles']),
  ('CBD-002', 'Delta-8 Cartridge 1g', '1 gram Delta-8 THC cartridge. Strain-specific terpenes. Lab tested.', 'cbd-delta-products', 2999, true, false, ARRAY['delta-8', 'cartridge', '1g']),
  ('CBD-003', 'CBD Tincture 1000mg', 'Organic CBD oil tincture. 1000mg in 30ml dropper bottle. Natural flavor.', 'cbd-delta-products', 4999, true, false, ARRAY['CBD', 'tincture', 'oil', '1000mg']),
  ('CBD-004', 'CBD Flower 3.5g', 'Premium indoor-grown CBD flower. Under 0.3% THC. Multiple strains available.', 'cbd-delta-products', 2499, false, false, ARRAY['CBD', 'flower', 'hemp']),

  ('CANN-001', 'OG Kush - Indica 3.5g', 'Classic OG Kush. Dense, trichome-rich buds. Earthy pine aroma.', 'cannabis-flower', 3999, false, true, ARRAY['indica', 'OG Kush', '3.5g']),
  ('CANN-002', 'Sour Diesel - Sativa 3.5g', 'Energizing Sour Diesel. Pungent diesel aroma with citrus undertones.', 'cannabis-flower', 4499, false, false, ARRAY['sativa', 'Sour Diesel', '3.5g']),
  ('CANN-003', 'Blue Dream - Hybrid 3.5g', 'Balanced Blue Dream hybrid. Sweet berry aroma. Smooth smoke.', 'cannabis-flower', 4299, false, false, ARRAY['hybrid', 'Blue Dream', '3.5g']),
  ('CANN-004', 'Pre-Roll Pack 5ct', 'Assorted pre-rolls. 0.5g each. Mix of indica and sativa strains.', 'cannabis-flower', 2999, false, true, ARRAY['pre-rolls', 'variety pack', '5ct'])
ON CONFLICT (sku) DO NOTHING;

-- Seed sample regions for Missouri (GeoJSON polygons around major metro areas)
INSERT INTO public.regions (id, region_name, state, boundary, center_lat, center_lng, is_active) VALUES
  ('a1111111-1111-1111-1111-111111111111', 'Kansas City Metro', 'MO',
   '{"type":"Polygon","coordinates":[[[-94.77,39.12],[-94.77,38.88],[-94.40,38.88],[-94.40,39.12],[-94.77,39.12]]]}',
   39.0, -94.585, true),
  ('b2222222-2222-2222-2222-222222222222', 'St. Louis Metro', 'MO',
   '{"type":"Polygon","coordinates":[[[-90.50,38.75],[-90.50,38.52],[-90.10,38.52],[-90.10,38.75],[-90.50,38.75]]]}',
   38.635, -90.3, true),
  ('c3333333-3333-3333-3333-333333333333', 'Springfield Area', 'MO',
   '{"type":"Polygon","coordinates":[[[-93.40,37.28],[-93.40,37.12],[-93.15,37.12],[-93.15,37.28],[-93.40,37.28]]]}',
   37.2, -93.275, true),
  ('d4444444-4444-4444-4444-444444444444', 'Columbia Area', 'MO',
   '{"type":"Polygon","coordinates":[[[-92.45,39.02],[-92.45,38.88],[-92.20,38.88],[-92.20,39.02],[-92.45,39.02]]]}',
   38.95, -92.325, true)
ON CONFLICT (id) DO NOTHING;

-- Seed pickup locations (using lat/lng columns)
INSERT INTO public.pickup_locations (id, location_name, address, state, lat, lng, is_active) VALUES
  ('e5555555-5555-5555-5555-555555555555', 'Generic Smokeshop - Downtown KC', '123 Main St, Kansas City, MO 64106', 'MO',
   39.0997, -94.5786, true),
  ('f6666666-6666-6666-6666-666666666666', 'Generic Smokeshop - St. Louis', '456 Market St, St. Louis, MO 63101', 'MO',
   38.6270, -90.1994, true),
  ('77777777-7777-7777-7777-777777777777', 'Generic Smokeshop - Springfield', '789 Commercial St, Springfield, MO 65803', 'MO',
   37.2090, -93.2923, true)
ON CONFLICT (id) DO NOTHING;

-- Seed region inventory (KC has everything, StL has most, Springfield limited)
INSERT INTO public.region_inventory (sku, region_id, quantity)
SELECT p.sku, 'a1111111-1111-1111-1111-111111111111'::uuid, 50
FROM public.products p WHERE p.delivery_eligible = true
ON CONFLICT (sku, region_id) DO NOTHING;

INSERT INTO public.region_inventory (sku, region_id, quantity)
SELECT p.sku, 'b2222222-2222-2222-2222-222222222222'::uuid, 30
FROM public.products p WHERE p.delivery_eligible = true
ON CONFLICT (sku, region_id) DO NOTHING;

INSERT INTO public.region_inventory (sku, region_id, quantity)
SELECT p.sku, 'c3333333-3333-3333-3333-333333333333'::uuid, 15
FROM public.products p WHERE p.delivery_eligible = true AND p.category IN ('vapes-e-cigarettes', 'rolling-papers-wraps', 'accessories')
ON CONFLICT (sku, region_id) DO NOTHING;

-- Seed pickup inventory (all products at KC/StL, limited at Springfield)
INSERT INTO public.pickup_inventory (sku, pickup_location_id, quantity)
SELECT p.sku, 'e5555555-5555-5555-5555-555555555555'::uuid, 40
FROM public.products p
ON CONFLICT (sku, pickup_location_id) DO NOTHING;

INSERT INTO public.pickup_inventory (sku, pickup_location_id, quantity)
SELECT p.sku, 'f6666666-6666-6666-6666-666666666666'::uuid, 25
FROM public.products p
ON CONFLICT (sku, pickup_location_id) DO NOTHING;

INSERT INTO public.pickup_inventory (sku, pickup_location_id, quantity)
SELECT p.sku, '77777777-7777-7777-7777-777777777777'::uuid, 10
FROM public.products p WHERE p.category IN ('vapes-e-cigarettes', 'rolling-papers-wraps', 'accessories', 'glass-pipes-bongs')
ON CONFLICT (sku, pickup_location_id) DO NOTHING;

-- Seed delivery fee tiers for KC and StL
INSERT INTO public.delivery_fee_tiers (region_id, tier_name, fee_cents, estimated_minutes_min, estimated_minutes_max, sort_order, is_active) VALUES
  ('a1111111-1111-1111-1111-111111111111', 'Express (Under 1 Hour)', 1499, 30, 60, 1, true),
  ('a1111111-1111-1111-1111-111111111111', 'Same Day', 899, 120, 360, 2, true),
  ('a1111111-1111-1111-1111-111111111111', 'Next Day', 499, 1440, 2880, 3, true),
  ('b2222222-2222-2222-2222-222222222222', 'Express (Under 1 Hour)', 1499, 30, 60, 1, true),
  ('b2222222-2222-2222-2222-222222222222', 'Same Day', 999, 120, 360, 2, true),
  ('b2222222-2222-2222-2222-222222222222', 'Next Day', 599, 1440, 2880, 3, true),
  ('c3333333-3333-3333-3333-333333333333', 'Same Day', 1299, 180, 480, 1, true),
  ('c3333333-3333-3333-3333-333333333333', 'Next Day', 799, 1440, 2880, 2, true)
ON CONFLICT DO NOTHING;

-- Seed delivery slots for KC
INSERT INTO public.delivery_slots (region_id, day_of_week, start_time, end_time, fee_cents, max_orders, is_active) VALUES
  ('a1111111-1111-1111-1111-111111111111', 1, '10:00', '14:00', 699, 10, true),
  ('a1111111-1111-1111-1111-111111111111', 1, '14:00', '18:00', 699, 10, true),
  ('a1111111-1111-1111-1111-111111111111', 3, '10:00', '14:00', 699, 10, true),
  ('a1111111-1111-1111-1111-111111111111', 3, '14:00', '18:00', 699, 10, true),
  ('a1111111-1111-1111-1111-111111111111', 5, '10:00', '14:00', 699, 10, true),
  ('a1111111-1111-1111-1111-111111111111', 5, '14:00', '18:00', 699, 10, true)
ON CONFLICT DO NOTHING;
