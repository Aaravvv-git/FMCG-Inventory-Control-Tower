# FMCG Supply Chain Analytics & Inventory Control Tower

**Status: In progress. Phase 1 (Data engineering and Waste diagnostics) is complete. Inventory policy model and Power BI dashboard are next.**

Tools: MySQL, Python (pandas, SQLAlchemy), Power BI, Excel

## Business question
Where does an FMCG distributor lose money to returned (unsold) product, and what should a planner act on this week?

## Data
Public Kaggle dataset: Grupo Bimbo Inventory Demand (weekly sales and returns by depot, channel, route, client, product).
The full file is far too large to load, so I sampled every 20th depot (`Agencia_ID % 20 == 0`), keeping each depot's complete history.

| Item | Value |
|---|---|
| Sample rows | 4,428,031 |
| Weeks | 7 (weeks 3 to 9) |
| Units sold | ~29.96M |
| Units returned | ~449K |
| Overall return rate | ~1.50% |

The raw data is not in this repo (size and Kaggle terms). Download it from Kaggle and run the scripts in `python/`.

## Key findings (all computed from the sample)
1. **Return rate drifted up.** Weekly rate rose from 1.35% (week 5) to 1.63% (week 8).
2. **Waste is concentrated.** 18.5% of products account for 80% of return value.
3. **Two different SKU problems.**
   - Volume-driven: product 2233 has the highest return value (144,680) at only a 1.08% rate. Fix: forecast accuracy.
   - Rate-driven: product 1230 (4.50%) and 972 (3.67%) against a 1.50% average. Fix: allocation and placement.
4. **Channel 5 is the hot spot.** It is 1.65% of units but ~8.0% of returned units. Its return rate is 7.28%, against 1.43% for channel 1 (82% of units). Both channel-5 depots in the sample (1980 and 1560) sit well above average.
5. **Depot 1980 returns 9.31% of units** (about 6x the network average) and has only 5 distinct clients. Route 3005, serving one client (653378), returns 15.91% and accounts for ~33% of the depot's returned units.
6. **That client's returns are volatile while its sales are stable.** Weekly units sold stay between ~5.1K and ~7.5K, but the return rate swings between 7.8% and 27.9%. The top 10 products make up ~62% of the route's return value.

## Illustrative scenario (not an observed result)
If route 3005 returned at the same rate as the best route in its depot (6.54%) instead of 15.91%, returned units would fall by about 4,200, roughly 35K in return value or ~20% of the depot's total return value. This assumes average return value per unit stays constant.

## Recommended actions for a planner (hypotheses to validate)
- Review order allocation for client 653378's top returning SKUs, and track weekly return rate against a threshold.
- Add an exception alert: any large account above ~5% return rate for 3 consecutive weeks.
- Treat channel 5 as a separate review, since it behaves differently from the rest of the network.
- For high-volume, low-rate SKUs like 2233, improve demand forecasting rather than cutting supply.

## Limitations
- Sample of every 20th depot over 7 weeks: findings describe the sample, not the full network.
- No stock-on-hand, lead time, cost or service-level data. These will come from a documented assumptions layer (see `docs/assumptions.md`).
- Some products show returns greater than sales over the window (e.g. 146% on one SKU). Returns are recorded against a following week, so this is likely a timing effect (units delivered before week 3), not a data fault. To be tested.
- Return value is in the source data's currency units.
- Root causes are not proven. Findings show where returns concentrate, not why.

## Roadmap
- [x] Sampling, MySQL load, data checks
- [x] Return-rate diagnostics by week, product, depot, channel, route, client
- [ ] ABC-XYZ segmentation
- [ ] Safety stock and reorder point model with simulated policy comparison
- [ ] Power BI control tower dashboard with exception alerts
- [ ] Stakeholder deck

## How to reproduce
1. Download `train.csv` from the Kaggle competition page.
2. Edit paths in `python/make_sample.py` and run it.
3. Create the table with `sql/01_schema.sql`.
4. Set the environment variable `MYSQL_PWD`, then run `python/load_mysql.py`.
5. Run `sql/02_diagnostics.sql`.
