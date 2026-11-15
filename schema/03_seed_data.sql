-- =====================================================================
-- 03_seed_data.sql
-- Sample rows for TESTING ONLY. Run after 01_create_tables.sql and
-- 02_constraints_indexes.sql.
--
-- All e-mails use reserved ".example" domains, all password hashes are
-- placeholders (not real credentials), and coordinates are rough placeholders.
--
-- The data is designed to exercise every table, every foreign key
-- (including the optional ones) and the interesting states:
--   rider locked / unverified / blocked, active + completed + cancelled
--   rides, paid + failed payments, discounts, open + resolved alerts, etc.
--
-- To re-run on a database that already has seed data, first uncomment:
-- TRUNCATE riders, admins, companies, stations, bikes, docks RESTART IDENTITY CASCADE;
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- Actors
-- ---------------------------------------------------------------------
INSERT INTO riders (rider_id, giu_email, password_hash, email_verified, failed_login_attempts, locked_until, referral_code) VALUES
(1, 'rider01@giu.example', '$2b$12$SAMPLE.HASH.FOR.TESTING.ONLY.NOT.A.REAL.PASSWORD', TRUE,  0, NULL,                           'REF-R01'),
(2, 'rider02@giu.example', '$2b$12$SAMPLE.HASH.FOR.TESTING.ONLY.NOT.A.REAL.PASSWORD', TRUE,  0, NULL,                           'REF-R02'),
(3, 'rider03@giu.example', '$2b$12$SAMPLE.HASH.FOR.TESTING.ONLY.NOT.A.REAL.PASSWORD', TRUE,  5, now() + interval '1 day',        'REF-R03'),  -- locked after failed logins
(4, 'rider04@giu.example', '$2b$12$SAMPLE.HASH.FOR.TESTING.ONLY.NOT.A.REAL.PASSWORD', FALSE, 0, NULL,                           'REF-R04'),  -- e-mail not verified
(5, 'rider05@giu.example', '$2b$12$SAMPLE.HASH.FOR.TESTING.ONLY.NOT.A.REAL.PASSWORD', TRUE,  0, NULL,                           'REF-R05');

INSERT INTO admins (admin_id, admin_email, password_hash) VALUES
(1, 'admin1@bikes.example', '$2b$12$SAMPLE.HASH.FOR.TESTING.ONLY.NOT.A.REAL.PASSWORD'),
(2, 'admin2@bikes.example', '$2b$12$SAMPLE.HASH.FOR.TESTING.ONLY.NOT.A.REAL.PASSWORD');

INSERT INTO companies (company_id, company_email, password_hash) VALUES
(1, 'ops@nilebikes.example',    '$2b$12$SAMPLE.HASH.FOR.TESTING.ONLY.NOT.A.REAL.PASSWORD'),
(2, 'ops@campuscycle.example',  '$2b$12$SAMPLE.HASH.FOR.TESTING.ONLY.NOT.A.REAL.PASSWORD');

-- ---------------------------------------------------------------------
-- Onboarding & notifications
-- ---------------------------------------------------------------------
INSERT INTO id_verifications (id_verification_id, rider_id, reviewed_by_admin_id, id_photo_url, verification_status, rejection_reason, submitted_at) VALUES
(1, 1, 1,    'https://files.example/id/rider01.jpg', 'approved', NULL,                         now() - interval '40 days'),
(2, 2, 2,    'https://files.example/id/rider02.jpg', 'approved', NULL,                         now() - interval '35 days'),
(3, 3, 1,    'https://files.example/id/rider03.jpg', 'approved', NULL,                         now() - interval '30 days'),
(4, 4, 1,    'https://files.example/id/rider04.jpg', 'rejected', 'ID photo is blurry',         now() - interval '3 days'),
(5, 5, NULL, 'https://files.example/id/rider05.jpg', 'pending',  NULL,                         now() - interval '1 hour');   -- not reviewed yet

INSERT INTO notifications (notification_id, rider_id, admin_id, type, message, created_at) VALUES
(1, 1,    NULL, 'ride_started',     'Your ride has started. Enjoy!',                      now() - interval '3 days'),
(2, 1,    NULL, 'payment_receipt',  'Payment received. Receipt RCPT-000003.',             now() - interval '10 days'),
(3, 4,    NULL, 'id_rejected',      'Your ID photo was rejected: ID photo is blurry.',    now() - interval '3 days'),
(4, NULL, 1,    'low_bikes_alert',  'Station "Library Plaza" is running low on bikes.',   now() - interval '2 hours'),
(5, NULL, 2,    'new_complaint',    'New complaint CMP-0004 needs review.',               now() - interval '1 day');

-- ---------------------------------------------------------------------
-- Plans, subscriptions, pricing, discounts
-- ---------------------------------------------------------------------
INSERT INTO subscription_plans (subscription_plan_id, company_id, plan_name, price, duration_days, includes) VALUES
(1, 1, 'Weekly Pass',   150.00,   7, 'Unlimited rides, 30 free minutes each'),
(2, 1, 'Monthly Pass',  450.00,  30, 'Unlimited rides, 30 free minutes each'),
(3, 2, 'Semester Pass', 1500.00, 120, 'Unlimited rides, 45 free minutes each');

INSERT INTO subscriptions (subscription_id, rider_id, subscription_plan_id, start_date, expiry_date) VALUES
(1, 1, 2, CURRENT_DATE - 10, CURRENT_DATE + 20),    -- rider01: active Monthly Pass
(2, 2, 1, CURRENT_DATE - 20, CURRENT_DATE - 13),    -- rider02: expired Weekly Pass
(3, 5, 3, CURRENT_DATE - 30, CURRENT_DATE + 90);    -- rider05: active Semester Pass

INSERT INTO pricing_rules (pricing_rule_id, company_id, per_minute_rate, overtime_rate, effective_start_date) VALUES
(1, 1, 0.50, 1.00, '2026-01-01 00:00:00+00'),       -- company 1, original rate
(2, 1, 0.60, 1.20, '2026-09-01 00:00:00+00'),       -- company 1, current rate
(3, 2, 0.40, 0.90, '2026-01-01 00:00:00+00');       -- company 2

INSERT INTO discounts (discount_id, company_id, discount_type, percent, min_monthly_rides) VALUES
(1, 1, 'loyalty',    10.00, 20),
(2, 1, 'subscriber', 15.00,  0),
(3, 2, 'student',     5.00,  0);

-- ---------------------------------------------------------------------
-- Infrastructure
-- (total_docks / docks_available below match the docks inserted further down)
-- ---------------------------------------------------------------------
INSERT INTO stations (station_id, station_name, station_type, latitude, longitude, total_docks, docks_available) VALUES
(1, 'Main Gate',          'campus', 30.023100, 31.738900, 4, 1),
(2, 'Library Plaza',      'campus', 30.026000, 31.741000, 3, 1),
(3, 'Dorms',              'campus', 30.021500, 31.743500, 3, 2),
(4, 'Engineering Block',  'hub',    30.028000, 31.737000, 2, 1);

INSERT INTO docks (dock_id, station_id, dock_status) VALUES
(1, 1, 'occupied'), (2, 1, 'occupied'), (3, 1, 'available'), (4, 1, 'faulty'),
(5, 2, 'occupied'), (6, 2, 'occupied'), (7, 2, 'available'),
(8, 3, 'occupied'), (9, 3, 'available'), (10, 3, 'available'),
(11, 4, 'occupied'), (12, 4, 'available');

INSERT INTO bikes (bike_id, dock_id, qr_code, bike_status, latitude, longitude, last_location_at, next_maintenance_date) VALUES
(1, 1,    'QR-B001', 'available',      30.023100, 31.738900, now() - interval '5 minutes',  CURRENT_DATE + 60),
(2, 2,    'QR-B002', 'available',      30.023100, 31.738900, now() - interval '5 minutes',  CURRENT_DATE + 1),
(3, 5,    'QR-B003', 'available',      30.026000, 31.741000, now() - interval '5 minutes',  CURRENT_DATE + 45),
(4, 6,    'QR-B004', 'available',      30.026000, 31.741000, now() - interval '5 minutes',  CURRENT_DATE + 30),
(5, 8,    'QR-B005', 'available',      NULL,      NULL,      NULL,                          CURRENT_DATE + 7),
(6, NULL, 'QR-B006', 'in_use',         30.024500, 31.740200, now() - interval '1 minute',   CURRENT_DATE + 90),   -- out on the active ride
(7, 11,   'QR-B007', 'maintenance',    30.028000, 31.737000, now() - interval '3 days',     CURRENT_DATE + 14),
(8, NULL, 'QR-B008', 'out_of_service', 30.022000, 31.742000, now() - interval '2 days',     NULL);               -- flat tyre, left off-dock

INSERT INTO station_alerts (station_alert_id, station_id, bike_count, alert_status, created_at, resolved_at) VALUES
(1, 2, 2, 'open',     now() - interval '2 hours',  NULL),
(2, 1, 0, 'resolved', now() - interval '1 day',    now() - interval '20 hours'),
(3, 3, 1, 'open',     now() - interval '30 minutes', NULL);

INSERT INTO areas (area_id, admin_id, area_type, boundary, block_duration_hours) VALUES
(1, 1, 'block', '{"type":"Polygon","coordinates":[[[31.735,30.020],[31.737,30.020],[31.737,30.022],[31.735,30.022],[31.735,30.020]]]}', 24),
(2, 1, 'allow', '{"type":"Polygon","coordinates":[[[31.730,30.015],[31.750,30.015],[31.750,30.035],[31.730,30.035],[31.730,30.015]]]}', NULL),
(3, 2, 'block', '{"type":"Polygon","coordinates":[[[31.745,30.030],[31.748,30.030],[31.748,30.033],[31.745,30.033],[31.745,30.030]]]}', 48);

-- ---------------------------------------------------------------------
-- Rides
-- ---------------------------------------------------------------------
INSERT INTO sessions (session_id, rider_id, bike_id, start_station_id, end_station_id, pricing_rule_id, subscription_id, start_time, end_time, free_minutes, session_status) VALUES
-- 1: rider01, subscriber, 25 min, fully covered by free minutes
(1, 1, 1, 1, 2,    2, 1,    now() - interval '3 days',                          now() - interval '3 days' + interval '25 minutes', 30, 'completed'),
-- 2: rider02, pay-per-ride (subscription expired), 40 min
(2, 2, 3, 2, 3,    2, NULL, now() - interval '2 days',                          now() - interval '2 days' + interval '40 minutes', 0,  'completed'),
-- 3: rider05, Semester Pass, 55 min (10 min overtime)
(3, 5, 5, 3, 1,    3, 3,    now() - interval '1 day',                           now() - interval '1 day'  + interval '55 minutes', 45, 'completed'),
-- 4: rider02, ACTIVE ride right now (no end yet)
(4, 2, 6, 1, NULL, 2, NULL, now() - interval '15 minutes',                      NULL,                                              0,  'active'),
-- 5: rider03, cancelled ride (bike was faulty)
(5, 3, 1, 1, NULL, 2, NULL, now() - interval '4 days',                          now() - interval '4 days' + interval '1 minute',   0,  'cancelled'),
-- 6: rider03, 90 min ride, payment later failed -> rider blocked
(6, 3, 4, 2, 4,    2, NULL, now() - interval '2 days',                          now() - interval '2 days' + interval '90 minutes', 0,  'completed'),
-- 7: rider01, older ride under the original pricing rule
(7, 1, 3, 3, 1,    1, NULL, now() - interval '40 days',                         now() - interval '40 days' + interval '20 minutes', 0, 'completed');

-- ---------------------------------------------------------------------
-- Payments  (a payment covers a session OR a subscription)
-- ---------------------------------------------------------------------
INSERT INTO payments (payment_id, session_id, subscription_id, discount_id, receipt_number, amount, payment_method, payment_status, failure_reason) VALUES
(1, 2,    NULL, 1,    'RCPT-000001',  21.60, 'card',   'paid',   NULL),              -- 40 min x 0.60 = 24.00, minus 10% loyalty
(2, 6,    NULL, NULL, NULL,           54.00, 'card',   'failed', 'Card declined'),   -- 90 min x 0.60
(3, 7,    NULL, NULL, 'RCPT-000002',  10.00, 'wallet', 'paid',   NULL),              -- 20 min x 0.50
(4, NULL, 1,    NULL, 'RCPT-000003', 450.00, 'card',   'paid',   NULL),              -- Monthly Pass
(5, 3,    NULL, NULL, 'RCPT-000004',   9.00, 'wallet', 'paid',   NULL),              -- 10 overtime min x 0.90
(6, NULL, 3,    3,    'RCPT-000005', 1425.00,'card',   'paid',   NULL),              -- Semester Pass, minus 5% student
(7, NULL, 2,    NULL, 'RCPT-000006', 150.00, 'wallet', 'paid',   NULL);              -- Weekly Pass (now expired)

-- ---------------------------------------------------------------------
-- Blocks, complaints, maintenance
-- ---------------------------------------------------------------------
INSERT INTO blocks (block_id, rider_id, session_id, area_id, reason, starts_at, ends_at) VALUES
(1, 3, 6,    NULL, 'Unpaid ride fee',                          now() - interval '1 day',  now() + interval '2 days'),
(2, 2, 2,    1,    'Parked inside a restricted area',          now() - interval '5 days', now() - interval '4 days'),   -- already expired
(3, 4, NULL, NULL, 'Manual block by admin: rejected ID',       now() - interval '1 day',  NULL);                         -- open-ended

INSERT INTO complaints (complaint_id, rider_id, bike_id, station_id, session_id, reference_number, description, photo_url, status, time_stamp, closed_at) VALUES
(1, 1, 2,    NULL, NULL, 'CMP-0001', 'Brake feels loose.',                      'https://files.example/c/1.jpg', 'open',        now() - interval '2 days',  NULL),
(2, 2, 3,    2,    2,    'CMP-0002', 'Seat could not be adjusted.',             NULL,                            'in_progress', now() - interval '1 day',   NULL),
(3, 5, NULL, 3,    NULL, 'CMP-0003', 'Dock 10 does not release the bike.',      NULL,                            'closed',      now() - interval '6 days',  now() - interval '5 days'),
(4, 1, 8,    NULL, NULL, 'CMP-0004', 'Front tyre is flat.',                     'https://files.example/c/4.jpg', 'open',        now() - interval '1 day',   NULL);

INSERT INTO maintenance_tasks (maintenance_task_id, bike_id, complaint_id, admin_id, technician_id, technician_name, scheduled_date, task_status) VALUES
(1, 2, 1,    1, 101,  'Technician A', CURRENT_DATE + 1, 'scheduled'),     -- created from complaint CMP-0001
(2, 8, 4,    1, 102,  'Technician B', CURRENT_DATE,     'in_progress'),   -- created from complaint CMP-0004
(3, 7, NULL, 2, 101,  'Technician A', CURRENT_DATE - 3, 'completed'),     -- routine maintenance
(4, 5, NULL, 2, NULL, NULL,           CURRENT_DATE + 7, 'scheduled');     -- not yet assigned

-- ---------------------------------------------------------------------
-- Move every identity sequence past the explicit ids used above so that
-- the application's next INSERT (without an id) does not collide.
-- ---------------------------------------------------------------------
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN
        SELECT table_name, column_name
        FROM information_schema.columns
        WHERE table_schema = 'public' AND is_identity = 'YES'
    LOOP
        EXECUTE format(
            'SELECT setval(pg_get_serial_sequence(%L, %L), COALESCE(MAX(%I), 1), MAX(%I) IS NOT NULL) FROM %I',
            'public.' || r.table_name, r.column_name, r.column_name, r.column_name, r.table_name);
    END LOOP;
END $$;

COMMIT;

-- Quick sanity check: row count per table (single-line statement on purpose, so any SQL client runs it as one command)
SELECT table_name, (xpath('/row/c/text()', query_to_xml(format('SELECT count(*) AS c FROM %I.%I', table_schema, table_name), false, true, '')))[1]::text::int AS row_count FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' ORDER BY table_name;
