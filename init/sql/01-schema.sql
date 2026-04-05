-- ─────────────────────────────────────────────────────────────
-- 01-schema.sql  –  Database schema (Aurora PostgreSQL via RDS)
-- ─────────────────────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    username    VARCHAR(50) UNIQUE NOT NULL,
    email       VARCHAR(150) UNIQUE NOT NULL,
    full_name   VARCHAR(150),
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    active      BOOLEAN     DEFAULT TRUE
);

CREATE TABLE categories (
    id   SERIAL      PRIMARY KEY,
    name VARCHAR(80) UNIQUE NOT NULL,
    slug VARCHAR(80) UNIQUE NOT NULL
);

CREATE TABLE products (
    id          SERIAL          PRIMARY KEY,
    sku         VARCHAR(20)     UNIQUE NOT NULL,
    name        VARCHAR(200)    NOT NULL,
    description TEXT,
    category_id INTEGER         REFERENCES categories(id),
    price       NUMERIC(12, 2)  NOT NULL CHECK (price >= 0),
    stock       INTEGER         NOT NULL DEFAULT 0 CHECK (stock >= 0),
    active      BOOLEAN         DEFAULT TRUE,
    created_at  TIMESTAMPTZ     DEFAULT NOW()
);

CREATE TABLE orders (
    id          SERIAL          PRIMARY KEY,
    user_id     UUID            REFERENCES users(id),
    status      VARCHAR(30)     NOT NULL DEFAULT 'pending'
                                CHECK (status IN ('pending','processing','shipped','delivered','cancelled')),
    total       NUMERIC(12, 2)  NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ     DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     DEFAULT NOW()
);

CREATE TABLE order_items (
    id          SERIAL          PRIMARY KEY,
    order_id    INTEGER         REFERENCES orders(id) ON DELETE CASCADE,
    product_id  INTEGER         REFERENCES products(id),
    quantity    INTEGER         NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(12, 2)  NOT NULL
);

CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_orders_user       ON orders(user_id);
CREATE INDEX idx_orders_status     ON orders(status);
CREATE INDEX idx_order_items_order ON order_items(order_id);

-- Summary view joining orders, users, and items
CREATE VIEW v_order_summary AS
SELECT
    o.id             AS order_id,
    u.username,
    u.email,
    o.status,
    COUNT(oi.id)     AS item_count,
    SUM(oi.quantity * oi.unit_price) AS order_total,
    o.created_at
FROM orders o
JOIN users       u  ON u.id = o.user_id
JOIN order_items oi ON oi.order_id = o.id
GROUP BY o.id, u.username, u.email, o.status, o.created_at;
