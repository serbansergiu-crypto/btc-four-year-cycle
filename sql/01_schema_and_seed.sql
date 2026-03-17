-- ============================================================
-- FILE 01: SCHEMA & SEED DATA
-- Project : Bitcoin Four-Year Cycle Analysis
-- Covers  : All 4 halving cycles (2012–Present)
-- Engine  : PostgreSQL 14+ (minor tweaks for MySQL/SQLite)
-- ============================================================

-- ── DROP ORDER (foreign keys first) ──────────────────────────
DROP TABLE IF EXISTS altcoin_performance  CASCADE;
DROP TABLE IF EXISTS cycle_phases         CASCADE;
DROP TABLE IF EXISTS btc_monthly_prices   CASCADE;
DROP TABLE IF EXISTS halving_events       CASCADE;
DROP TABLE IF EXISTS btc_cycles           CASCADE;

-- ============================================================
-- TABLE 1: btc_cycles
-- One row per 4-year cycle
-- ============================================================
CREATE TABLE btc_cycles (
    cycle_id          SMALLINT    PRIMARY KEY,           -- 1,2,3,4
    cycle_name        VARCHAR(20) NOT NULL,
    halving_date      DATE        NOT NULL,
    halving_price_usd NUMERIC(12,2),
    ath_date          DATE,
    ath_price_usd     NUMERIC(12,2),
    bear_bottom_date  DATE,
    bear_bottom_usd   NUMERIC(12,2),
    max_drawdown_pct  NUMERIC(5,2),                      -- negative, e.g. -85.20
    days_halving_to_ath  INT,
    days_ath_to_bottom   INT,
    bull_return_pct   NUMERIC(9,2),                      -- halving price → ATH
    cycle_notes       TEXT
);

INSERT INTO btc_cycles VALUES
(1,'Cycle 1','2012-11-28',    12.35, '2013-11-30',  1150.00,
   '2015-01-14',  170.00, -85.20,  367,  409,  9213.00,
   'First halving. Mt.Gox collapse drove bear. China BTC ban.'),

(2,'Cycle 2','2016-07-09',   650.63, '2017-12-17', 19891.00,
   '2018-12-15', 3122.00, -84.30,  525,  363,  2960.00,
   'ICO bubble. ETH/XRP altseason. CME futures launch at peak.'),

(3,'Cycle 3','2020-05-11',  8821.00, '2021-11-10', 68789.00,
   '2022-11-21',15476.00, -77.50,  546,  376,   680.00,
   'Institutional era. Tesla/MicroStrategy. Luna + FTX collapses.'),

(4,'Cycle 4','2024-04-20', 63850.00, '2025-10-06',126296.00,
   NULL,          NULL,   -46.70,  534,  NULL,    98.00,
   'ETF era. Pre-halving ATH in Mar 2024 (unprecedented). Bear ongoing as of Mar 2026.');


-- ============================================================
-- TABLE 2: halving_events
-- Detailed halving data including supply metrics
-- ============================================================
CREATE TABLE halving_events (
    halving_id          SMALLINT    PRIMARY KEY,
    halving_number      VARCHAR(5)  NOT NULL,            -- '1st','2nd',...
    halving_date        DATE        NOT NULL,
    block_height        INT         NOT NULL,
    reward_before_btc   NUMERIC(8,4) NOT NULL,
    reward_after_btc    NUMERIC(8,4) NOT NULL,
    price_at_halving    NUMERIC(12,2),
    price_30d_after     NUMERIC(12,2),
    price_180d_after    NUMERIC(12,2),
    price_365d_after    NUMERIC(12,2),
    cycle_ath           NUMERIC(12,2),
    gain_halving_to_ath NUMERIC(9,2),                    -- %
    days_to_ath         INT,
    annual_inflation_after VARCHAR(10),
    estimated_next_halving DATE
);

INSERT INTO halving_events VALUES
(1,'1st','2012-11-28', 210000, 50.0000, 25.0000,
    12.35,    13.50,   127.00,   984.00,  1150.00, 9213.00, 367, '~12%','2016-07-09'),

(2,'2nd','2016-07-09', 420000, 25.0000, 12.5000,
   650.63,   676.00,   718.00,  2526.00, 19891.00, 2960.00, 525, '~4%', '2020-05-11'),

(3,'3rd','2020-05-11', 630000, 12.5000,  6.2500,
  8821.00,  9750.00, 12560.00, 56000.00, 68789.00,  680.00, 546, '~1.8%','2024-04-20'),

(4,'4th','2024-04-20', 840000,  6.2500,  3.1250,
 63850.00, 57500.00, 62000.00, 97000.00,126296.00,   98.00, 534, '~0.85%','2028-04-01'),

(5,'5th','2028-04-01',1050000,  3.1250,  1.5625,
  NULL,     NULL,     NULL,     NULL,    NULL,       NULL,  NULL,'~0.4%', '2032-04-01');


-- ============================================================
-- TABLE 3: cycle_phases
-- Granular phase breakdown for each cycle
-- ============================================================
CREATE TABLE cycle_phases (
    phase_id      SERIAL      PRIMARY KEY,
    cycle_id      SMALLINT    NOT NULL REFERENCES btc_cycles(cycle_id),
    phase_name    VARCHAR(40) NOT NULL,
    phase_type    VARCHAR(20) NOT NULL,                  -- 'accumulation','bull','bear','recovery','correction'
    start_date    DATE        NOT NULL,
    end_date      DATE,
    duration_days INT         GENERATED ALWAYS AS
                    (CASE WHEN end_date IS NOT NULL
                     THEN end_date - start_date ELSE NULL END) STORED,
    start_price   NUMERIC(12,2),
    end_price     NUMERIC(12,2),
    pct_change    NUMERIC(8,2),
    key_event     TEXT
);

INSERT INTO cycle_phases
    (cycle_id, phase_name, phase_type, start_date, end_date,
     start_price, end_price, pct_change, key_event)
VALUES
-- Cycle 1
(1,'Accumulation',       'accumulation','2012-01-01','2012-11-28',    5.00,   12.35,  +147.0,'Pre-1st halving bottom to halving'),
(1,'Bull Run',           'bull',        '2012-11-28','2013-11-30',   12.35, 1150.00, +9213.0,'Post-halving parabolic; China retail FOMO'),
(1,'Bear Market',        'bear',        '2013-12-01','2015-01-14', 1150.00,  170.00,   -85.2,'Mt. Gox collapse Feb 2014; China ban'),
(1,'Recovery',           'recovery',   '2015-01-14','2016-07-09',  170.00,  650.63,  +282.7,'Bottom accumulation pre-2nd halving'),

-- Cycle 2
(2,'Pre-Halving Rally',  'accumulation','2015-09-01','2016-07-09',  230.00,  650.63,  +183.0,'Classic pre-halving anticipation rally'),
(2,'Bull Run',           'bull',        '2016-07-09','2017-12-17',  650.63,19891.00, +2960.0,'ICO mania; ETH/XRP altseason; CME futures'),
(2,'Bear Market',        'bear',        '2017-12-17','2018-12-15',19891.00, 3122.00,   -84.3,'Regulatory crackdown; ICO bust'),
(2,'Recovery',           'recovery',   '2018-12-15','2020-05-11', 3122.00, 8821.00,  +182.6,'Steady accumulation; COVID dip recovered'),

-- Cycle 3
(3,'Pre-Halving Rally',  'accumulation','2019-12-01','2020-05-11', 7200.00, 8821.00,   +22.5,'Modest rally; COVID-19 crash March 2020'),
(3,'Bull Run Leg 1',     'bull',        '2020-05-11','2021-04-14', 8821.00,64863.00,  +635.5,'Institutional FOMO; MicroStrategy; Coinbase IPO'),
(3,'Mid-Cycle Correction','correction', '2021-04-14','2021-07-20',64863.00,29807.00,   -54.0,'China mining ban; Elon Musk FUD'),
(3,'Bull Run Leg 2',     'bull',        '2021-07-20','2021-11-10',29807.00,68789.00,  +130.8,'NFT mania; SOL/ADA surge; double-top structure'),
(3,'Bear Market',        'bear',        '2021-11-10','2022-11-21',68789.00,15476.00,   -77.5,'Fed rate hikes; Luna May 2022; FTX Nov 2022'),
(3,'Recovery',           'recovery',   '2022-11-21','2024-04-20',15476.00,63850.00,  +312.5,'ETF anticipation; BlackRock filing Jul 2023'),

-- Cycle 4
(4,'Pre-Halving ATH',    'accumulation','2024-01-11','2024-04-20',43500.00,63850.00,   +46.8,'ETFs approved Jan 11; broke ATH BEFORE halving (first time)'),
(4,'Post-Halving Consol.','correction', '2024-04-20','2024-09-01',63850.00,58000.00,    -9.2,'Range-bound; ETF flows absorbing sell pressure'),
(4,'Bull Run',           'bull',        '2024-09-01','2025-10-06',58000.00,126296.00, +117.8,'Election tailwind; ETF inflows; BTC strategic reserve talk'),
(4,'Post-ATH Decline',   'bear',        '2025-10-06', NULL,       126296.00,67550.00,  -46.5,'Ongoing as of Mar 2026; bear not yet confirmed');


-- ============================================================
-- TABLE 4: btc_monthly_prices
-- Key monthly price snapshots (not exhaustive — key dates)
-- ============================================================
CREATE TABLE btc_monthly_prices (
    price_id      SERIAL      PRIMARY KEY,
    price_date    DATE        NOT NULL UNIQUE,
    close_price   NUMERIC(12,2) NOT NULL,
    cycle_id      SMALLINT    REFERENCES btc_cycles(cycle_id),
    phase_type    VARCHAR(20),
    note          TEXT
);

INSERT INTO btc_monthly_prices (price_date, close_price, cycle_id, phase_type, note) VALUES
-- Cycle 1
('2012-11-28',    12.35, 1, 'halving',      '1st Halving'),
('2013-01-01',    13.30, 1, 'bull',         ''),
('2013-04-10',   266.00, 1, 'bull',         'First parabolic spike — April mania'),
('2013-07-01',    65.50, 1, 'correction',   'Post-spike correction'),
('2013-10-01',   198.00, 1, 'bull',         'Recovery leg'),
('2013-11-30',  1150.00, 1, 'ath',          'Cycle 1 ATH'),
('2014-02-01',   550.00, 1, 'bear',         'Mt. Gox collapse'),
('2015-01-14',   170.00, 1, 'bottom',       'Cycle 1 Bear Bottom'),
-- Cycle 2
('2016-07-09',   650.63, 2, 'halving',      '2nd Halving'),
('2016-12-01',   952.00, 2, 'bull',         'Post-halving pickup'),
('2017-03-01',  1265.00, 2, 'bull',         ''),
('2017-06-01',  2975.00, 2, 'bull',         'ETH/ICO mania begins'),
('2017-09-01',  4400.00, 2, 'bull',         'China exchange ban — brief dip then continued'),
('2017-12-17', 19891.00, 2, 'ath',          'Cycle 2 ATH'),
('2018-06-01',  6700.00, 2, 'bear',         'Mid-bear'),
('2018-12-15',  3122.00, 2, 'bottom',       'Cycle 2 Bear Bottom'),
-- Cycle 3
('2020-05-11',  8821.00, 3, 'halving',      '3rd Halving'),
('2020-10-01', 11650.00, 3, 'bull',         ''),
('2020-12-01', 29300.00, 3, 'bull',         'Year-end surge — $20K broken'),
('2021-01-01', 40000.00, 3, 'bull',         '$40K milestone'),
('2021-04-14', 64863.00, 3, 'ath_leg1',     'Cycle 3 first top'),
('2021-07-20', 29807.00, 3, 'correction',   'China ban low — mid-cycle'),
('2021-10-01', 61000.00, 3, 'bull',         'Recovery leg 2'),
('2021-11-10', 68789.00, 3, 'ath',          'Cycle 3 ATH (double-top)'),
('2022-06-01', 17600.00, 3, 'bear',         'Luna collapse aftermath'),
('2022-11-21', 15476.00, 3, 'bottom',       'Cycle 3 Bottom — FTX collapse'),
-- Cycle 4
('2024-01-11', 43500.00, 4, 'accumulation', 'ETF approval date — BlackRock IBIT'),
('2024-03-14', 73750.00, 4, 'pre_ath',      'Pre-halving ATH — unprecedented in BTC history'),
('2024-04-20', 63850.00, 4, 'halving',      '4th Halving'),
('2024-09-01', 57000.00, 4, 'consolidation','Post-halving range low'),
('2024-11-01', 97000.00, 4, 'bull',         'Post-US election pump'),
('2025-01-01',105000.00, 4, 'bull',         'Inauguration rally'),
('2025-10-06',126296.00, 4, 'ath',          'Cycle 4 ATH'),
('2026-02-01', 67550.00, 4, 'post_ath',     'Current price — Feb 2026');


-- ============================================================
-- TABLE 5: altcoin_performance
-- Altcoin gains per cycle vs BTC
-- ============================================================
CREATE TABLE altcoin_performance (
    alt_id        SERIAL      PRIMARY KEY,
    cycle_id      SMALLINT    NOT NULL REFERENCES btc_cycles(cycle_id),
    asset_ticker  VARCHAR(10) NOT NULL,
    asset_name    VARCHAR(40),
    cycle_low_usd NUMERIC(14,6),
    cycle_high_usd NUMERIC(14,6),
    peak_date     DATE,
    gain_pct      NUMERIC(10,2),
    gain_vs_btc_multiplier NUMERIC(8,2),                 -- e.g. 3.7 means 3.7x better than BTC
    btc_dominance_at_peak NUMERIC(5,1),
    notes         TEXT
);

INSERT INTO altcoin_performance
    (cycle_id, asset_ticker, asset_name, cycle_low_usd, cycle_high_usd,
     peak_date, gain_pct, gain_vs_btc_multiplier, btc_dominance_at_peak, notes)
VALUES
-- Cycle 2 alts
(2,'BTC','Bitcoin',         650.63,  19891.00,'2017-12-17',  2960.0,  1.00, 38.0,'Baseline'),
(2,'ETH','Ethereum',          8.00,   1400.00,'2018-01-13', 17400.0,  5.88, 38.0,'ERC20 / ICO platform'),
(2,'LTC','Litecoin',          3.50,    375.00,'2017-12-12', 10614.0,  3.59, 38.0,'Silver to BTC gold narrative'),
(2,'XRP','Ripple',            0.006,    3.84, '2018-01-04', 63900.0, 21.59, 38.0,'Bank partnership hype'),
(2,'BCH','Bitcoin Cash',    310.00,   4355.00,'2017-12-20',  1305.0,  0.44, 38.0,'BTC fork — Roger Ver'),

-- Cycle 3 alts
(3,'BTC','Bitcoin',        8821.00,  68789.00,'2021-11-10',   680.0,  1.00, 38.0,'Baseline'),
(3,'ETH','Ethereum',        185.00,   4868.00,'2021-11-09',  2532.0,  3.72, 38.0,'DeFi summer + ETH2 merge hype'),
(3,'SOL','Solana',            0.77,    260.00,'2021-11-06', 33666.0, 49.51, 38.0,'Fastest TPS narrative; FTX backed'),
(3,'BNB','BNB',              14.00,    688.00,'2021-11-10',  4814.0,  7.08, 38.0,'BSC DeFi ecosystem boom'),
(3,'ADA','Cardano',           0.03,      3.10,'2021-09-02', 10233.0, 15.05, 38.0,'Hoskinson smart contract hype'),
(3,'DOGE','Dogecoin',         0.002,     0.74,'2021-05-08', 36900.0, 54.26, 38.0,'Elon Musk Twitter catalyst'),

-- Cycle 4 alts (ETF Era)
(4,'BTC','Bitcoin',       15476.00, 126296.00,'2025-10-06',   716.0,  1.00, 56.0,'Baseline — ETF inflows dominant'),
(4,'ETH','Ethereum',        880.00,   4100.00,'2024-12-01',   366.0,  0.51, 56.0,'Underperformed vs history; ETH/BTC ratio fell'),
(4,'SOL','Solana',            8.00,    294.00,'2025-01-19',  3575.0,  4.99, 56.0,'FTX narrative recovery; Meme coin launch pad'),
(4,'BNB','BNB',             210.00,    999.00,'2025-11-01',   376.0,  0.53, 56.0,'Regulatory risk partially resolved'),
(4,'XRP','Ripple',            0.30,      3.40,'2025-01-16',  1033.0,  1.44, 56.0,'SEC case settled; RLUSD launch'),
(4,'DOGE','Dogecoin',         0.07,      0.48,'2024-12-08',   586.0,  0.82, 56.0,'Trump/Musk DOGE government dept catalyst');
