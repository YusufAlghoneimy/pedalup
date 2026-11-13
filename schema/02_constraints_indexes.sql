-- =====================================================================
-- 02_constraints_indexes.sql
-- Business-rule CHECK constraints and indexes for the Smart Bike Rental schema.
-- Run AFTER 01_create_tables.sql. The schema is valid without this file, but
-- this is what keeps bad data out and keeps queries fast.
--
-- Values marked [ASSUMED] are NOT listed in the ERD. Adjust them to match
-- the values your application really uses.
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- A. CHECK CONSTRAINTS
-- ---------------------------------------------------------------------

-- riders / admins / companies
ALTER TABLE riders
    ADD CONSTRAINT ck_riders_email_format  CHECK (position('@' IN giu_email) > 1),
    ADD CONSTRAINT ck_riders_failed_logins CHECK (failed_login_attempts >= 0);
ALTER TABLE admins
    ADD CONSTRAINT ck_admins_email_format  CHECK (position('@' IN admin_email) > 1);
ALTER TABLE companies
    ADD CONSTRAINT ck_companies_email_format CHECK (position('@' IN company_email) > 1);

-- id_verifications
ALTER TABLE id_verifications
    ADD CONSTRAINT ck_idv_status CHECK (verification_status IN ('pending','approved','rejected')),   -- [ASSUMED]
    ADD CONSTRAINT ck_idv_rejection_reason
        CHECK (verification_status <> 'rejected' OR rejection_reason IS NOT NULL);

-- notifications: the ERD has both links optional; require exactly one recipient
ALTER TABLE notifications
    ADD CONSTRAINT ck_notif_one_recipient CHECK (num_nonnulls(rider_id, admin_id) = 1);

-- plans, subscriptions, pricing, discounts
ALTER TABLE subscription_plans
    ADD CONSTRAINT ck_plan_price    CHECK (price >= 0),
    ADD CONSTRAINT ck_plan_duration CHECK (duration_days > 0);
ALTER TABLE subscriptions
    ADD CONSTRAINT ck_sub_dates CHECK (expiry_date >= start_date);
ALTER TABLE pricing_rules
    ADD CONSTRAINT ck_pr_rates CHECK (per_minute_rate >= 0 AND overtime_rate >= 0),
    -- a company cannot start two different rules at the same instant
    ADD CONSTRAINT uq_pr_company_start UNIQUE (company_id, effective_start_date);
ALTER TABLE discounts
    ADD CONSTRAINT ck_disc_percent   CHECK (percent > 0 AND percent <= 100),
    ADD CONSTRAINT ck_disc_min_rides CHECK (min_monthly_rides >= 0);

-- stations, docks, bikes, alerts, areas
ALTER TABLE stations
    ADD CONSTRAINT ck_station_lat   CHECK (latitude  BETWEEN -90  AND 90),
    ADD CONSTRAINT ck_station_lng   CHECK (longitude BETWEEN -180 AND 180),
    ADD CONSTRAINT ck_station_docks CHECK (total_docks >= 0),
    ADD CONSTRAINT ck_station_docks_available CHECK (docks_available BETWEEN 0 AND total_docks);
ALTER TABLE docks
    ADD CONSTRAINT ck_dock_status CHECK (dock_status IN ('available','occupied','faulty'));           -- [ASSUMED]
ALTER TABLE bikes
    ADD CONSTRAINT ck_bike_status CHECK (bike_status IN ('available','in_use','maintenance','out_of_service')),  -- [ASSUMED]
    ADD CONSTRAINT ck_bike_lat    CHECK (latitude  BETWEEN -90  AND 90),
    ADD CONSTRAINT ck_bike_lng    CHECK (longitude BETWEEN -180 AND 180),
    ADD CONSTRAINT ck_bike_coords_pair CHECK ((latitude IS NULL) = (longitude IS NULL)),
    -- a physical dock holds at most one bike
    ADD CONSTRAINT uq_bike_dock   UNIQUE (dock_id);
ALTER TABLE station_alerts
    ADD CONSTRAINT ck_alert_count  CHECK (bike_count >= 0),
    ADD CONSTRAINT ck_alert_status CHECK (alert_status IN ('open','resolved')),                      -- [ASSUMED]
    ADD CONSTRAINT ck_alert_resolved_consistent
        CHECK ((alert_status = 'resolved') = (resolved_at IS NOT NULL)),
    ADD CONSTRAINT ck_alert_dates  CHECK (resolved_at IS NULL OR resolved_at >= created_at);
ALTER TABLE areas
    ADD CONSTRAINT ck_area_block_hours CHECK (block_duration_hours IS NULL OR block_duration_hours > 0);

-- sessions
ALTER TABLE sessions
    ADD CONSTRAINT ck_sess_status CHECK (session_status IN ('active','completed','cancelled')),      -- [ASSUMED]
    ADD CONSTRAINT ck_sess_free_minutes CHECK (free_minutes >= 0),
    ADD CONSTRAINT ck_sess_times  CHECK (end_time IS NULL OR end_time >= start_time),
    ADD CONSTRAINT ck_sess_completed_has_end
        CHECK (session_status <> 'completed' OR (end_time IS NOT NULL AND end_station_id IS NOT NULL));

-- payments
ALTER TABLE payments
    ADD CONSTRAINT ck_pay_amount CHECK (amount >= 0),
    ADD CONSTRAINT ck_pay_method CHECK (payment_method IN ('card','wallet')),                        -- [ASSUMED]
    ADD CONSTRAINT ck_pay_status CHECK (payment_status IN ('pending','paid','failed','refunded')),  -- [ASSUMED]
    -- the ERD has both links optional; a payment covers a ride OR a subscription, never both/neither
    ADD CONSTRAINT ck_pay_one_target CHECK (num_nonnulls(session_id, subscription_id) = 1),
    ADD CONSTRAINT ck_pay_paid_has_receipt CHECK (payment_status <> 'paid' OR receipt_number IS NOT NULL);

-- blocks, complaints, maintenance
ALTER TABLE blocks
    ADD CONSTRAINT ck_block_ends CHECK (ends_at IS NULL OR ends_at > starts_at);
ALTER TABLE complaints
    ADD CONSTRAINT ck_comp_status CHECK (status IN ('open','in_progress','resolved','closed')),      -- [ASSUMED]
    ADD CONSTRAINT ck_comp_closed CHECK (closed_at IS NULL OR closed_at >= time_stamp);
ALTER TABLE maintenance_tasks
    ADD CONSTRAINT ck_mt_status CHECK (task_status IN ('scheduled','in_progress','completed','cancelled')),  -- [ASSUMED]
    ADD CONSTRAINT ck_mt_technician_name CHECK (technician_id IS NULL OR technician_name IS NOT NULL);

-- ---------------------------------------------------------------------
-- B. BUSINESS-RULE INDEXES (race-condition guards)
-- ---------------------------------------------------------------------
-- At most one live ride per bike, and one per rider.
CREATE UNIQUE INDEX uq_sess_one_active_per_bike  ON sessions (bike_id)  WHERE session_status = 'active';
CREATE UNIQUE INDEX uq_sess_one_active_per_rider ON sessions (rider_id) WHERE session_status = 'active';

-- ---------------------------------------------------------------------
-- C. FOREIGN-KEY INDEXES (PostgreSQL does not create these automatically)
--    Skipped where a unique constraint already leads with the column:
--    bikes.dock_id and pricing_rules.company_id.
-- ---------------------------------------------------------------------
CREATE INDEX ix_idv_rider          ON id_verifications (rider_id);
CREATE INDEX ix_idv_admin          ON id_verifications (reviewed_by_admin_id);
CREATE INDEX ix_notif_rider        ON notifications (rider_id);
CREATE INDEX ix_notif_admin        ON notifications (admin_id);
CREATE INDEX ix_plan_company       ON subscription_plans (company_id);
CREATE INDEX ix_sub_rider          ON subscriptions (rider_id);
CREATE INDEX ix_sub_plan           ON subscriptions (subscription_plan_id);
CREATE INDEX ix_disc_company       ON discounts (company_id);
CREATE INDEX ix_dock_station       ON docks (station_id);
CREATE INDEX ix_alert_station      ON station_alerts (station_id);
CREATE INDEX ix_area_admin         ON areas (admin_id);
CREATE INDEX ix_sess_rider         ON sessions (rider_id);
CREATE INDEX ix_sess_bike          ON sessions (bike_id);
CREATE INDEX ix_sess_start_station ON sessions (start_station_id);
CREATE INDEX ix_sess_end_station   ON sessions (end_station_id);
CREATE INDEX ix_sess_pricing_rule  ON sessions (pricing_rule_id);
CREATE INDEX ix_sess_subscription  ON sessions (subscription_id);
CREATE INDEX ix_pay_session        ON payments (session_id);
CREATE INDEX ix_pay_subscription   ON payments (subscription_id);
CREATE INDEX ix_pay_discount       ON payments (discount_id);
CREATE INDEX ix_block_rider        ON blocks (rider_id);
CREATE INDEX ix_block_session      ON blocks (session_id);
CREATE INDEX ix_block_area         ON blocks (area_id);
CREATE INDEX ix_comp_rider         ON complaints (rider_id);
CREATE INDEX ix_comp_bike          ON complaints (bike_id);
CREATE INDEX ix_comp_station       ON complaints (station_id);
CREATE INDEX ix_comp_session       ON complaints (session_id);
CREATE INDEX ix_mt_bike            ON maintenance_tasks (bike_id);
CREATE INDEX ix_mt_complaint       ON maintenance_tasks (complaint_id);
CREATE INDEX ix_mt_admin           ON maintenance_tasks (admin_id);

-- ---------------------------------------------------------------------
-- D. QUERY-SUPPORT INDEXES
-- ---------------------------------------------------------------------
CREATE INDEX ix_bike_status      ON bikes (bike_status);
CREATE INDEX ix_sess_start_time  ON sessions (start_time);
CREATE INDEX ix_comp_status      ON complaints (status);
CREATE INDEX ix_alert_open       ON station_alerts (station_id) WHERE alert_status = 'open';
CREATE INDEX ix_mt_scheduled     ON maintenance_tasks (scheduled_date) WHERE task_status IN ('scheduled','in_progress');

COMMIT;
