-- ==============================================================================
-- SMART POS DATABASE SCHEMA FOR SUPABASE
-- Point of Sale system: Authentication, Categories, Products, Orders, Order Items,
-- Triggers, Row Level Security (RLS), and Seed Data.
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. TABLE: PROFILES (Extends Supabase Auth users)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT,
    role TEXT NOT NULL DEFAULT 'cashier' CHECK (role IN ('admin', 'cashier', 'manager')),
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.profiles IS 'Stores user and cashier profiles linked to auth.users';

-- ==============================================================================
-- 3. TABLE: CATEGORIES
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.categories IS 'Product categories for grouping menu items';

-- ==============================================================================
-- 4. TABLE: PRODUCTS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    price NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (price >= 0),
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    image_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.products IS 'Product catalog with prices, stock levels, and images';

-- ==============================================================================
-- 5. TABLE: ORDERS (Transactions & Open Nota tabs)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_number TEXT NOT NULL UNIQUE,
    customer_name TEXT,
    status TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'COMPLETED', 'CANCELLED')),
    payment_method TEXT CHECK (payment_method IN ('TUNAI', 'NON_TUNAI') OR payment_method IS NULL),
    total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0),
    pay_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (pay_amount >= 0),
    change_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (change_amount >= 0),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.orders IS 'Order headers for both completed transactions and open bills (Open Nota)';

-- ==============================================================================
-- 6. TABLE: ORDER_ITEMS (Order details / line items)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    product_name TEXT,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (unit_price >= 0),
    subtotal NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (subtotal >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.order_items IS 'Line items belonging to an order';

-- ==============================================================================
-- 7. PERFORMANCE INDEXES
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_products_category_id ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON public.order_items(product_id);

-- ==============================================================================
-- 8. AUTOMATION FUNCTIONS & TRIGGERS
-- ==============================================================================

-- A. Auto update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_products_updated_at ON public.products;
CREATE TRIGGER trg_products_updated_at
    BEFORE UPDATE ON public.products
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_orders_updated_at ON public.orders;
CREATE TRIGGER trg_orders_updated_at
    BEFORE UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- B. Auto create profile when a user registers through Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, email, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
        NEW.email,
        'cashier'
    )
    ON CONFLICT (id) DO UPDATE
    SET
        full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name),
        email = COALESCE(EXCLUDED.email, public.profiles.email);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- 9. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Profiles: Authenticated users can read all profiles; user can update their own
DROP POLICY IF EXISTS "profiles_select_policy" ON public.profiles;
CREATE POLICY "profiles_select_policy" ON public.profiles
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "profiles_insert_policy" ON public.profiles;
CREATE POLICY "profiles_insert_policy" ON public.profiles
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_update_policy" ON public.profiles;
CREATE POLICY "profiles_update_policy" ON public.profiles
    FOR UPDATE TO authenticated USING (auth.uid() = id);

-- Categories: Read allowed for all (auth & anon); modifications for authenticated
DROP POLICY IF EXISTS "categories_select_policy" ON public.categories;
CREATE POLICY "categories_select_policy" ON public.categories
    FOR SELECT TO authenticated, anon USING (true);

DROP POLICY IF EXISTS "categories_insert_policy" ON public.categories;
CREATE POLICY "categories_insert_policy" ON public.categories
    FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "categories_update_policy" ON public.categories;
CREATE POLICY "categories_update_policy" ON public.categories
    FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "categories_delete_policy" ON public.categories;
CREATE POLICY "categories_delete_policy" ON public.categories
    FOR DELETE TO authenticated USING (true);

-- Products: Read allowed for all; full management for authenticated staff
DROP POLICY IF EXISTS "products_select_policy" ON public.products;
CREATE POLICY "products_select_policy" ON public.products
    FOR SELECT TO authenticated, anon USING (true);

DROP POLICY IF EXISTS "products_insert_policy" ON public.products;
CREATE POLICY "products_insert_policy" ON public.products
    FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "products_update_policy" ON public.products;
CREATE POLICY "products_update_policy" ON public.products
    FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "products_delete_policy" ON public.products;
CREATE POLICY "products_delete_policy" ON public.products
    FOR DELETE TO authenticated USING (true);

-- Orders: Authenticated staff can view, insert, update and delete orders
DROP POLICY IF EXISTS "orders_select_policy" ON public.orders;
CREATE POLICY "orders_select_policy" ON public.orders
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "orders_insert_policy" ON public.orders;
CREATE POLICY "orders_insert_policy" ON public.orders
    FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "orders_update_policy" ON public.orders;
CREATE POLICY "orders_update_policy" ON public.orders
    FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "orders_delete_policy" ON public.orders;
CREATE POLICY "orders_delete_policy" ON public.orders
    FOR DELETE TO authenticated USING (true);

-- Order Items: Authenticated staff can view, insert, update and delete items
DROP POLICY IF EXISTS "order_items_select_policy" ON public.order_items;
CREATE POLICY "order_items_select_policy" ON public.order_items
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "order_items_insert_policy" ON public.order_items;
CREATE POLICY "order_items_insert_policy" ON public.order_items
    FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "order_items_update_policy" ON public.order_items;
CREATE POLICY "order_items_update_policy" ON public.order_items
    FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "order_items_delete_policy" ON public.order_items;
CREATE POLICY "order_items_delete_policy" ON public.order_items
    FOR DELETE TO authenticated USING (true);

-- ==============================================================================
-- 10. STORAGE BUCKET CONFIGURATION FOR PRODUCT IMAGES
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "product_images_public_read" ON storage.objects;
CREATE POLICY "product_images_public_read" ON storage.objects
    FOR SELECT TO authenticated, anon
    USING (bucket_id = 'product-images');

DROP POLICY IF EXISTS "product_images_auth_insert" ON storage.objects;
CREATE POLICY "product_images_auth_insert" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'product-images');

DROP POLICY IF EXISTS "product_images_auth_update" ON storage.objects;
CREATE POLICY "product_images_auth_update" ON storage.objects
    FOR UPDATE TO authenticated
    USING (bucket_id = 'product-images');

DROP POLICY IF EXISTS "product_images_auth_delete" ON storage.objects;
CREATE POLICY "product_images_auth_delete" ON storage.objects
    FOR DELETE TO authenticated
    USING (bucket_id = 'product-images');

-- ==============================================================================
-- 11. INITIAL SEED DATA (Kategori & Produk Awal)
-- ==============================================================================

-- Kategori Awal
INSERT INTO public.categories (id, name)
VALUES 
    ('c1111111-1111-1111-1111-111111111111', 'Kopi & Minuman'),
    ('c2222222-2222-2222-2222-222222222222', 'Makanan & Snack'),
    ('c3333333-3333-3333-3333-333333333333', 'Pastry & Bakery'),
    ('c4444444-4444-4444-4444-444444444444', 'Dessert')
ON CONFLICT (name) DO NOTHING;

-- Produk Awal
INSERT INTO public.products (id, category_id, name, price, stock, image_url)
VALUES
    (
        'p1111111-1111-1111-1111-111111111111',
        'c1111111-1111-1111-1111-111111111111',
        'Kopi Susu Aren',
        20000.00,
        50,
        'https://images.unsplash.com/photo-1541167760496-1628856ab772?auto=format&fit=crop&w=400&q=80'
    ),
    (
        'p2222222-2222-2222-2222-222222222222',
        'c2222222-2222-2222-2222-222222222222',
        'Roti Bakar Coklat',
        15000.00,
        30,
        'https://images.unsplash.com/photo-1584776296944-ab6fb57b0bdd?auto=format&fit=crop&w=400&q=80'
    ),
    (
        'p3333333-3333-3333-3333-333333333333',
        'c1111111-1111-1111-1111-111111111111',
        'Espresso Double Shot',
        18000.00,
        60,
        'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?auto=format&fit=crop&w=400&q=80'
    ),
    (
        'p4444444-4444-4444-4444-444444444444',
        'c1111111-1111-1111-1111-111111111111',
        'Matcha Green Tea Latte',
        24000.00,
        25,
        'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?auto=format&fit=crop&w=400&q=80'
    ),
    (
        'p5555555-5555-5555-5555-555555555555',
        'c3333333-3333-3333-3333-333333333333',
        'Croissant Butter Paris',
        22000.00,
        20,
        'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=400&q=80'
    ),
    (
        'p6666666-6666-6666-6666-666666666666',
        'c2222222-2222-2222-2222-222222222222',
        'Nasi Goreng Spesial',
        32000.00,
        40,
        'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&w=400&q=80'
    ),
    (
        'p7777777-7777-7777-7777-777777777777',
        'c4444444-4444-4444-4444-444444444444',
        'Caramel Waffle Ice Cream',
        28000.00,
        15,
        'https://images.unsplash.com/photo-1562376552-0d160a2f238d?auto=format&fit=crop&w=400&q=80'
    ),
    (
        'p8888888-8888-8888-8888-888888888888',
        'c1111111-1111-1111-1111-111111111111',
        'Sparkling Lemon Tea',
        17000.00,
        35,
        'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=400&q=80'
    )
ON CONFLICT (id) DO NOTHING;
