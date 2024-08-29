-- Look at what table llooks like and how many segments
 SELECT *
 FROM subscriptions 
 LIMIT 5;

-- Determine range of dates to see which months we can calc churn rate for
SELECT MIN(subscription_start), MAX(subscription_start)
FROM subscriptions;

-- Determine the segments
SELECT DISTINCT(segment)
FROM subscriptions;

--Create temp tables

-- months table will have the 3 months start and end dates that we can calc from with col names first_day and last_day
WITH months AS (
  SELECT 
    '2017-01-01' AS 'first_day',
    '2017-01-31' AS 'last_day'
  UNION
  SELECT 
    '2017-02-01' AS 'first_day',
    '2017-02-28' AS 'last_day'
  UNION
  SELECT 
    '2017-03-01' AS 'first_day',
    '2017-03-30' AS 'last_day'
),
-- crceate temp table called cross_join table that joins subscriptions table and temp months table
cross_join AS (
  SELECT *
  FROM subscriptions
  CROSS JOIN months
),
--create Temp table called status that creates month column and is_active and is_cancelled columns for both 87 and 30 segments
status AS(
  SELECT 
    id,
    first_day AS 'month',
  CASE
  WHEN (
    subscription_start < first_day
    )
  AND (
    segment = 87
  )
  AND (
    subscription_end > first_day
    OR subscription_end IS NULL 
  ) THEN 1
  ELSE 0
  END AS is_active_87,
  CASE
  WHEN (
    subscription_start < first_day
    )
  AND (
    segment = 30
  )
  AND (
    subscription_end > first_day
    OR subscription_end IS NULL 
  ) THEN 1
  ELSE 0
  END AS is_active_30,
  CASE
  WHEN (
    subscription_end BETWEEN first_day AND last_day
  ) 
  AND (
    segment = 87
  )THEN 1
  ELSE 0
  END AS is_cancelled_87,
  CASE
  WHEN (
    subscription_end BETWEEN first_day AND last_day
  ) 
  AND (
    segment = 30
  )THEN 1
  ELSE 0
  END AS is_cancelled_30
  FROM cross_join
),
status_aggregate AS(
  SELECT
    month,
    SUM(is_active_87) AS 'sum_active_87',
    SUM(is_active_30) AS 'sum_active_30',
    SUM(is_cancelled_87) AS 'sum_canceled_87',
    SUM(is_cancelled_30) AS 'sum_canceled_30'
  FROM status
  GROUP BY month
)
--Calc churn rate for 2 segements over 3 months
SELECT 
  month,
  ROUND(1.0 * sum_canceled_87 / sum_active_87, 2) AS 'churn_rate_87',
  ROUND(1.0 * sum_canceled_30 / sum_active_30, 2) AS 'churn_rate_30'
FROM status_aggregate;
