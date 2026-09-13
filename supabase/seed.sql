-- =============================================================================
-- KISANSETU (SIH26032) - DEVELOPMENT & EVALUATION SEED SCRIPT
-- Team: ODE TO CODE
--
-- IMPORTANT DEMO & REFERENCE DATA NOTICE:
-- 1. ALL DATA IN THIS SCRIPT IS STRICTLY MOCK / DEMO DATA INTENDED SOLELY FOR
--    SIH JUDGE EVALUATION, STAGING, AND LOCAL INTEGRATION TESTING.
-- 2. ZERO REAL PII: Contains NO real farmer identities, NO actual Aadhaar
--    numbers, NO valid bank account credentials, and NO confidential details.
-- 3. MSP BENCHMARK RATES: All MSP values used are official reference benchmarks
--    aligned with Government of India CCEA pricing (2024-25 / 2025-26) for
--    calculating transparent simulated procurement values.
-- 4. SIMULATION BOUNDARIES: Digital QR check-in, dynamic queues, and DBT payment
--    records in this database reflect simulated workflow prototypes. They do
--    not connect to live SMS telecommunication gateways or banking clearinghouses.
-- 5. DO NOT EXECUTE AGAINST PRODUCTION SERVERS WITH LIVE GOVERNMENT DATA.
-- =============================================================================

DO $$
DECLARE
    v_centre_id   UUID := '11111111-1111-1111-1111-111111111111'; -- Khanna Grain Market
    v_centre_2_id UUID := '11111111-1111-1111-1111-111111111112'; -- Samrala Sub-Yard (Grain Silo)
    v_farmer_id   UUID := '22222222-2222-2222-2222-222222222222'; -- Ramesh Kumar
    v_officer_id  UUID := '33333333-3333-3333-3333-333333333333'; -- Officer 001
    v_produce_id  UUID := '44444444-4444-4444-4444-444444444444'; -- Wheat 50 Qtl
    v_booking_id  UUID := '55555555-5555-5555-5555-555555555555'; -- TK-8492
BEGIN
    -- 0. Safe Demo Auth Users (Creates auth records if run via Supabase SQL Editor)
    -- This ensures foreign key constraints on farmers.id and officer_profiles.officer_id are satisfied
    BEGIN
        INSERT INTO auth.users (
            instance_id,
            id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            phone,
            phone_confirmed_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at
        ) VALUES 
        (
            '00000000-0000-0000-0000-000000000000',
            v_farmer_id,
            'authenticated',
            'authenticated',
            'farmer.ramesh@kisansetu.demo',
            crypt('demo123456', gen_salt('bf')),
            NOW(),
            '9876543210',
            NOW(),
            '{"provider":"phone","providers":["phone"]}',
            '{"name":"Ramesh Kumar","phone":"9876543210","role":"farmer"}',
            NOW(),
            NOW()
        ),
        (
            '00000000-0000-0000-0000-000000000000',
            v_officer_id,
            'authenticated',
            'authenticated',
            'officer001@kisansetu.gov.in',
            crypt('demo123456', gen_salt('bf')),
            NOW(),
            NULL,
            NULL,
            '{"provider":"email","providers":["email"]}',
            '{"name":"Demo Procurement Officer","role":"officer","officer_id":"OFFICER001","centre_id":"11111111-1111-1111-1111-111111111111"}',
            NOW(),
            NOW()
        ) ON CONFLICT (id) DO NOTHING;
    EXCEPTION
        WHEN insufficient_privilege THEN
            -- In restricted environments where auth.users is managed strictly through dashboard
            NULL;
    END;

    -- 1. Primary Procurement Centre (Khanna Grain Market)
    INSERT INTO public.procurement_centres (
        id, name, location, status, capacity, operating_status, current_load_percent, delay_minutes, processing_rate_per_hour
    ) VALUES (
        v_centre_id,
        'Khanna Grain Market',
        'GT Road, Khanna, Punjab - 141401',
        'operational',
        500,
        'operational',
        75,
        0,
        15
    ) ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        location = EXCLUDED.location,
        status = EXCLUDED.status,
        capacity = EXCLUDED.capacity,
        operating_status = EXCLUDED.operating_status,
        current_load_percent = EXCLUDED.current_load_percent,
        delay_minutes = EXCLUDED.delay_minutes,
        processing_rate_per_hour = EXCLUDED.processing_rate_per_hour;

    -- 1.1 Secondary Alternative Procurement Centre (Samrala Sub-Yard)
    -- Seeds alternative centre to demonstrate Dynamic Centre Recommendations
    INSERT INTO public.procurement_centres (
        id, name, location, status, capacity, operating_status, current_load_percent, delay_minutes, processing_rate_per_hour
    ) VALUES (
        v_centre_2_id,
        'Samrala Sub-Yard (Grain Silo)',
        'Samrala Bypass Road, Ludhiana, Punjab - 141114',
        'operational',
        400,
        'operational',
        30,
        0,
        18
    ) ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        location = EXCLUDED.location,
        status = EXCLUDED.status,
        capacity = EXCLUDED.capacity,
        operating_status = EXCLUDED.operating_status,
        current_load_percent = EXCLUDED.current_load_percent,
        delay_minutes = EXCLUDED.delay_minutes,
        processing_rate_per_hour = EXCLUDED.processing_rate_per_hour;

    -- 2. Officer Profile (Officer001 -> Khanna Grain Market)
    INSERT INTO public.officer_profiles (
        officer_id, centre_id, role
    ) VALUES (
        v_officer_id,
        v_centre_id,
        'procurement_officer'
    ) ON CONFLICT (officer_id, centre_id) DO NOTHING;

    -- 3. Farmer Profile (Ramesh Kumar - Demo Persona)
    INSERT INTO public.farmers (
        id, phone, name, preferred_language, created_at, updated_at
    ) VALUES (
        v_farmer_id,
        '9876543210',
        'Ramesh Kumar',
        'hi',
        NOW(),
        NOW()
    ) ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        phone = EXCLUDED.phone,
        preferred_language = EXCLUDED.preferred_language;

    -- 4. Farmer Produce (Default: Wheat, 50 Quintals)
    INSERT INTO public.farmer_produce (
        id, farmer_id, crop, quantity, created_at, updated_at
    ) VALUES (
        v_produce_id,
        v_farmer_id,
        'Wheat (गेहूं)',
        50.00,
        NOW(),
        NOW()
    ) ON CONFLICT (id) DO UPDATE SET
        crop = EXCLUDED.crop,
        quantity = EXCLUDED.quantity;

    -- 5. Active Demo Booking (Token: TK-8492)
    INSERT INTO public.bookings (
        id, farmer_id, centre_id, produce_id, slot_time, arrival_time, token, status, created_at, updated_at
    ) VALUES (
        v_booking_id,
        v_farmer_id,
        v_centre_id,
        v_produce_id,
        '11:30 AM',
        NOW(),
        'TK-8492',
        'WAITING',
        NOW(),
        NOW()
    ) ON CONFLICT (id) DO UPDATE SET
        token = EXCLUDED.token,
        status = EXCLUDED.status;

    -- 6. Live Queue Entry (Position 7, 6 ahead, ~35 min wait)
    INSERT INTO public.queue_entries (
        id, booking_id, position, people_ahead, status, estimated_wait_minutes, expected_turn, updated_at
    ) VALUES (
        '66666666-6666-6666-6666-666666666666',
        v_booking_id,
        7,
        6,
        'waiting',
        35,
        '12:05 PM',
        NOW()
    ) ON CONFLICT (booking_id) DO UPDATE SET
        position = EXCLUDED.position,
        people_ahead = EXCLUDED.people_ahead,
        status = EXCLUDED.status,
        estimated_wait_minutes = EXCLUDED.estimated_wait_minutes,
        expected_turn = EXCLUDED.expected_turn;

    -- 7. Procurement Record (Gate entry completed, assaying underway)
    INSERT INTO public.procurement_records (
        id, booking_id, expected_quantity, actual_quantity, quality_grade, procurement_stage, discrepancy, created_at, updated_at
    ) VALUES (
        '77777777-7777-7777-7777-777777777777',
        v_booking_id,
        50.00,
        50.20,
        'FAQ',
        'gate_entry',
        FALSE,
        NOW(),
        NOW()
    ) ON CONFLICT (booking_id) DO UPDATE SET
        actual_quantity = EXCLUDED.actual_quantity,
        quality_grade = EXCLUDED.quality_grade,
        procurement_stage = EXCLUDED.procurement_stage;

    -- 8. Payment Record (₹1,14,205 at CCEA 2024-25 Wheat MSP ₹2,275/qtl)
    INSERT INTO public.payments (
        id, booking_id, gross_amount, deductions, net_amount, payment_status, payment_reference, payment_date, created_at, updated_at
    ) VALUES (
        '88888888-8888-8888-8888-888888888888',
        v_booking_id,
        114205.00,
        0.00,
        114205.00,
        'PENDING',
        'PAY-2026-8492',
        NOW(),
        NOW(),
        NOW()
    ) ON CONFLICT (booking_id) DO UPDATE SET
        net_amount = EXCLUDED.net_amount,
        payment_status = EXCLUDED.payment_status;

    -- 9. Proactive Notifications (Booking Confirmed & Go-Time)
    INSERT INTO public.notifications (
        id, farmer_id, type, title, message, is_read, created_at
    ) VALUES (
        '99999999-9999-9999-9999-999999999991',
        v_farmer_id,
        'booking',
        'Booking Confirmed (स्लॉट पुष्ट)',
        'Your procurement slot for Wheat (50 Qtl) is confirmed for 11:30 AM at Khanna Grain Market. Token: TK-8492.',
        FALSE,
        NOW() - INTERVAL '2 hours'
    ) ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.notifications (
        id, farmer_id, type, title, message, is_read, created_at
    ) VALUES (
        '99999999-9999-9999-9999-999999999992',
        v_farmer_id,
        'leave',
        'Optimal Time to Leave (निकलने का सही समय)',
        'Please depart by 10:55 AM. Queue is moving normally with ~35 min estimated wait time.',
        FALSE,
        NOW() - INTERVAL '30 minutes'
    ) ON CONFLICT (id) DO NOTHING;

    -- 10. Sample Dispute Record (Tracked grievance resolution demonstration)
    INSERT INTO public.disputes (
        id, farmer_id, booking_id, category, description, tracking_id, status, created_at, updated_at
    ) VALUES (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        v_farmer_id,
        v_booking_id,
        'weight_mismatch',
        'Scale reading discrepancy noted at secondary weighbridge check.',
        'DSP-8492-01',
        'submitted',
        NOW() - INTERVAL '10 minutes',
        NOW()
    ) ON CONFLICT (id) DO NOTHING;
END $$;
