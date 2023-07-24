{{
    config(
        materialized = 'view'
    )
}}
WITH src_hosts AS (
    SELECT * FROM {{ ref('src_hosts') }}
)

SELECT
    host_id,
    IFNULL(host_name, "Anonymous") as host_name,
    IFNULL(is_superhost, FALSE) as is_superhost,
    created_at,
    updated_at
FROM src_hosts

