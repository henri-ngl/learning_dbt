with source_league as (
    select * from {{ source('backoffice_db', 'league') }}
),

final as (
    select * from source_league
)

select * from final