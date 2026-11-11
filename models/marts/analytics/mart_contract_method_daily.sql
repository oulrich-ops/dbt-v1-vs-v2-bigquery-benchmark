select
    block_date,
    method_id,
    sum(call_count) as call_count,
    count(distinct contract_address) as contracts_called,
    sum(fees_eth) as fees_eth
from {{ ref('int_contract_daily_calls') }}
group by 1, 2
