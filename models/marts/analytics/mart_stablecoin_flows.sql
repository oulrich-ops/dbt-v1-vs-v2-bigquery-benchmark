select
    transfers.block_date,
    stablecoins.stablecoin_symbol,
    count(*) as transfer_count,
    approx_count_distinct(transfers.from_address) as unique_senders,
    sum(transfers.amount) as amount_transferred,
    avg(transfers.amount) as avg_transfer_amount
from {{ ref('int_token_transfers_enriched') }} as transfers
inner join {{ ref('stablecoins') }} as stablecoins
    on transfers.token_address = stablecoins.token_address
group by 1, 2
