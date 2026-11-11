select
    daily.block_date,
    daily.token_address,
    tokens.symbol,
    tokens.is_stablecoin,
    daily.transfer_count,
    daily.unique_senders,
    daily.unique_receivers,
    daily.amount_transferred
from {{ ref('int_token_daily_transfers') }} as daily
left join {{ ref('dim_tokens') }} as tokens
    on daily.token_address = tokens.token_address
