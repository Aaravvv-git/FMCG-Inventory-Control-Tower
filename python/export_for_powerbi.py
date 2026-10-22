import os
import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

url = URL.create("mysql+pymysql", username="root", password=os.environ["MYSQL_PWD"],
                 host="localhost", port=3306, database="fmcg_tower")
engine = create_engine(url)
os.makedirs("powerbi", exist_ok=True)

queries = {
 "kpi_weekly": """SELECT Semana AS week, SUM(Venta_uni_hoy) AS units_sold, SUM(Dev_uni_proxima) AS units_returned,
          ROUND(SUM(Venta_hoy)) AS sales_value, ROUND(SUM(Dev_proxima)) AS return_value
          FROM stg_sales GROUP BY Semana ORDER BY Semana""",
 "depot_channel": """SELECT Agencia_ID AS depot_id, Canal_ID AS channel_id, SUM(Venta_uni_hoy) AS units_sold,
          SUM(Dev_uni_proxima) AS units_returned, ROUND(SUM(Venta_hoy)) AS sales_value,
          ROUND(SUM(Dev_proxima)) AS return_value FROM stg_sales GROUP BY Agencia_ID, Canal_ID""",
 "client_route": """SELECT Agencia_ID AS depot_id, Ruta_SAK AS route_id, Cliente_ID AS client_id,
          SUM(Venta_uni_hoy) AS units_sold, SUM(Dev_uni_proxima) AS units_returned,
          ROUND(SUM(Dev_proxima)) AS return_value FROM stg_sales
          GROUP BY Agencia_ID, Ruta_SAK, Cliente_ID HAVING SUM(Venta_uni_hoy) >= 5000""",
 "sku_segment": "SELECT * FROM sku_segment",
 "exceptions_week9": """SELECT Agencia_ID AS depot_id, Producto_ID AS product_id,
          SUM(delivered) AS delivered_3w, SUM(returned) AS returned_3w,
          ROUND(100 * SUM(returned) / SUM(delivered), 2) AS return_rate_pct,
          ROUND(SUM(return_value)) AS return_value_3w
          FROM depot_sku_weekly WHERE Semana BETWEEN 7 AND 9
          GROUP BY Agencia_ID, Producto_ID
          HAVING SUM(delivered) >= 100 AND SUM(returned) / SUM(delivered) > 0.05
          ORDER BY return_value_3w DESC""",
}
for name, q in queries.items():
    df = pd.read_sql(q, engine)
    df.to_csv(f"powerbi/{name}.csv", index=False)
    print(name, len(df), "rows")
