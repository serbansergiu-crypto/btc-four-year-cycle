-- ============================================================
-- FILE 02: HALVING PRICE IMPACT ANALYSIS
-- Project : Bitcoin Four-Year Cycle Analysis
-- Purpose : Measure price behaviour around each halving event
-- ============================================================


-- ──────────────────────────────────────────────────────────────
-- QUERY 1: Post-Halving Returns — Full Comparison Table
-- Shows price at halving, 30/180/365 days after, cycle ATH,
-- and % gain at each checkpoint
-- ──────────────────────────────────────────────────────────────
SELECT
    h.halving_number                                             AS halving,
    h.halving_date,
    h.block_height,
    h.reward_before_btc || ' → ' || h.reward_after_btc          AS reward_change,
    h.annual_inflation_after,

    -- Prices at key intervals
    '$' || TO_CHAR(h.price_at_halving,  'FM999,999,990.00')     AS price_at_halving,
    '$' || TO_CHAR(h.price_30d_after,   'FM999,999,990.00')     AS price_30d_after,
    '$' || TO_CHAR(h.price_180d_after,  'FM999,999,990.00')     AS price_180d_after,
    '$' || TO_CHAR(h.price_365d_after,  'FM999,999,990.00')     AS price_365d_after,
    '$' || TO_CHAR(h.cycle_ath,         'FM999,999,990.00')     AS cycle_ath,

    -- % gains from halving price
    ROUND((h.price_30d_after  / h.price_at_halving - 1) * 100, 1) AS pct_gain_30d,
    ROUND((h.price_180d_after / h.price_at_halving - 1) * 100, 1) AS pct_gain_180d,
    ROUND((h.price_365d_after / h.price_at_halving - 1) * 100, 1) AS pct_gain_365d,
    h.gain_halving_to_ath                                        AS pct_gain_to_ath,
    h.days_to_ath

FROM halving_events h
WHERE h.price_at_halving IS NOT NULL
ORDER BY h.halving_id;


-- ──────────────────────────────────────────────────────────────
-- QUERY 2: Diminishing Returns Analysis
-- Calculates how post-halving returns shrink each cycle
-- and projects the next cycle's expected gain range
-- ──────────────────────────────────────────────────────────────
WITH returns AS (
    SELECT
        halving_id,
        halving_number,
        gain_halving_to_ath,
        LAG(gain_halving_to_ath) OVER (ORDER BY halving_id) AS prev_cycle_gain
    FROM halving_events
    WHERE gain_halving_to_ath IS NOT NULL
),
decay AS (
    SELECT
        halving_id,
        halving_number,
        gain_halving_to_ath,
        prev_cycle_gain,
        ROUND(
            CASE WHEN prev_cycle_gain IS NOT NULL
            THEN (gain_halving_to_ath / prev_cycle_gain - 1) * 100
            ELSE NULL END, 1
        ) AS cycle_over_cycle_decay_pct
    FROM returns
)
SELECT
    halving_number,
    gain_halving_to_ath    AS ath_gain_pct,
    prev_cycle_gain        AS prev_cycle_ath_gain_pct,
    cycle_over_cycle_decay_pct,
    CASE
        WHEN halving_id = 4 THEN
            'Next (Cycle 5) projected range: ' ||
            ROUND(gain_halving_to_ath * 0.3, 0)  || '% – ' ||
            ROUND(gain_halving_to_ath * 0.6, 0)  || '%'
        ELSE NULL
    END                    AS projection_note
FROM decay
ORDER BY halving_id;


-- ──────────────────────────────────────────────────────────────
-- QUERY 3: Supply Shock Effect — Inflation Rate vs Price Multiplier
-- Shows how each halving cuts supply inflation and
-- the corresponding price multiple achieved
-- ──────────────────────────────────────────────────────────────
SELECT
    h.halving_number,
    h.halving_date,
    h.reward_before_btc                                     AS reward_before,
    h.reward_after_btc                                      AS reward_after,
    h.annual_inflation_after                                AS supply_inflation_post_halving,
    h.price_at_halving                                      AS btc_price,
    h.cycle_ath,
    ROUND(h.cycle_ath / h.price_at_halving, 1)             AS price_multiple,

    -- New BTC entering market per day after halving
    ROUND(h.reward_after_btc * 144, 2)                     AS new_btc_per_day_post,

    -- Annual new supply in USD at halving price
    ROUND(h.reward_after_btc * 144 * 365 * h.price_at_halving / 1e9, 2)
                                                            AS annual_new_supply_usd_billions

FROM halving_events h
WHERE h.price_at_halving IS NOT NULL
ORDER BY h.halving_id;


-- ──────────────────────────────────────────────────────────────
-- QUERY 4: Time-to-ATH Consistency Check
-- Tests whether the halving→ATH window is statistically consistent
-- ──────────────────────────────────────────────────────────────
SELECT
    c.cycle_id,
    c.cycle_name,
    c.halving_date,
    c.ath_date,
    c.days_halving_to_ath,

    -- Is it within the historical 365–546 day window?
    CASE
        WHEN c.days_halving_to_ath BETWEEN 365 AND 560 THEN '✓ Within historical window'
        WHEN c.days_halving_to_ath < 365              THEN '↓ Earlier than expected'
        WHEN c.days_halving_to_ath > 560              THEN '↑ Later than expected'
        ELSE 'Ongoing'
    END                                                    AS window_check,

    -- Days from halving to ATH vs cycle average
    ROUND(
        c.days_halving_to_ath - AVG(c.days_halving_to_ath)
            OVER (PARTITION BY 1)
    , 0)                                                   AS days_vs_avg

FROM btc_cycles c
ORDER BY c.cycle_id;
