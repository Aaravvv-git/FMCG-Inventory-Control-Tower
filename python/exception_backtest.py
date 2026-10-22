"""Backtest 2: cap next delivery only where trailing 3-week return rate exceeds a trigger."""
import os
import numpy as np
import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

url = URL.create("mysql+pymysql", username="root", password=os.environ["MYSQL_PWD"],
                 host="localhost", port=3306, database="fmcg_tower")
engine = create_engine(url)

df = pd.read_sql("""SELECT Agencia_ID, Producto_ID, Semana, delivered, demand,
                           returned, sales_value FROM depot_sku_weekly""", engine)
for c in ["delivered", "demand", "returned", "sales_value"]:
    df[c] = pd.to_numeric(df[c], errors="coerce").astype(float)

df = df.sort_values(["Agencia_ID", "Producto_ID", "Semana"])
g = df.groupby(["Agencia_ID", "Producto_ID"])
df["fc"] = g["demand"].transform(lambda s: s.shift(1).rolling(4, min_periods=3).mean())
df["sd"] = g["demand"].transform(lambda s: s.shift(1).rolling(4, min_periods=3).std())
df["ret_hist"] = g["returned"].transform(lambda s: s.shift(1).rolling(3, min_periods=2).sum())
df["del_hist"] = g["delivered"].transform(lambda s: s.shift(1).rolling(3, min_periods=2).sum())
df = df.dropna(subset=["fc", "sd", "ret_hist", "del_hist"]).copy()
df["hist_rate"] = df["ret_hist"] / df["del_hist"].replace(0, np.nan)
df["price"] = (df["sales_value"] / df["delivered"].replace(0, np.nan)).fillna(0)

total_returns = df["returned"].sum()
rows = []
for thr in [0.03, 0.05, 0.10]:
    for z in [1.28, 1.65]:
        f = df[(df["hist_rate"] > thr) & (df["del_hist"] >= 100)]
        cap = np.ceil(f["fc"] + z * f["sd"])
        removed = np.maximum(f["delivered"] - cap, 0)
        avoided = np.minimum(removed, f["returned"])   # removed units that would have been returned
        lost = removed - avoided                        # removed units that would have sold
        row = {"trigger_rate": thr, "z": z, "flagged_rows": len(f),
               "flagged_share_of_returns_pct": round(100 * f["returned"].sum() / total_returns, 1),
               "returns_avoided_units": round(avoided.sum()),
               "avoided_pct_of_all_returns": round(100 * avoided.sum() / total_returns, 1),
               "lost_sales_units": round(lost.sum()),
               "lost_pct_of_flagged_sales": round(100 * lost.sum() / max((f["delivered"] - f["returned"]).sum(), 1), 2)}
        for cogs in (0.5, 0.7, 0.85):   # ASSUMPTION: cost of goods as share of price
            net = (avoided * f["price"] * cogs).sum() - (lost * f["price"] * (1 - cogs)).sum()
            row[f"net_value_cogs{int(cogs * 100)}"] = round(net)
        rows.append(row)
res = pd.DataFrame(rows)
print(res.to_string(index=False))
os.makedirs("results", exist_ok=True)
res.to_csv("results/exception_backtest.csv", index=False)
