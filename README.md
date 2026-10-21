# FMCG Supply Chain Analytics & Inventory Control Tower

**Status: in progress.** Data engineering, waste diagnostics, ABC-XYZ segmentation and two policy backtests are complete. The Power BI dashboard and stakeholder deck are in progress.

Tools: MySQL, Python (pandas, SQLAlchemy), Power BI, Excel (planned)

## Business question
Where does an FMCG distributor lose money to returned (unsold) product, and what should a planner review this week?

## Data
Public Kaggle dataset: Grupo Bimbo Inventory Demand (weekly sales and returns by depot, channel, route, client, product). I sampled every 20th depot (`Agencia_ID % 20 == 0`), keeping each depot's full history.

| Item | Value |
|---|---|
| Sample rows | 4,428,031 |
| Weeks | 7 (weeks 3 to 9) |
| Units sold / returned | ~29.96M / ~449K (1.50%) |
| SKUs segmented (present in >= 5 weeks) | 679 |

The raw data is not in this repo (size and Kaggle terms). See "How to reproduce".

## Findings
**Where the waste is**
1. The weekly return rate rose from 1.35% (week 5) to 1.63% (week 8).
2. 18.5% of products account for 80% of return value.
3. ABC-XYZ: A-class SKUs are 19% of SKUs and 80% of sales value but 67% of return value. The stable, high-volume AX segment (117 SKUs, 1.18% return rate) alone holds ~64% of return value. This is volume-driven waste.
4. Return rate rises as value falls and demand gets less stable: AX 1.18%, BX 2.11%, CX 3.49%, CY 10.22%, CZ 19.57%. The 90 CY/CZ SKUs are ~0.5% of sales value; they are range-review candidates.
5. Channel 5 is 1.65% of units but ~8% of returned units (7.28% return rate vs 1.43% for channel 1, which is 82% of units).
6. Depot 1980 (channel 5) returns 9.31% of units and has 5 distinct clients. One client route (route 3005, client 653378) returns 15.91% and accounts for ~33% of the depot's returned units. Its weekly sales are steady (~5.1K to 7.5K units) while its return rate swings from 7.8% to 27.9%. Its top 10 products make up ~62% of the route's return value.

**What did not work (two backtests)**
7. *Replacing replenishment with a 4-week forecast + safety stock* (`python/policy_simulation.py`) on 8,182 depot-SKU-weeks: simulated returns were 8x to 28x actual returns across service levels of 50% to 98%. Actual returns are only 1.5% of delivered units, so the existing process is much more accurate than a moving average. Fill rate is measured against recorded demand, which can never exceed deliveries, so it is optimistic.
8. *Capping deliveries only where the trailing 3-week return rate is high* (`python/exception_backtest.py`): the flag is informative (3% trigger: 22% of rows hold 37% of returns), but cutting stock loses 3.7 to 5.9 sales for every return avoided. Net value is negative at 50% and 70% cost of goods, and positive only at 85%.

**Design conclusion:** the control tower is an exception-alert and prioritisation tool for planner review, not an automatic order-reduction engine.

## Recommended planner actions (hypotheses to validate)
- Review client 653378's top returning SKUs and the channel-5 depots first.
- Weekly exception list: depot-SKUs above a 5% trailing return rate with at least 100 units (326 in week 9, A/B SKUs only).
- For AX SKUs, work on forecast accuracy and order sizing, not on cutting supply.
- Review CY/CZ SKUs for minimum order sizes, make-to-order or delisting.

## Limitations
- Sample of every 20th depot over 7 weeks: findings describe the sample, not the full network.
- No stock-on-hand, lead time, cost or service data. See `docs/assumptions.md`; cost of goods is an assumption shown as a sensitivity.
- Some SKUs show returns above sales over the window (e.g. 146% on one SKU). Returns are recorded against a following week, so this is likely a timing effect; not yet tested.
- Z-class SKUs are rare at network level (26 SKUs) because summing demand across depots smooths variability.
- Findings show where returns concentrate, not why.
- Earlier drafts contained a "~20% return value reduction" scenario for route 3005. It ignored lost sales and is withdrawn: backtest 8 shows most removed units would have sold.

## Roadmap
- [x] Sampling, MySQL load, data checks
- [x] Return-rate diagnostics by week, product, depot, channel, route, client
- [x] ABC-XYZ segmentation
- [x] Policy backtests (two negative results)
- [ ] Power BI control tower (overview, ABC-XYZ matrix, exceptions, concentration)
- [ ] Excel planner view and reconciliation to SQL totals
- [ ] Stakeholder deck

## How to reproduce
1. Download `train.csv` from the Kaggle competition page; edit paths in `python/make_sample.py` and run it.
2. Run `sql/01_schema.sql`, load with `python/load_mysql.py` (set env var `MYSQL_PWD`), then `sql/02_indexes.sql`.
3. Run `sql/03_diagnostics.sql`, `sql/04_abc_xyz.sql`, `sql/05_depot_sku.sql` in order.
4. Run `python/policy_simulation.py`, `python/exception_backtest.py`, `python/export_for_powerbi.py`.
