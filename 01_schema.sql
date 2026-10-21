CREATE DATABASE IF NOT EXISTS fmcg_tower;
USE fmcg_tower;

CREATE TABLE stg_sales (
  Semana TINYINT,
  Agencia_ID SMALLINT,
  Canal_ID TINYINT,
  Ruta_SAK SMALLINT,
  Cliente_ID INT,
  Producto_ID INT,
  Venta_uni_hoy INT,
  Venta_hoy DECIMAL(12,2),
  Dev_uni_proxima INT,
  Dev_proxima DECIMAL(12,2),
  Demanda_uni_equil INT
);

-- Create after loading
CREATE INDEX ix_client_prod ON stg_sales (Cliente_ID, Producto_ID, Semana);
CREATE INDEX ix_agency ON stg_sales (Agencia_ID);
