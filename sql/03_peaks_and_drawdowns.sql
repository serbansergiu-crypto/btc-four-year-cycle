-- ============================================================
-- FILE 03: CYCLE PEAKS, BOTTOMS & DRAWDOWN ANALYSIS
-- Project : Bitcoin Four-Year Cycle Analysis
-- Purpose : Quantify bull/bear dynamics across all 4 cycles
-- ============================================================


-- ──────────────────────────────────────────────────────────────
-- QUERY 1: Full Cycle Summary — Peaks, Bottoms, and Key Stats
-- ──────────────────────────────────────────────────────────────
SELECT
    c.cycle_id,
    c.cycle_name,

    -- Halving
    c.halving_date,
    '$' || TO_CHAR(c.halving_price_usd, 'FM999,999,990.00')  AS halving_price,

    -- ATH
    c.ath_date,
    '$' || TO_CHAR(c.ath_price_usd,     'FM999,999,990.00')  AS cycle_ath,
    c.days_halving_to_ath                                     AS days_halving_to_ath,
    c.bull_return_pct || '%'                                  AS bull_return,

    -- Bear
    COALESCE(c.bear_bottom_date::TEXT, 'Ongoing')            AS bear_bottom_date,
    COALESCE('$' || TO_CHAR(c.bear_bottom_usd,'FM999,999,990.00'), 'TBD') AS bear_bottom,
    c.max_drawdown_pct || '%'                                 AS max_drawdown,
    COALESCE(c.days_ath_to_bottom::TEXT, 'Ongoing')          AS days_ath_to_bottom,

    -- Recovery multiple (bottom to next halving)
    CASE
        WHEN c.cycle_id < 4 THEN
            ROUND(
                (SELECT h2.price_at_halving
                 FROM halving_events h2
                 WHERE h2.halving_id = c.cycle_id + 1)
                / c.bear_bottom_usd, 1
            )
        ELSE NULL
    END                                                       AS bottom_to_next_halving_multiple

FROM btc_cycles c
ORDER BY c.cycle_id;


-- ──────────────────────────────────────────────────────────────
-- QUERY 2: Drawdown Severity Trend
-- Confirms the "each bear is less severe" hypothesis
-- ──────────────────────────────────────────────────────────────
WITH drawdowns AS (
    SELECT
        cycle_id,
        cycle_name,
        max_drawdown_pct,
        LAG(max_drawdown_pct) OVER (ORDER BY cycle_id)  AS prev_drawdown,
        bear_bottom_usd,
        ath_price_usd
    FROM btc_cycles
    WHERE max_drawdown_pct IS NOT NULL
)
SELECT
    cycle_id,
    cycle_name,
    ath_price_usd,
    bear_bottom_usd,
    max_drawdown_pct                                         AS drawdown_pct,
    prev_drawdown                                            AS prev_cycle_drawdown_pct,
    ROUND(max_drawdown_pct - prev_drawdown, 1)               AS improvement_pct,

    -- Rank: 1 = worst bear, 4 = mildest
    RANK() OVER (ORDER BY max_drawdown_pct DESC)             AS severity_rank_worst_first,

    -- Is this a new "less severe" record?
    CASE
        WHEN max_drawdown_pct > LAG(max_drawdown_pct) OVER (ORDER BY cycle_id)
        THEN 'Worsened'
        WHEN max_drawdown_pct < LAG(max_drawdown_pct) OVER (ORDER BY cycle_id)
        THEN '✓ Improved (less severe)'
        ELSE 'First cycle'
    END                                                      AS vs_prev_cycle

FROM drawdowns
ORDER BY cycle_id;


-- ──────────────────────────────────────────────────────────────
-- QUERY 3: Current Cycle 4 Bear Projection
-- If ATH was $126,296, where would the bottom land?
-- Uses historical drawdown percentages as scenarios
-- ──────────────────────────────────────────────────────────────
WITH cycle4_ath AS (
    SELECT ath_price_usd FROM btc_cycles WHERE cycle_id = 4
)
SELECT
    scenario,
    drawdown_pct,
    ROUND(ath.ath_price_usd * (1 + drawdown_pct / 100.0), 0)  AS implied_bottom_usd,
    historical_reference
FROM cycle4_ath ath
CROSS JOIN (VALUES
    ('Conservative (ETF floor)',    -50.0, 'Cycle 4 mid-2024 support zone'),
    ('Moderate',                    -60.0, 'Between 2020 halving and 2021 support'),
    ('Historical average (−70%)',   -70.0, 'Average of Cycles 1-3 extrapolated'),
    ('Cycle 3 analog',              -73.0, 'Matching 2021–2022 drawdown severity'),
    ('Cycle 2 analog',              -77.5, 'Matching 2017–2018 drawdown severity'),
    ('Extreme / Max historical',    -85.0, 'Cycle 1/2 extreme — unlikely with ETFs')
) AS scenarios(scenario, drawdown_pct, historical_reference)
ORDER BY drawdown_pct DESC;


-- ──────────────────────────────────────────────────────────────
-- QUERY 4: Phase Duration Analysis
-- How long does each phase type last across cycles?
-- ──────────────────────────────────────────────────────────────
SELECT
    phase_type,
    COUNT(*)                                                   AS occurrences,
    ROUND(AVG(duration_days), 0)                               AS avg_duration_days,
    MIN(duration_days)                                         AS min_days,
    MAX(duration_days)                                         AS max_days,
    ROUND(AVG(pct_change), 1)                                  AS avg_pct_change,
    MIN(pct_change)                                            AS worst_pct_change,
    MAX(pct_change)                                            AS best_pct_change
FROM cycle_phases
WHERE duration_days IS NOT NULL
GROUP BY phase_type
ORDER BY avg_pct_change DESC;


-- ──────────────────────────────────────────────────────────────
-- QUERY 5: Price at Even Intervals Post-ATH
-- Measures how fast each bear market declines
-- at 30/90/180/365 days after cycle ATH
-- ──────────────────────────────────────────────────────────────
SELECT
    c.cycle_name,
    c.ath_price_usd                                            AS ath_price,
    c.ath_date,

    -- How much was the drawdown by each checkpoint?
    -- Approximated from monthly price data for cycles with data
    ROUND(100.0 * (
        (SELECT p.close_price
         FROM btc_monthly_prices p
         WHERE p.price_date BETWEEN c.ath_date + 25 AND c.ath_date + 60
           AND p.cycle_id = c.cycle_id
         ORDER BY ABS(p.price_date - (c.ath_date + 45))
         LIMIT 1)
        / c.ath_price_usd - 1
    ), 1)                                                      AS approx_drawdown_by_day60,

    c.max_drawdown_pct                                         AS final_max_drawdown,
    c.days_ath_to_bottom                                       AS total_bear_days,
    c.bear_bottom_usd

FROM btc_cycles c
WHERE c.ath_price_usd IS NOT NULL
ORDER BY c.cycle_id;
