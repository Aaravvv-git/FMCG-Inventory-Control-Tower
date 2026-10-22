USE fmcg_tower;
-- Depot x SKU x week table for A and B class SKUs (input to the Python backtests)
DROP TABLE IF EXISTS depot_sku_weekly;
CREATE TABLE depot_sku_weekly AS
SELECT w.Agencia_ID, w.Producto_ID, w.Semana,
       SUM(w.Venta_uni_hoy) AS delivered, SUM(w.Demanda_uni_equil) AS demand,
       SUM(w.Dev_uni_proxima) AS returned, SUM(w.Dev_proxima) AS return_value,
       SUM(w.Venta_hoy) AS sales_value
FROM stg_sales w
JOIN sku_segment s ON s.Producto_ID = w.Producto_ID AND s.abc IN ('A','B')
GROUP BY w.Agencia_ID, w.Producto_ID, w.Semana;
CREATE INDEX ix_dsw ON depot_sku_weekly (Agencia_ID, Producto_ID, Semana);
