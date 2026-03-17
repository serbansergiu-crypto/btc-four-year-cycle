-- ============================================================
-- FILE 05: ALTCOIN CORRELATION & BTC DOMINANCE ANALYSIS
-- Project : Bitcoin Four-Year Cycle Analysis
-- Purpose : Quantify how altcoins perform relative to BTC
--           and how capital rotates across cycle phases
-- ============================================================


-- ──────────────────────────────────────────────────────────────
-- QUERY 1: Altcoin Performance vs BTC — All Cycles
-- Direct comparison: did each alt beat BTC in its cycle?
-- ──────────────────────────────────────────────────────────────
SELECT
    c.cycle_name,
    a.asset_ticker,
    a.asset_name,
    '$' || TO_CHAR(a.cycle_low_usd,  'FM999,999,990.0000')   AS cycle_low,
    '$' || TO_CHAR(a.cycle_high_usd, 'FM999,999,990.0000')   AS cycle_high,
    a.peak_date,
    a.gain_pct                                                 AS gain_pct,

    -- BTC gain for reference (same cycle)
    (SELECT b.gain_pct FROM altcoin_performance b
     WHERE b.cycle_id = a.cycle_id AND b.asset_ticker = 'BTC')
                                                              AS btc_cycle_gain_pct,

    a.gain_vs_btc_multiplier,

    CASE
        WHEN a.asset_ticker = 'BTC'          THEN '— baseline —'
        WHEN a.gain_vs_btc_multiplier >= 10  THEN '🚀 Massively outperformed'
        WHEN a.gain_vs_btc_multiplier >= 3   THEN '✓ Outperformed BTC'
        WHEN a.gain_vs_btc_multiplier >= 1   THEN '~ Roughly matched BTC'
        ELSE                                      '✗ Underperformed BTC'
    END                                                       AS vs_btc_verdict,

    a.notes

FROM altcoin_performance a
JOIN btc_cycles c ON c.cycle_id = a.cycle_id
ORDER BY a.cycle_id, a.gain_vs_btc_multiplier DESC;


-- ──────────────────────────────────────────────────────────────
-- QUERY 2: Best & Worst Altcoin Performers Per Cycle
-- Ranking alts within each cycle
-- ──────────────────────────────────────────────────────────────
SELECT
    c.cycle_name,
    a.asset_ticker,
    a.gain_pct,
    a.gain_vs_btc_multiplier,

    RANK() OVER (
        PARTITION BY a.cycle_id
        ORDER BY a.gain_pct DESC
    )                                                          AS rank_by_gain,

    CASE
        WHEN RANK() OVER (PARTITION BY a.cycle_id ORDER BY a.gain_pct DESC) = 1
        THEN '🥇 Best in cycle'
        WHEN RANK() OVER (PARTITION BY a.cycle_id ORDER BY a.gain_pct DESC) = 2
        THEN '🥈 2nd best'
        WHEN RANK() OVER (PARTITION BY a.cycle_id ORDER BY a.gain_pct ASC) = 1
        THEN '⚠️ Worst in cycle'
        ELSE NULL
    END                                                        AS medal,

    a.notes

FROM altcoin_performance a
JOIN btc_cycles c ON c.cycle_id = a.cycle_id
WHERE a.asset_ticker != 'BTC'
ORDER BY a.cycle_id, rank_by_gain;


-- ──────────────────────────────────────────────────────────────
-- QUERY 3: Cross-Cycle Altcoin Performance Tracker
-- For assets that appeared in multiple cycles (ETH, BNB, DOGE)
-- shows how each performed in successive cycles
-- ──────────────────────────────────────────────────────────────
SELECT
    a.asset_ticker,
    a.asset_name,
    c.cycle_name,
    a.gain_pct,
    a.gain_vs_btc_multiplier,

    -- Cycle-over-cycle change in performance
    a.gain_pct - LAG(a.gain_pct)
        OVER (PARTITION BY a.asset_ticker ORDER BY a.cycle_id) AS gain_vs_prev_cycle,

    a.gain_vs_btc_multiplier - LAG(a.gain_vs_btc_multiplier)
        OVER (PARTITION BY a.asset_ticker ORDER BY a.cycle_id) AS multiplier_vs_prev_cycle

FROM altcoin_performance a
JOIN btc_cycles c ON c.cycle_id = a.cycle_id
WHERE a.asset_ticker IN (
    -- Assets with data in 2+ cycles
    SELECT asset_ticker
    FROM altcoin_performance
    WHERE asset_ticker != 'BTC'
    GROUP BY asset_ticker
    HAVING COUNT(DISTINCT cycle_id) > 1
)
ORDER BY a.asset_ticker, a.cycle_id;


-- ──────────────────────────────────────────────────────────────
-- QUERY 4: BTC Dominance at Cycle Peaks
-- How low did BTC dominance fall at each cycle's altseason peak?
-- ──────────────────────────────────────────────────────────────
SELECT
    c.cycle_name,
    c.ath_date,

    -- BTC dominance at ATH from altcoin data
    MAX(CASE WHEN a.asset_ticker = 'BTC'
        THEN a.btc_dominance_at_peak END)                     AS btc_dominance_at_cycle_peak_pct,

    -- How many alts beat BTC
    SUM(CASE WHEN a.asset_ticker != 'BTC'
              AND a.gain_vs_btc_multiplier > 1
        THEN 1 ELSE 0 END)                                    AS alts_beating_btc_count,

    SUM(CASE WHEN a.asset_ticker != 'BTC'
        THEN 1 ELSE 0 END)                                    AS total_alts_tracked,

    ROUND(100.0 *
        SUM(CASE WHEN a.asset_ticker != 'BTC'
                  AND a.gain_vs_btc_multiplier > 1
            THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN a.asset_ticker != 'BTC' THEN 1 ELSE 0 END), 0)
    , 0)                                                      AS pct_alts_beating_btc,

    -- Average alt multiplier vs BTC
    ROUND(AVG(CASE WHEN a.asset_ticker != 'BTC'
              THEN a.gain_vs_btc_multiplier END), 1)          AS avg_alt_multiplier_vs_btc

FROM altcoin_performance a
JOIN btc_cycles c ON c.cycle_id = a.cycle_id
GROUP BY c.cycle_id, c.cycle_name, c.ath_date
ORDER BY c.cycle_id;


-- ──────────────────────────────────────────────────────────────
-- QUERY 5: Capital Rotation Model
-- Which assets tend to lead / lag BTC in each cycle?
-- Uses peak date vs BTC ATH date to determine rotation timing
-- ──────────────────────────────────────────────────────────────
SELECT
    c.cycle_name,
    a.asset_ticker,
    c.ath_date                                                 AS btc_ath_date,
    a.peak_date                                                AS alt_peak_date,

    -- Days between BTC ATH and alt peak
    a.peak_date - c.ath_date                                   AS days_alt_peaked_after_btc,

    CASE
        WHEN a.peak_date < c.ath_date  - 30  THEN '⬅️ Led BTC (peaked before)'
        WHEN a.peak_date BETWEEN c.ath_date - 30 AND c.ath_date + 30
                                             THEN '↔️  Peaked with BTC'
        WHEN a.peak_date > c.ath_date  + 30  THEN '➡️ Lagged BTC (altseason after)'
        ELSE 'Same day'
    END                                                        AS rotation_timing,

    a.gain_pct,
    a.gain_vs_btc_multiplier

FROM altcoin_performance a
JOIN btc_cycles c ON c.cycle_id = a.cycle_id
WHERE a.asset_ticker != 'BTC'
  AND a.peak_date IS NOT NULL
  AND c.ath_date IS NOT NULL
ORDER BY c.cycle_id, days_alt_peaked_after_btc;


-- ──────────────────────────────────────────────────────────────
-- QUERY 6: Cycle 4 ETF-Era Altcoin Analysis
-- Special focus on what changed in the current cycle
-- ──────────────────────────────────────────────────────────────
SELECT
    a.asset_ticker,
    a.asset_name,
    a.gain_pct                                                 AS cycle4_gain_pct,
    a.gain_vs_btc_multiplier                                   AS multiplier_vs_btc,

    -- Comparison to cycle 3 performance (same asset)
    (SELECT b.gain_pct FROM altcoin_performance b
     WHERE b.asset_ticker = a.asset_ticker AND b.cycle_id = 3)
                                                               AS cycle3_gain_pct,

    ROUND(a.gain_pct -
        COALESCE(
            (SELECT b.gain_pct FROM altcoin_performance b
             WHERE b.asset_ticker = a.asset_ticker AND b.cycle_id = 3),
            0
        )
    , 1)                                                       AS gain_delta_vs_cycle3,

    CASE
        WHEN a.gain_vs_btc_multiplier >= 3  THEN 'ETF era winner ✓'
        WHEN a.gain_vs_btc_multiplier >= 1  THEN 'Kept pace with BTC'
        ELSE 'ETF era underperformer — BTC dominance effect'
    END                                                        AS etf_era_verdict,

    a.notes

FROM altcoin_performance a
WHERE a.cycle_id = 4
ORDER BY a.gain_vs_btc_multiplier DESC;
