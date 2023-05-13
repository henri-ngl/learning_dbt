with source_company as (
    select * from {{ source('backoffice_db', 'company') }}
),

final as (
    select * from source_company
)

select * from final