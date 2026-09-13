-- =============================================================================
-- KISANSETU (SIH26032) - SUPABASE POSTGRESQL SCHEMA & ROW LEVEL SECURITY (RLS)
-- Team: ODE TO CODE
-- Phase: 10 Backend Foundation
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. CORE TABLES
-- =============================================================================

-- 1.1 Farmers
CREATE TABLE IF NOT EXISTS public.farmers (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone VARCHAR(15) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    preferred_language VARCHAR(10) NOT NULL DEFAULT 'hi',
    state VARCHAR(100) DEFAULT 'Punjab',
    district VARCHAR(100) DEFAULT 'Ludhiana',
    village VARCHAR(150) DEFAULT 'Khanna Kalan',
    aadhaar_masked VARCHAR(20) DEFAULT 'XXXX-XXXX-8492',
    bank_name VARCHAR(150) DEFAULT 'State Bank of India (SBI)',
    account_number_masked VARCHAR(30) DEFAULT 'A/C ending in **4321',
    ifsc_code VARCHAR(15) DEFAULT 'SBIN0001234',
    dbt_status VARCHAR(50) DEFAULT 'Aadhaar-Linked Active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Idempotent column additions for existing deployments
ALTER TABLE public.farmers ADD COLUMN IF NOT EXISTS state VARCHAR(100) DEFAULT 'Punjab';
ALTER TABLE public.farmers ADD COLUMN IF NOT EXISTS district VARCHAR(100) DEFAULT 'Ludhiana';
ALTER TABLE public.farmers ADD COLUMN IF NOT EXISTS village VARCHAR(150) DEFAULT 'Khanna Kalan';
ALTER TABLE public.farmers ADD COLUMN IF NOT EXISTS aadhaar_masked VARCHAR(20) DEFAULT 'XXXX-XXXX-8492';
ALTER TABLE public.farmers ADD COLUMN IF NOT EXISTS bank_name VARCHAR(150) DEFAULT 'State Bank of India (SBI)';
ALTER TABLE public.farmers ADD COLUMN IF NOT EXISTS account_number_masked VARCHAR(30) DEFAULT 'A/C ending in **4321';
ALTER TABLE public.farmers ADD COLUMN IF NOT EXISTS ifsc_code VARCHAR(15) DEFAULT 'SBIN0001234';
ALTER TABLE public.farmers ADD COLUMN IF NOT EXISTS dbt_status VARCHAR(50) DEFAULT 'Aadhaar-Linked Active';

-- 1.2 Procurement Centres
CREATE TABLE IF NOT EXISTS public.procurement_centres (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(150) NOT NULL,
    location VARCHAR(255) NOT NULL,
    address VARCHAR(255),
    state VARCHAR(100) NOT NULL DEFAULT 'Punjab',
    district VARCHAR(100) NOT NULL DEFAULT 'Ludhiana',
    mandal VARCHAR(100) NOT NULL DEFAULT 'Khanna',
    latitude NUMERIC(10, 6),
    longitude NUMERIC(10, 6),
    status VARCHAR(50) NOT NULL DEFAULT 'operational', -- 'operational', 'closed', 'maintenance'
    capacity INTEGER NOT NULL DEFAULT 500, -- in Quintals per day
    operating_status VARCHAR(50) NOT NULL DEFAULT 'operational',
    current_load_percent INTEGER NOT NULL DEFAULT 75,
    delay_minutes INTEGER NOT NULL DEFAULT 0,
    processing_rate_per_hour INTEGER NOT NULL DEFAULT 15,
    available_slots INTEGER NOT NULL DEFAULT 10,
    supported_crops TEXT[] DEFAULT ARRAY['Wheat', 'Paddy (Rice)', 'Mustard', 'Cotton'],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 1.2b India Administrative Locations (Hierarchical State -> District -> Mandal Master)
CREATE TABLE IF NOT EXISTS public.administrative_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    state VARCHAR(100) NOT NULL,
    district VARCHAR(100) NOT NULL,
    mandal VARCHAR(100) NOT NULL,
    state_hi VARCHAR(100),
    state_te VARCHAR(100),
    district_hi VARCHAR(100),
    district_te VARCHAR(100),
    mandal_hi VARCHAR(100),
    mandal_te VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- 1.3 Officer Profiles
CREATE TABLE IF NOT EXISTS public.officer_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    officer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    centre_id UUID NOT NULL REFERENCES public.procurement_centres(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL DEFAULT 'procurement_officer',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(officer_id, centre_id)
);

-- 1.4 Farmer Produce
CREATE TABLE IF NOT EXISTS public.farmer_produce (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID NOT NULL REFERENCES public.farmers(id) ON DELETE CASCADE,
    crop VARCHAR(100) NOT NULL,
    quantity NUMERIC(10, 2) NOT NULL, -- in Quintals
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 1.5 Bookings
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID NOT NULL REFERENCES public.farmers(id) ON DELETE CASCADE,
    centre_id UUID NOT NULL REFERENCES public.procurement_centres(id) ON DELETE CASCADE,
    produce_id UUID REFERENCES public.farmer_produce(id) ON DELETE SET NULL,
    slot_time VARCHAR(50) NOT NULL,
    arrival_time TIMESTAMPTZ,
    token VARCHAR(20) NOT NULL UNIQUE,
    status VARCHAR(50) NOT NULL DEFAULT 'booked', -- 'booked', 'in_queue', 'procuring', 'completed', 'cancelled'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 1.6 Queue Entries
CREATE TABLE IF NOT EXISTS public.queue_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE UNIQUE,
    position INTEGER NOT NULL DEFAULT 1,
    people_ahead INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'waiting', -- 'waiting', 'next', 'in_inspection', 'completed'
    estimated_wait_minutes INTEGER NOT NULL DEFAULT 0,
    expected_turn VARCHAR(50) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 1.7 Procurement Records
CREATE TABLE IF NOT EXISTS public.procurement_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE UNIQUE,
    expected_quantity NUMERIC(10, 2) NOT NULL,
    actual_quantity NUMERIC(10, 2),
    quality_grade VARCHAR(20), -- 'Grade A', 'Grade B', 'Grade C', 'Rejected'
    procurement_stage VARCHAR(50) NOT NULL DEFAULT 'gate_entry', -- 'gate_entry', 'quality_assaying', 'weighbridge', 'acceptance'
    discrepancy BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 1.8 Payments
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE UNIQUE,
    gross_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    deductions NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    net_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    payment_status VARCHAR(50) NOT NULL DEFAULT 'pending', -- 'pending', 'authorized', 'processing', 'completed', 'failed'
    payment_reference VARCHAR(100),
    payment_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 1.9 Notifications
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID NOT NULL REFERENCES public.farmers(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- 'booking', 'queue', 'inspection', 'payment', 'system'
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 1.10 Disputes
CREATE TABLE IF NOT EXISTS public.disputes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID NOT NULL REFERENCES public.farmers(id) ON DELETE CASCADE,
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    category VARCHAR(100) NOT NULL, -- 'weight_mismatch', 'grading_quality', 'payment_delay', 'other'
    description TEXT NOT NULL,
    tracking_id VARCHAR(50) NOT NULL UNIQUE,
    status VARCHAR(50) NOT NULL DEFAULT 'submitted', -- 'submitted', 'under_review', 'resolved', 'rejected'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 2. INDEXES FOR PERFORMANCE
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_farmers_phone ON public.farmers(phone);
CREATE INDEX IF NOT EXISTS idx_bookings_farmer ON public.bookings(farmer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_centre ON public.bookings(centre_id);
CREATE INDEX IF NOT EXISTS idx_bookings_token ON public.bookings(token);
CREATE INDEX IF NOT EXISTS idx_queue_booking ON public.queue_entries(booking_id);
CREATE INDEX IF NOT EXISTS idx_procurement_booking ON public.procurement_records(booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_booking ON public.payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_notifications_farmer ON public.notifications(farmer_id);
CREATE INDEX IF NOT EXISTS idx_disputes_farmer ON public.disputes(farmer_id);
CREATE INDEX IF NOT EXISTS idx_officer_centre ON public.officer_profiles(officer_id, centre_id);
CREATE INDEX IF NOT EXISTS idx_admin_loc_state ON public.administrative_locations(state);
CREATE INDEX IF NOT EXISTS idx_admin_loc_dist ON public.administrative_locations(district);

-- =============================================================================
-- 3. ROW LEVEL SECURITY (RLS) POLICIES
-- Strict zero-blanket-access policy: farmers access own data; officers access assigned centre.
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE public.farmers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.procurement_centres ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.administrative_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.officer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.farmer_produce ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.queue_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.procurement_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.disputes ENABLE ROW LEVEL SECURITY;

-- Helper function: check if current user is officer assigned to centre
CREATE OR REPLACE FUNCTION public.is_officer_for_centre(target_centre_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.officer_profiles
        WHERE officer_id = auth.uid()
        AND centre_id = target_centre_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- 3.1 Farmers Table Policies
CREATE POLICY "Farmers can view own profile"
    ON public.farmers FOR SELECT
    USING (id = auth.uid());

CREATE POLICY "Farmers can update own profile"
    ON public.farmers FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

CREATE POLICY "Farmers can insert own profile"
    ON public.farmers FOR INSERT
    WITH CHECK (id = auth.uid());

-- 3.2 Procurement Centres Policies (Public read for active centres)
CREATE POLICY "Anyone authenticated can view centres"
    ON public.procurement_centres FOR SELECT
    TO authenticated
    USING (true);

-- 3.2b Administrative Locations Policies (Public read for nationwide master)
CREATE POLICY "Public read for administrative locations"
    ON public.administrative_locations FOR SELECT
    USING (true);

-- 3.3 Officer Profiles Policies
CREATE POLICY "Officers can view their own assignment"
    ON public.officer_profiles FOR SELECT
    USING (officer_id = auth.uid());

-- 3.4 Farmer Produce Policies
CREATE POLICY "Farmers can view own produce"
    ON public.farmer_produce FOR SELECT
    USING (farmer_id = auth.uid());

CREATE POLICY "Farmers can insert own produce"
    ON public.farmer_produce FOR INSERT
    WITH CHECK (farmer_id = auth.uid());

CREATE POLICY "Farmers can update own produce"
    ON public.farmer_produce FOR UPDATE
    USING (farmer_id = auth.uid())
    WITH CHECK (farmer_id = auth.uid());

-- 3.5 Bookings Policies
CREATE POLICY "Farmers can view own bookings"
    ON public.bookings FOR SELECT
    USING (farmer_id = auth.uid());

CREATE POLICY "Farmers can create own bookings"
    ON public.bookings FOR INSERT
    WITH CHECK (farmer_id = auth.uid());

CREATE POLICY "Officers can view bookings for their centre"
    ON public.bookings FOR SELECT
    USING (public.is_officer_for_centre(centre_id));

CREATE POLICY "Officers can update bookings for their centre"
    ON public.bookings FOR UPDATE
    USING (public.is_officer_for_centre(centre_id))
    WITH CHECK (public.is_officer_for_centre(centre_id));

-- 3.6 Queue Entries Policies
CREATE POLICY "Farmers can view queue for their bookings"
    ON public.queue_entries FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.bookings
            WHERE bookings.id = queue_entries.booking_id
            AND bookings.farmer_id = auth.uid()
        )
    );

CREATE POLICY "Officers can view and update queue entries for their centre"
    ON public.queue_entries FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.bookings
            WHERE bookings.id = queue_entries.booking_id
            AND public.is_officer_for_centre(bookings.centre_id)
        )
    );

-- 3.7 Procurement Records Policies
CREATE POLICY "Farmers can view procurement records for their bookings"
    ON public.procurement_records FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.bookings
            WHERE bookings.id = procurement_records.booking_id
            AND bookings.farmer_id = auth.uid()
        )
    );

CREATE POLICY "Officers can view and update records for their centre"
    ON public.procurement_records FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.bookings
            WHERE bookings.id = procurement_records.booking_id
            AND public.is_officer_for_centre(bookings.centre_id)
        )
    );

-- 3.8 Payments Policies
CREATE POLICY "Farmers can view payments for their bookings"
    ON public.payments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.bookings
            WHERE bookings.id = payments.booking_id
            AND bookings.farmer_id = auth.uid()
        )
    );

CREATE POLICY "Officers can view and manage payments for their centre"
    ON public.payments FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.bookings
            WHERE bookings.id = payments.booking_id
            AND public.is_officer_for_centre(bookings.centre_id)
        )
    );

-- 3.9 Notifications Policies
CREATE POLICY "Farmers can view own notifications"
    ON public.notifications FOR SELECT
    USING (farmer_id = auth.uid());

CREATE POLICY "Farmers can mark own notifications read"
    ON public.notifications FOR UPDATE
    USING (farmer_id = auth.uid())
    WITH CHECK (farmer_id = auth.uid());

-- 3.10 Disputes Policies
CREATE POLICY "Farmers can view own disputes"
    ON public.disputes FOR SELECT
    USING (farmer_id = auth.uid());

CREATE POLICY "Farmers can create disputes for their bookings"
    ON public.disputes FOR INSERT
    WITH CHECK (
        farmer_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.bookings
            WHERE bookings.id = disputes.booking_id
            AND bookings.farmer_id = auth.uid()
        )
    );

CREATE POLICY "Officers can view and update disputes for their centre"
    ON public.disputes FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.bookings
            WHERE bookings.id = disputes.booking_id
            AND public.is_officer_for_centre(bookings.centre_id)
        )
    );

-- =============================================================================
-- 4. REALTIME PUBLICATION
-- Enable Realtime publication for tables requiring dynamic updates
-- =============================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.queue_entries;
ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
ALTER PUBLICATION supabase_realtime ADD TABLE public.procurement_records;
ALTER PUBLICATION supabase_realtime ADD TABLE public.payments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
