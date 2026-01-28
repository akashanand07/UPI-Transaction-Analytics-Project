CREATE DATABASE upi_analysis;
USE upi_analysis;
 CREATE TABLE upi_monthly_stats(
 month VARCHAR(10),
 banks_cnt INT,
 txn_vol_mn DOUBLE,
 txn_val_cr DOUBLE,
 avg_txn_val_inr DOUBLE
 );
SHOW TABLES;
 SELECT COUNT(*) FROM upi_monthly_stats;
 SELECT month
 FROM upi_monthly_stats
 ORDER BY STR_TO_DATE(month,'%b-%y'); 
 SELECT month,
 txn_vol_mn
 FROM upi_monthly_stats
 ORDER BY txn_vol_mn DESC
 LIMIT 1;
 SELECT month,
 txn_val_cr
 FROM upi_monthly_stats
 ORDER BY txn_val_cr DESC
 LIMIT 1;
 
SELECT month,
txn_vol_mn,
LAG(txn_vol_mn)
OVER (ORDER BY STR_TO_DATE(month,'%b-%y')) AS 
prev_month FROM  upi_monthly_stats;

SELECT
    month,
    txn_val_cr,
    ROUND(
        (txn_val_cr - LAG(txn_val_cr)
            OVER (ORDER BY STR_TO_DATE(month, '%b-%y')))
        / LAG(txn_val_cr)
            OVER (ORDER BY STR_TO_DATE(month, '%b-%y')) * 100,
    2) AS mom_growth_percent
FROM upi_monthly_stats;

SELECT
    month,
    txn_val_cr,
    ROUND(
        AVG(txn_val_cr)
            OVER (
                ORDER BY STR_TO_DATE(month, '%b-%y')
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ),
    2) AS moving_avg_3_month
FROM upi_monthly_stats;
CREATE TABLE upi_yearly_summary (
    financial_year VARCHAR(10),
    upi_txn_volume_mn DOUBLE,
    upi_txn_value_cr DOUBLE
);
INSERT INTO upi_yearly_summary
(financial_year, upi_txn_volume_mn, upi_txn_value_cr)
SELECT
    CONCAT('FY-', year_part) AS financial_year,
    SUM(txn_vol_mn) AS upi_txn_volume_mn,
    SUM(txn_val_cr) AS upi_txn_value_cr
FROM (
    SELECT
        SUBSTRING_INDEX(month, '-', -1) AS year_part,
        txn_vol_mn,
        txn_val_cr
    FROM upi_monthly_stats
) t
GROUP BY year_part
ORDER BY year_part;
SELECT
    financial_year,
    ROUND(
        (
            upi_txn_value_cr
            - LAG(upi_txn_value_cr)
              OVER (ORDER BY CAST(SUBSTRING(financial_year, 4) AS UNSIGNED))
        )
        /
        LAG(upi_txn_value_cr)
          OVER (ORDER BY CAST(SUBSTRING(financial_year, 4) AS UNSIGNED))
        * 100
    , 2) AS yoy_growth_percent
FROM upi_yearly_summary;
SELECT COUNT(*) FROM upi_yearly_summary; 
SELECT MIN(month),MAX(month)
FROM upi_monthly_stats;
SELECT
  COUNT(*) AS total_rows,
  SUM(month IS NULL) AS null_months,
  SUM(txn_vol_mn IS NULL) AS null_volume
FROM upi_monthly_stats;
CREATE OR REPLACE VIEW vw_upi_monthly_base AS
SELECT
    month,
    banks_cnt,
    txn_vol_mn,
    txn_val_cr,
    avg_txn_val_inr
FROM upi_monthly_stats;
CREATE OR REPLACE VIEW vw_upi_mom_growth AS
SELECT
    month,
    txn_val_cr,
    ROUND(
        (
            txn_val_cr
            - LAG(txn_val_cr)
              OVER (ORDER BY STR_TO_DATE(month, '%b-%y'))
        )
        /
        LAG(txn_val_cr)
          OVER (ORDER BY STR_TO_DATE(month, '%b-%y'))
        * 100,
    2) AS mom_growth_percent
FROM upi_monthly_stats;
CREATE OR REPLACE VIEW vw_upi_yoy_growth AS
SELECT
    financial_year,
    upi_txn_value_cr,
    ROUND(
        (
            upi_txn_value_cr
            - LAG(upi_txn_value_cr)
              OVER (ORDER BY CAST(SUBSTRING(financial_year, 4) AS UNSIGNED))
        )
        /
        LAG(upi_txn_value_cr)
          OVER (ORDER BY CAST(SUBSTRING(financial_year, 4) AS UNSIGNED))
        * 100,
    2) AS yoy_growth_percent
FROM upi_yearly_summary;
SELECT * FROM vw_upi_mom_growth;
SELECT * FROM vw_upi_yoy_growth;