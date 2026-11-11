with activity as (

    select
        token_address,
        min(block_date) as first_transfer_date,
        max(block_date) as last_transfer_date,
        count(*) as active_days,
        sum(transfer_count) as total_transfers,
        sum(amount_transferred) as total_amount_transferred
    from {{ ref('int_token_daily_transfers') }}
    group by 1

)

select
    activity.token_address,
    tokens.symbol,
    tokens.token_name,
    tokens.decimals,
    stablecoins.token_address is not null as is_stablecoin,
    activity.first_transfer_date,
    activity.last_transfer_date,
    activity.active_days,
    activity.total_transfers,
    activity.total_amount_transferred
from activity
left join {{ ref('stg_eth__tokens') }} as tokens
    on activity.token_address = tokens.token_address
left join {{ ref('stablecoins') }} as stablecoins
    on activity.token_address = stablecoins.token_address
