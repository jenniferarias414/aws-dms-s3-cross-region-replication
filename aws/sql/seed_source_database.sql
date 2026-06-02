-- Seed source MySQL database for AWS DMS CDC replication lab.
--
-- This script creates a simple retail database with customers, products,
-- and orders. AWS DMS will later read changes from this RDS MySQL source
-- and move them toward S3.

-- Confirm key binary log / CDC-related settings.
-- For MySQL CDC with AWS DMS, binary logging should be enabled and
-- binlog_format should be ROW.
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'binlog_format';
SHOW VARIABLES LIKE 'binlog_row_image';

-- Keep binary logs long enough for DMS CDC testing.
-- This is useful for RDS MySQL sources.
CALL mysql.rds_set_configuration('binlog retention hours', 24);

-- Create and use the source database.
CREATE DATABASE IF NOT EXISTS retail;

USE retail;

-- Drop tables if rerunning the lab seed script.
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
  customer_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  email       VARCHAR(200),
  first_name  VARCHAR(100),
  last_name   VARCHAR(100),
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE products (
  product_id  BIGINT PRIMARY KEY AUTO_INCREMENT,
  name        VARCHAR(200),
  category    VARCHAR(100),
  price       DECIMAL(10,2),
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
  order_id    BIGINT PRIMARY KEY AUTO_INCREMENT,
  customer_id BIGINT,
  status      VARCHAR(30),
  total       DECIMAL(10,2),
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO customers (email, first_name, last_name) VALUES
 ('alice@test.com','Alice','Smith'),
 ('bob@test.com','Bob','Johnson');

INSERT INTO products (name, category, price) VALUES
 ('Laptop','Electronics',1200),
 ('Phone','Electronics',700);

INSERT INTO orders (customer_id, status, total) VALUES
 (1, 'NEW', 1200),
 (2, 'NEW', 700);

-- Validation queries.
SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM orders;

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'products' AS table_name, COUNT(*) AS row_count FROM products
UNION ALL
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM orders;