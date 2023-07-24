{% snapshot scd_raw_listings %}

{{
    config(
        target_schema='dbtlearn',
        unique_key='id',
        strategy='timestamp',
        updated_at='updated_at',
        invalidate_hard_deletes=True
    )
}}

SELECT * FROM {{ source('dbtlearning', 'listings') }}

{% endsnapshot %}