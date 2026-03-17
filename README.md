# ₿ Bitcoin Four-Year Cycle Analysis
### A Data-Driven Portfolio Project · All 4 Halvings · 2012–Present

[![Bitcoin](https://img.shields.io/badge/Asset-Bitcoin-F7931A?style=flat&logo=bitcoin&logoColor=white)](https://bitcoin.org)
[![Cycles](https://img.shields.io/badge/Cycles_Analyzed-4-0F3460?style=flat)](/)
[![Status](https://img.shields.io/badge/Cycle_4_ATH-$126,296-10B981?style=flat)](/)
[![SQL](https://img.shields.io/badge/SQL-PostgreSQL_14+-336791?style=flat&logo=postgresql&logoColor=white)](/)

---

## 📌 Project Overview

This project is a comprehensive, data-driven analysis of Bitcoin's **four-year halving cycle** — the single most reliable macro framework in crypto markets. Using historical data from all four halving cycles (2012–present), I built a full analytical stack: a structured database, SQL query library, Excel workbook, and an interactive dashboard.

> **Core thesis:** The four-year cycle is not dead. It is maturing. Cycle 4 confirmed the timing pattern (ATH at 534 days post-halving), confirmed diminishing returns, while introducing new ETF-era dynamics that are changing the *shape* of cycles without breaking the underlying structure.

---

## 📁 Project Structure

```
btc-four-year-cycle/
│
├── README.md
│
├── dashboard/
│   └── btc_4year_cycle_dashboard.html     ← Interactive 6-tab HTML dashboard
│
├── data/
│   └── btc_4year_cycle_analysis.xlsx      ← Excel workbook (7 sheets)
│
└── sql/
    ├── 01_schema_and_seed.sql             ← Database schema + all seed data
    ├── 02_halving_price_impact.sql        ← Post-halving return analysis
    ├── 03_peaks_and_drawdowns.sql         ← Bear market & drawdown analysis
    ├── 04_phase_duration_analysis.sql     ← Bull/bear timing & duration
    └── 05_altcoin_correlation.sql         ← Altcoin vs BTC rotation analysis
```

---

## 🗄️ Database Schema

The SQL layer is built on **5 relational tables** in PostgreSQL:

| Table | Rows | Description |
|---|---|---|
| `btc_cycles` | 4 | One row per halving cycle — ATH, bottom, drawdown, returns |
| `halving_events` | 5 | Detailed halving data including supply metrics and post-halving prices |
| `cycle_phases` | 18 | Granular phase breakdown (accumulation, bull, bear, recovery, correction) |
| `btc_monthly_prices` | 36 | Key monthly price snapshots across all 4 cycles |
| `altcoin_performance` | 17 | ETH, SOL, BNB, XRP, DOGE vs BTC per cycle |

---

## 📊 Excel Workbook — 7 Sheets

| Sheet | Contents |
|---|---|
| **KPI Dashboard** | At-a-glance KPI cards, halving summary, cycle stat comparison |
| **Cycle Phases** | All 18 phases across 4 cycles with color-coded phase types |
| **Halving Price Impact** | Price at halving + 30/180/365d after + diminishing returns note |
| **Peaks & Bottoms** | ATH dates, bear bottoms, max drawdowns, projected Cycle 4 bottom range |
| **Altcoin Correlation** | Alt performance vs BTC — Cycles 2, 3, 4 + BTC dominance rotation table |
| **Monthly Price Data** | 36 key price snapshots with phase labels, filterable |
| **Cycle 4 — Current Status** | Live cycle status cards + "Is the cycle dead?" evidence table |

---

## 🌐 Interactive Dashboard — 6 Tabs

| Tab | Charts & Data |
|---|---|
| **Overview** | KPI cards, post-halving returns bar chart, drawdown bar, days-to-ATH bar, post-halving indexed performance line |
| **Halvings** | Full halving table, post-halving 365-day indexed performance chart |
| **Cycle Phases** | Bull/bear duration bars, full annotated cycle timeline |
| **Peaks & Drawdowns** | ATH/bottom table, drawdown severity trend line, Cycle 4 bear projection chart |
| **Altcoin Rotation** | BTC dominance line chart, Cycle 3 alt table, Cycle 4 alt table, rotation insights |
| **Cycle 4 Now** | Current status KPIs, "Is the cycle dead?" evidence review table |

---

## 🔍 SQL Query Library — 5 Files / 20 Queries

### `01_schema_and_seed.sql`
Complete database setup — run this first to create all tables and load all data.

### `02_halving_price_impact.sql`
- Post-halving returns at 30/180/365 days after each halving
- Diminishing returns decay calculation with Cycle 5 projection
- Supply shock analysis — new BTC per day and annual USD value of issuance
- Time-to-ATH consistency window check

### `03_peaks_and_drawdowns.sql`
- Full cycle summary: peak → bottom → recovery stats
- Drawdown severity trend with cycle-over-cycle improvement
- **Cycle 4 bear projection** — 6 scenarios from −50% to −85%
- Phase duration statistics with averages by phase type

### `04_phase_duration_analysis.sql`
- Full phase timeline for all cycles
- Bull market stats: avg daily/monthly gain rate per cycle
- Bear market stats: avg monthly decline rate per cycle
- **Bull vs bear asymmetry** — % of time spent in uptrend vs downtrend
- Four-year cycle calendar with Cycle 5 projection

### `05_altcoin_correlation.sql`
- All altcoins vs BTC across cycles with performance verdict
- Best/worst alt per cycle with rankings
- Cross-cycle tracker (ETH, BNB, DOGE performance across multiple cycles)
- BTC dominance at cycle peaks + % of alts that beat BTC
- **Capital rotation model** — did each alt peak before or after BTC ATH?
- Cycle 4 ETF-era special analysis: what changed vs Cycle 3

---

## 📈 Key Findings

### The Cycle Holds — Key Stats

| | Cycle 1 | Cycle 2 | Cycle 3 | Cycle 4 |
|---|---|---|---|---|
| **Halving Date** | Nov 28, 2012 | Jul 9, 2016 | May 11, 2020 | Apr 20, 2024 |
| **Price at Halving** | $12.35 | $650.63 | $8,821 | $63,850 |
| **Cycle ATH** | $1,150 | $19,891 | $68,789 | $126,296 |
| **Days to ATH** | 367 | 525 | 546 | **534** ✓ |
| **Bull Return** | +9,213% | +2,960% | +680% | +98% |
| **Bear Drawdown** | −85.2% | −84.3% | −77.5% | −46.7%* |
| **Bear Duration** | 409 days | 363 days | 376 days | Ongoing |

*Cycle 4 bear ongoing as of March 2026

### The Cycle Is Evolving — ETF-Era Changes
- **Pre-halving ATH**: Cycle 4 broke all-time high in March 2024 — *before* the April halving. Never happened in prior cycles. Caused by ETF approval in January 2024.
- **Higher BTC dominance floor**: In 2021 dominance crashed to 38%. In Cycle 4 the floor was ~55%. Institutional ETF holders don't rotate into alts.
- **Diminishing returns**: +9,213% → +2,960% → +680% → +98%. Returns shrink each cycle as supply shock weakens. Cycle 5 estimated +30%–60%.
- **ETH underperformed** for the first time — SOL and XRP took its historical role.

### Bear Market Projection (Cycle 4)
If $126,296 (Oct 2025) was the cycle ATH, historical patterns imply a bottom of:
- **Conservative (ETF floor):** ~$63,000 (−50%)
- **Moderate:** ~$44,000 (−65%)
- **Historical avg:** ~$38,000 (−70%)
- **Extreme:** ~$30,000 (−76%)

---

## 🛠️ How to Run the SQL

```sql
-- Step 1: Create the database
CREATE DATABASE btc_cycle_analysis;

-- Step 2: Run files in order
\i sql/01_schema_and_seed.sql
\i sql/02_halving_price_impact.sql
\i sql/03_peaks_and_drawdowns.sql
\i sql/04_phase_duration_analysis.sql
\i sql/05_altcoin_correlation.sql
```

**Compatibility:** Written for PostgreSQL 14+. The `GENERATED ALWAYS AS ... STORED` column in `cycle_phases` requires PG 12+. For MySQL, replace with a regular column and trigger. For SQLite, remove the generated column and compute `duration_days` in queries.

---

## 📋 Data Sources & Methodology

| Source | Used For |
|---|---|
| CoinMarketCap / CoinGecko | Historical BTC and altcoin prices |
| HLTV / Blockchain.com | Halving block heights and dates |
| TradingView | Monthly OHLC data |
| Glassnode (public) | BTC dominance metrics |
| Messari | Cycle phase categorisation |

**Methodology notes:**
- "Cycle" defined as halving date → next halving date
- ATH defined as highest close price in each cycle (not intraday)
- Bear bottom defined as lowest close price post-ATH before recovery
- Altcoin cycle low = lowest price after prior cycle's ATH (entry point)
- All prices in USD

---

## ⚠️ Disclaimer

This project is for **educational and portfolio purposes only**. Nothing here constitutes financial advice. Bitcoin markets are highly volatile and past cycle behaviour does not guarantee future results. Always do your own research.

---

## 👤 Author

**Serban Sergiu**
Data Analyst | Crypto Market Research
[LinkedIn]www.linkedin.com/in/sergiu-serban-48043313b · [GitHub]https://github.com/serbansergiu-crypto

---

*Last updated: March 2026 · Data current through February 2026*
