with league as (
    select * from {{ ref('example__league') }}
),

league_code as (
-- here we are using the csv file in seeds folder leagues_code
    select * from {{ ref('leagues_code')}}
),

final as (
    select
        league.name,
        league_code.code
    from league
    left join league_code
        USING(name)
)

select * from final