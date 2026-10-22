##Demand Columns##
USE fmcg_tower;
SELECT COUNT(*) AS rows_,
       SUM(Demanda_uni_equil IS NULL) AS null_demand,
       MIN(Demanda_uni_equil) AS min_d,
       MAX(Demanda_uni_equil) AS max_d,
       SUM(Demanda_uni_equil) AS total_demand,
       SUM(Venta_uni_hoy) AS total_sold
FROM stg_sales;

##SKU Tables##
DROP TABLE IF EXISTS sku_weekly;
CREATE TABLE sku_weekly AS
SELECT Producto_ID, Semana,
       SUM(Demanda_uni_equil) AS demand,
       SUM(Venta_hoy) AS sales_value,
       SUM(Dev_proxima) AS return_value,
       SUM(Venta_uni_hoy) AS units_sold,
       SUM(Dev_uni_proxima) AS units_returned
FROM stg_sales
GROUP BY Producto_ID, Semana;

DROP TABLE IF EXISTS sku_segment;
CREATE TABLE sku_segment AS
WITH s AS (
  SELECT Producto_ID,
         SUM(sales_value) AS sales_value,
         SUM(return_value) AS return_value,
         SUM(units_sold) AS units_sold,
         SUM(units_returned) AS units_returned,
         COUNT(*) AS weeks_present,
         AVG(demand) AS avg_demand,
         STDDEV_POP(demand) AS sd_demand
  FROM sku_weekly GROUP BY Producto_ID
), r AS (
  SELECT s.*,
         SUM(sales_value) OVER (ORDER BY sales_value DESC) / SUM(sales_value) OVER () AS cum_share
  FROM s
)
SELECT Producto_ID, sales_value, return_value, units_sold, units_returned, weeks_present,
       ROUND(avg_demand, 1) AS avg_demand,
       ROUND(sd_demand / NULLIF(avg_demand, 0), 2) AS cv,
       CASE WHEN cum_share <= 0.80 THEN 'A' WHEN cum_share <= 0.95 THEN 'B' ELSE 'C' END AS abc,
       CASE WHEN sd_demand / NULLIF(avg_demand, 0) < 0.5 THEN 'X'
            WHEN sd_demand / NULLIF(avg_demand, 0) < 1.0 THEN 'Y' ELSE 'Z' END AS xyz,
       ROUND(100 * units_returned / NULLIF(units_sold, 0), 2) AS return_rate_pct
FROM r
WHERE weeks_present >= 5;


##SEGMENT SUMMARY##
SELECT CONCAT(abc, xyz) AS segment,
       COUNT(*) AS skus,
       ROUND(SUM(sales_value)) AS sales_value,
       ROUND(SUM(return_value)) AS return_value,
       ROUND(100 * SUM(units_returned) / SUM(units_sold), 2) AS return_rate_pct
FROM sku_segment
GROUP BY abc, xyz
ORDER BY abc, xyz;


##MOVING TO THE DEPOT LEVEL FOR THE INVENTORY MODEL##
USE fmcg_tower;

DROP TABLE IF EXISTS depot_sku_weekly;
CREATE TABLE depot_sku_weekly AS
SELECT w.Agencia_ID, w.Producto_ID, w.Semana,
       SUM(w.Venta_uni_hoy) AS delivered,
       SUM(w.Demanda_uni_equil) AS demand,
       SUM(w.Dev_uni_proxima) AS returned,
       SUM(w.Dev_proxima) AS return_value,
       SUM(w.Venta_hoy) AS sales_value
FROM stg_sales w
JOIN sku_segment s ON s.Producto_ID = w.Producto_ID AND s.abc IN ('A','B')
GROUP BY w.Agencia_ID, w.Producto_ID, w.Semana;

CREATE INDEX ix_dsw ON depot_sku_weekly (Agencia_ID, Producto_ID, Semana);

SELECT COUNT(*) AS rows_,
       COUNT(DISTINCT Agencia_ID, Producto_ID) AS depot_sku_pairs,
       ROUND(COUNT(*) / COUNT(DISTINCT Agencia_ID, Producto_ID), 1) AS avg_weeks_per_pair
FROM depot_sku_weekly;
