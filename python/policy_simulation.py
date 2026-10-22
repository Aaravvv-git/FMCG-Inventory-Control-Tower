"""Backtest 1: replace actual replenishment with forecast + safety stock. Result: it loses (see README)."""
import os
import numpy as np
import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

url = URL.create("mysql+pymysql", username="root", password=os.environ["MYSQL_PWD"],
                 host="localhost", port=3306, database="fmcg_tower")
engine = create_engine(url)

df = pd.read_sql("""SELECT d.Agencia_ID, d.Producto_ID, d.Semana, d.delivered, d.demand,
                           d.returned, d.sales_value, s.abc
                    FROM depot_sku_weekly d JOIN sku_segment s ON s.Producto_ID = d.Producto_ID""", engine)
for c in ["delivered", "demand", "returned", "sales_value"]:
    df[c] = pd.to_numeric(df[c], errors="coerce").astype(float)

LEAD_WEEKS = 1            # assumption: weekly review, one-week lead time
WINDOW, MIN_HIST = 4, 3

df = df.sort_values(["Agencia_ID", "Producto_ID", "Semana"])
grp = df.groupby(["Agencia_ID", "Producto_ID"])["demand"]
df["fc"] = grp.transform(lambda s: s.shift(1).rolling(WINDOW, min_periods=MIN_HIST).mean())
df["sd"] = grp.transform(lambda s: s.shift(1).rolling(WINDOW, min_periods=MIN_HIST).std())
g = df.dropna(subset=["fc", "sd"]).copy()
g["price"] = (g["sales_value"] / g["delivered"].replace(0, np.nan)).fillna(0)

Z = {0.50: 0.00, 0.80: 0.84, 0.90: 1.28, 0.95: 1.65, 0.98: 2.05}
rows = []
for sl, z in Z.items():
    order = np.ceil(g["fc"] + z * g["sd"] * np.sqrt(LEAD_WEEKS))
    sim_ret = np.maximum(order - g["demand"], 0)
    short = np.maximum(g["demand"] - order, 0)
    rows.append({"target_service_level": sl, "rows_tested": len(g),
                 "actual_returns_units": g["returned"].sum(), "sim_returns_units": sim_ret.sum(),
                 "returns_change_pct": round(100 * (sim_ret.sum() / g["returned"].sum() - 1), 1),
                 "actual_returns_value": round((g["returned"] * g["price"]).sum()),
                 "sim_returns_value": round((sim_ret * g["price"]).sum()),
                 "fill_rate_pct": round(100 * (1 - short.sum() / g["demand"].sum()), 1),
                 "actual_delivered": g["delivered"].sum(), "sim_delivered": order.sum()})
res = pd.DataFrame(rows)
print(res.to_string(index=False))
os.makedirs("results", exist_ok=True)
res.to_csv("results/policy_simulation.csv", index=False)
