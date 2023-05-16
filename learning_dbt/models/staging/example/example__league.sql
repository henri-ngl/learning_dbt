with source_league as (
    select * from {{ source('backoffice_db', 'league') }}
),

final as (
    select * from source_league
)

select *, '{{ invocation_id }}' as invocation_id from final