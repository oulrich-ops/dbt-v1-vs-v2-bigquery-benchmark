select
    token_address,
    symbol,
    token_name,
    total_transfers,
    active_days,
    rank() over (order by total_transfers desc) as transfer_rank
from {{ ref('dim_tokens') }}
qualify transfer_rank <= 1000
