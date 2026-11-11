-- La table source contient plusieurs lignes par adresse : on garde la plus recente.
with ranked as (

    select
        address as token_address,
        symbol,
        name as token_name,
        safe_cast(decimals as int64) as decimals,
        row_number() over (
            partition by address
            order by block_number desc
        ) as row_num
    from {{ source('eth_raw', 'tokens') }}

)

select
    token_address,
    symbol,
    token_name,
    decimals
from ranked
where row_num = 1
