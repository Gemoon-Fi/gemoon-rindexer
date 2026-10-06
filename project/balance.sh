#!/bin/bash
# Баланс ERC20 у адреса.
#
#   ./project/balance.sh <TOKEN> <HOLDER>
#
# RPC_URL переопределяет anvil по умолчанию.
set -euo pipefail

RPC="${RPC_URL:-https://anvil.devinside.tech}"
TOKEN="${1:?usage: $0 <TOKEN> <HOLDER>}"
HOLDER="${2:?usage: $0 <TOKEN> <HOLDER>}"

SYMBOL=$(cast call "$TOKEN" 'symbol()(string)' --rpc-url "$RPC" | tr -d '"')
DECIMALS=$(cast call "$TOKEN" 'decimals()(uint8)' --rpc-url "$RPC")
RAW=$(cast call "$TOKEN" 'balanceOf(address)(uint256)' "$HOLDER" --rpc-url "$RPC" | awk '{print $1}')

python3 -c "
from decimal import Decimal
raw=Decimal($RAW); d=$DECIMALS
print(f'{raw/10**d:,.{d}f}'.rstrip('0').rstrip('.') or '0', '$SYMBOL', f'(raw {raw}, decimals {d})')"
