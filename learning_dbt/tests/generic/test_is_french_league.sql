{% test is_french_league(model, column_name) %}

with validation as (

    select
        {{ column_name }} as league_code,
        name

    from {{ model }}

),

validation_errors as (

    select
        name,
        league_code

    from validation
    -- if this is true, then even_field is actually odd!
    where league_code like 'FRA-%'
        and name not like 'French%'

)

-- select count(*)
select *
from validation_errors

{% endtest %}