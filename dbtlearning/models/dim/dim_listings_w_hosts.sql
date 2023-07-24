WITH
    dlc AS (
        SELECT * FROM {{ ref('dim_listings_cleansed') }}
    ),
    dhc AS (
        SELECT * FROM {{ ref('dim_hosts_cleansed') }}
    )

SELECT
    dlc.listing_id,
    dlc.listing_name,
    dlc.room_type,
    dlc.minimum_nights,
    dlc.price,
    dlc.host_id,
    dhc.host_name,
    dhc.is_superhost as host_is_superhost,
    dlc.created_at,
    GREATEST(dlc.updated_at, dhc.updated_at) AS updated_at
FROM dlc
LEFT JOIN dhc ON dhc.host_id = dlc.host_id
