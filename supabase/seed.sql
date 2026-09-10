-- =============================================================================
-- KISANSETU (SIH26032) - DEVELOPMENT SEED SCRIPT
-- Team: ODE TO CODE
-- Description: Development and staging seed data for verifying end-to-end flows.
-- Demonstrates: Ramesh Kumar, Wheat produce, Procurement Centre, Booking,
-- Queue entries, Procurement record, Payment record, Notifications, and Dispute.
-- NOTE: Never execute in production environments with live farmer identities.
-- =============================================================================

-- Clean existing demo records if present
DO $$
DECLARE
    v_centre_id UUID := '11111111-1111-1111-1111-111111111111';
    v_farmer_id UUID := '22222222-2222-2222-2222-222222222222';
    v_officer_id UUID := '33333333-3333-3333-3333-333333333333';
    v_produce_id UUID := '44444444-4444-4444-4444-444444444444';
    v_booking_id UUID := '55555555-5555-5555-5555-555555555555';
BEGIN
    -- 1. Procurement Centre
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
        current_load_percent = EXCLUDED.current_load_percent;

    -- 2. Farmer Profile (Ramesh Kumar)
    -- Assumes a corresponding auth.users row exists in a real environment
    -- For local seed scripts, this provides the public profile representation
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

    -- 3. Farmer Produce
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

    -- 4. Booking
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

    -- 5. Queue Entry
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

    -- 6. Procurement Record
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

    -- 7. Payment Record
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

    -- 8. Notifications
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

    -- 9. Dispute
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
