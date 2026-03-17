-- ============================================================
-- FILE 04: BULL / BEAR PHASE DURATION ANALYSIS
-- Project : Bitcoin Four-Year Cycle Analysis
-- Purpose : Deep-dive into timing patterns across cycle phases
-- ============================================================


-- ──────────────────────────────────────────────────────────────
-- QUERY 1: Complete Phase Timeline — All Cycles
-- Full chronological view of every cycle phase
-- ──────────────────────────────────────────────────────────────
SELECT
    c.cycle_name,
    p.phase_name,
    p.phase_type,
    p.start_date,
    COALESCE(p.end_date::TEXT, 'Ongoing')                      AS end_date,
    COALESCE(p.duration_days::TEXT, 'Ongoing')                 AS duration_days,
    '$' || TO_CHAR(p.start_price, 'FM999,999,990.00')         AS start_price,
    COALESCE('$' || TO_CHAR(p.end_price,'FM999,999,990.00'), 'TBD')
                                                               AS end_price,
    p.pct_change || '%'                                        AS pct_change,
    p.key_event
FROM cycle_phases p
JOIN btc_cycles c ON c.cycle_id = p.cycle_id
ORDER BY p.start_date;


-- ──────────────────────────────────────────────────────────────
-- QUERY 2: Bull Market Statistics — Cycle Comparison
-- Side-by-side comparison of each bull run's length and gains
-- ──────────────────────────────────────────────────────────────
SELECT
    c.cycle_name,
    p.phase_name,
    p.start_date                                               AS bull_start,
    p.end_date                                                 AS bull_end,
    p.duration_days                                            AS bull_days,
    ROUND(p.duration_days / 30.44, 1)                         AS bull_months,

    '$' || TO_CHAR(p.start_price,'FM999,999,990.00')          AS start_price,
    '$' || TO_CHAR(p.end_price,  'FM999,999,990.00')          AS ath_price,
    p.pct_change                                               AS gain_pct,

    -- Daily average gain during bull
    ROUND(p.pct_change / p.duration_days, 2)                  AS avg_daily_gain_pct,

    -- Gain per month
    ROUND(p.pct_change / (p.duration_days / 30.44), 1)        AS avg_monthly_gain_pct

FROM cycle_phases p
JOIN btc_cycles c ON c.cycle_id = p.cycle_id
WHERE p.phase_type = 'bull'
ORDER BY p.start_date;


-- ──────────────────────────────────────────────────────────────
-- QUERY 3: Bear Market Statistics — Cycle Comparison
-- How each bear played out in terms of time and severity
-- ──────────────────────────────────────────────────────────────
SELECT
    c.cycle_name,
    p.phase_name,
    p.start_date                                               AS bear_start,
    COALESCE(p.end_date::TEXT, 'Ongoing')                     AS bear_end,
    COALESCE(p.duration_days::TEXT, 'Ongoing')                AS bear_days,

    '$' || TO_CHAR(p.start_price,'FM999,999,990.00')          AS ath_price,
    COALESCE('$' || TO_CHAR(p.end_price,'FM999,999,990.00'), 'TBD')
                                                               AS bottom_price,
    p.pct_change                                               AS drawdown_pct,

    -- If bear has ended: monthly decline rate
    CASE
        WHEN p.duration_days IS NOT NULL
        THEN ROUND(p.pct_change / (p.duration_days / 30.44), 2)
        ELSE NULL
    END                                                        AS avg_monthly_decline_pct,

    p.key_event                                                AS primary_catalyst

FROM cycle_phases p
JOIN btc_cycles c ON c.cycle_id = p.cycle_id
WHERE p.phase_type = 'bear'
ORDER BY p.start_date;


-- ──────────────────────────────────────────────────────────────
-- QUERY 4: Bull vs Bear Asymmetry
-- Time spent in bull phases vs bear phases per cycle
-- ──────────────────────────────────────────────────────────────
SELECT
    c.cycle_name,

    SUM(CASE WHEN p.phase_type IN ('bull','accumulation','recovery')
        THEN p.duration_days ELSE 0 END)                      AS days_in_uptrend,

    SUM(CASE WHEN p.phase_type IN ('bear','correction')
        THEN p.duration_days ELSE 0 END)                      AS days_in_downtrend,

    ROUND(
        100.0 * SUM(CASE WHEN p.phase_type IN ('bull','accumulation','recovery')
                    THEN p.duration_days ELSE 0 END)
        / NULLIF(SUM(p.duration_days), 0)
    , 1)                                                       AS pct_time_in_uptrend,

    MAX(CASE WHEN p.phase_type = 'bull'
        THEN p.pct_change END)                                 AS peak_bull_gain_pct,

    MIN(CASE WHEN p.phase_type = 'bear'
        THEN p.pct_change END)                                 AS peak_bear_loss_pct

FROM cycle_phases p
JOIN btc_cycles c ON c.cycle_id = p.cycle_id
WHERE p.duration_days IS NOT NULL
GROUP BY c.cycle_id, c.cycle_name
ORDER BY c.cycle_id;


-- ──────────────────────────────────────────────────────────────
-- QUERY 5: Four-Year Cycle Calendar
-- How many days does each full cycle span?
-- Projects Cycle 5 timing
-- ──────────────────────────────────────────────────────────────
SELECT
    c.cycle_id,
    c.cycle_name,
    c.halving_date                                             AS cycle_start_halving,

    -- Next halving date (= start of next cycle)
    LEAD(c.halving_date) OVER (ORDER BY c.cycle_id)           AS next_halving_date,

    -- Cycle length in days
    LEAD(c.halving_date) OVER (ORDER BY c.cycle_id)
        - c.halving_date                                       AS cycle_length_days,

    -- Cycle length in years
    ROUND(
        (LEAD(c.halving_date) OVER (ORDER BY c.cycle_id)
         - c.halving_date)::NUMERIC / 365.25
    , 2)                                                       AS cycle_length_years,

    c.ath_date,
    c.ath_price_usd,
    c.bull_return_pct                                          AS cycle_return_pct

FROM btc_cycles c

UNION ALL

-- Project Cycle 5
SELECT
    5, 'Cycle 5 (Projected)', '2028-04-01'::DATE,
    '2032-04-01'::DATE, 1461, 4.00,
    NULL, NULL, NULL

ORDER BY cycle_id;


-- ──────────────────────────────────────────────────────────────
-- QUERY 6: Monthly Price Momentum
-- Rolling analysis of price change from monthly snapshots
-- ──────────────────────────────────────────────────────────────
SELECT
    p.price_date,
    c.cycle_name,
    p.phase_type,
    p.close_price,

    -- Price vs halving price for that cycle
    ROUND(100.0 * (p.close_price / cyc.halving_price_usd - 1), 1)
                                                               AS pct_from_halving_price,

    -- Price vs cycle ATH
    ROUND(100.0 * (p.close_price / cyc.ath_price_usd - 1), 1)
                                                               AS pct_from_ath,

    -- MoM change
    ROUND(100.0 * (
        p.close_price
        / LAG(p.close_price) OVER (ORDER BY p.price_date) - 1
    ), 1)                                                      AS mom_pct_change,

    p.note

FROM btc_monthly_prices p
JOIN btc_cycles c ON c.cycle_id = p.cycle_id
JOIN btc_cycles cyc ON cyc.cycle_id = p.cycle_id
ORDER BY p.price_date;
