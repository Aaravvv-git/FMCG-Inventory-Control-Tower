USE fmcg_tower;

-- 1. Load check
SELECT COUNT(*) AS total_rows FROM stg_sales;

-- 2. Weekly return rate
SELECT Semana, COUNT(*) AS row_count, SUM(Venta_uni_hoy) AS units_sold,
       SUM(Dev_uni_proxima) AS units_returned,
       ROUND(100 * SUM(Dev_uni_proxima) / SUM(Venta_uni_hoy), 2) AS return_rate_pct
FROM stg_sales GROUP BY Semana ORDER BY Semana;

-- 3. Top products by return value
SELECT Producto_ID, SUM(Venta_uni_hoy) AS units_sold, SUM(Dev_uni_proxima) AS units_returned,
       ROUND(100 * SUM(Dev_uni_proxima) / SUM(Venta_uni_hoy), 2) AS return_rate_pct,
       ROUND(SUM(Dev_proxima), 0) AS return_value
FROM stg_sales GROUP BY Producto_ID
HAVING SUM(Venta_uni_hoy) >= 5000
ORDER BY return_value DESC LIMIT 20;

-- 4. Top depots by return value
SELECT Agencia_ID, SUM(Venta_uni_hoy) AS units_sold, SUM(Dev_uni_proxima) AS units_returned,
       ROUND(100 * SUM(Dev_uni_proxima) / SUM(Venta_uni_hoy), 2) AS return_rate_pct,
       ROUND(SUM(Dev_proxima), 0) AS return_value
FROM stg_sales GROUP BY Agencia_ID
HAVING SUM(Venta_uni_hoy) >= 20000
ORDER BY return_value DESC LIMIT 20;

-- 5. Concentration: share of products driving 80% of return value (MySQL 8+)
WITH p AS (
  SELECT Producto_ID, SUM(Dev_proxima) AS rv FROM stg_sales GROUP BY Producto_ID
), r AS (
  SELECT rv, SUM(rv) OVER (ORDER BY rv DESC) AS cum, SUM(rv) OVER () AS tot,
         ROW_NUMBER() OVER (ORDER BY rv DESC) AS rn, COUNT(*) OVER () AS n
  FROM p
)
SELECT ROUND(100 * MIN(CASE WHEN cum / tot >= 0.8 THEN rn END) / MAX(n), 1)
       AS pct_of_products_driving_80pct_of_return_value
FROM r;

-- 6. Drill-down: depot 1980 by route
SELECT Ruta_SAK, COUNT(DISTINCT Cliente_ID) AS clients, SUM(Venta_uni_hoy) AS units_sold,
       SUM(Dev_uni_proxima) AS units_returned,
       ROUND(100 * SUM(Dev_uni_proxima) / SUM(Venta_uni_hoy), 2) AS return_rate_pct,
       ROUND(SUM(Dev_proxima), 0) AS return_value
FROM stg_sales WHERE Agencia_ID = 1980
GROUP BY Ruta_SAK ORDER BY return_value DESC;

-- 7. Channel comparison, network-wide
SELECT Canal_ID, COUNT(DISTINCT Agencia_ID) AS depots, SUM(Venta_uni_hoy) AS units_sold,
       SUM(Dev_uni_proxima) AS units_returned,
       ROUND(100 * SUM(Dev_uni_proxima) / SUM(Venta_uni_hoy), 2) AS return_rate_pct
FROM stg_sales GROUP BY Canal_ID ORDER BY units_sold DESC;

-- 8. Route 3005 weekly pattern
SELECT Semana, Cliente_ID, SUM(Venta_uni_hoy) AS units_sold, SUM(Dev_uni_proxima) AS units_returned,
       ROUND(100 * SUM(Dev_uni_proxima) / SUM(Venta_uni_hoy), 2) AS return_rate_pct
FROM stg_sales WHERE Agencia_ID = 1980 AND Ruta_SAK = 3005
GROUP BY Semana, Cliente_ID ORDER BY Semana;

-- 9. Route 3005 top products by return value
SELECT Producto_ID, SUM(Venta_uni_hoy) AS units_sold, SUM(Dev_uni_proxima) AS units_returned,
       ROUND(100 * SUM(Dev_uni_proxima) / SUM(Venta_uni_hoy), 2) AS return_rate_pct,
       ROUND(SUM(Dev_proxima), 0) AS return_value
FROM stg_sales WHERE Agencia_ID = 1980 AND Ruta_SAK = 3005
GROUP BY Producto_ID ORDER BY return_value DESC LIMIT 10;
