{% macro insert_logic(action_name) -%}

INSERT INTO staging.dbt_audit (audit_type)
VALUES('{{ action_name }}')

{%- endmacro %}