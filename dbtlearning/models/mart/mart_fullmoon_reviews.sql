{{
    config(
        materialized = 'table'
    )
}}

WITH
    fct_reviews AS (
        SELECT * FROM {{ ref('fct_reviews') }}
    ),
    full_moon_dates AS (
        SELECT * FROM {{ ref('seed_full_moon_dates') }}
    )

SELECT
    fr.*,
    CASE
        WHEN fmd.full_moon_date IS NULL THEN 'not full moon'
        ELSE 'full_moon'
    END AS is_full_moon
FROM
    fct_reviews fr
LEFT JOIN
    full_moon_dates fmd
    ON DATE(fr.review_date) = DATE_ADD(fmd.full_moon_date, INTERVAL 1 DAY)
