{% test not_null(model, column_name) %}

{% set column_list = '*' if should_store_failures() else column_name %}

select {{ column_list }}
from {{ model }}
where {{ column_name }} is null
-- we can add all the condition that we want and it will just overide the default__test_not_null test
    and x y z

{% endtest %}