-- ─────────────────────────────────────────────────────────────
-- 02-seed.sql  –  Initial demo data
-- ─────────────────────────────────────────────────────────────

INSERT INTO categories (name, slug) VALUES
    ('Electronics',  'electronics'),
    ('Peripherals',  'peripherals'),
    ('Audio',        'audio'),
    ('Storage',      'storage'),
    ('Accessories',  'accessories');

INSERT INTO users (username, email, full_name) VALUES
    ('user_001', 'alice@example.com',  'Alice Silva'),
    ('user_002', 'bob@example.com',    'Bob Santos'),
    ('user_003', 'carol@example.com',  'Carol Lima'),
    ('user_004', 'daniel@example.com', 'Daniel Costa'),
    ('user_005', 'eva@example.com',    'Eva Rocha');

INSERT INTO products (sku, name, description, category_id, price, stock) VALUES
    ('P001', 'Notebook Pro 15',    'i7 processor, 16GB RAM, 512GB SSD',        1, 4599.90,  50),
    ('P002', 'RGB Gaming Mouse',   'Adjustable DPI 800-12000, 7 buttons',       2,  189.90, 200),
    ('P003', 'Mechanical Keyboard','Blue switch, RGB backlight',                2,  349.90, 150),
    ('P004', '27in 4K Monitor',    'IPS, 144Hz, HDR400, USB-C',                1, 2199.90,  30),
    ('P005', 'Wireless Headset',   'ANC, 30h battery, retractable microphone',  3,  499.90,  80),
    ('P006', 'HD 1080p Webcam',    '30fps, built-in microphone, plug-and-play', 2,  279.90, 120),
    ('P007', '1TB NVMe SSD',       'Read 3500MB/s, write 3000MB/s',             4,  399.90,  90),
    ('P008', '7-Port USB-C Hub',   '4K HDMI, SD card, USB 3.0 x4',             5,  129.90, 300);

INSERT INTO orders (user_id, status, total)
SELECT id, 'delivered',  4599.90 FROM users WHERE username = 'user_001';
INSERT INTO orders (user_id, status, total)
SELECT id, 'processing',  379.80 FROM users WHERE username = 'user_002';
INSERT INTO orders (user_id, status, total)
SELECT id, 'shipped',    2199.90 FROM users WHERE username = 'user_001';
INSERT INTO orders (user_id, status, total)
SELECT id, 'pending',     629.80 FROM users WHERE username = 'user_003';
INSERT INTO orders (user_id, status, total)
SELECT id, 'cancelled',   499.90 FROM users WHERE username = 'user_004';

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 1, id, 1, price FROM products WHERE sku = 'P001';
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 2, id, 2, price FROM products WHERE sku = 'P002';
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 3, id, 1, price FROM products WHERE sku = 'P004';
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 4, id, 1, price FROM products WHERE sku = 'P003';
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 4, id, 1, price FROM products WHERE sku = 'P006';
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 5, id, 1, price FROM products WHERE sku = 'P005';
