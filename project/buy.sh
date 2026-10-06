#!/bin/bash
# Купить мем за USDC на anvil-форке через Uniswap V4 PoolSwapTest.
#
#   ./project/buy.sh [AMOUNT_USDC] [MEME_ADDRESS]
#
#   AMOUNT_USDC   сколько USDC потратить (целое или дробное, по умолчанию 1)
#   MEME_ADDRESS  адрес мема; по умолчанию последний TokenCreated контроллера из abis/README.md
#
# Если у покупателя не хватает USDC, скрипт доминчивает их через имперсонацию
# masterMinter'а Circle. Работает только на anvil (anvil_* RPC).
set -euo pipefail

RPC="${RPC_URL:-https://anvil.devinside.tech}"
PK="${PRIVATE_KEY:-0x3dede3458561d2b630b85480bd1478cef39cc0c9f1079d504c8d253f74f609b5}"
README="$(dirname "$0")/../abis/README.md"

AMOUNT="${1:-1}"
AMOUNT_RAW=$(python3 -c "from decimal import Decimal; print(int(Decimal('$AMOUNT')*10**6))")

CONTROLLER=$(grep -m1 CONTROLLER_PROXY "$README" | grep -oE '0x[0-9a-fA-F]{40}')
HOOK=$(grep -m1 HOOK_PROXY "$README" | grep -oE '0x[0-9a-fA-F]{40}')
USDC=$(grep -m1 USDG_ADDRESS "$README" | grep -oE '0x[0-9a-fA-F]{40}')

# Uniswap V4 на Sepolia
SWAP_TEST=0x9B6b46e2c869aa39918Db7f52f5557FE577B6eEe
QUOTER=0x61B3f2011A92d183C7dbaDBdA940a7555Ccf9227
STATE_VIEW=0xE1Dd9c3fA50EDB962E442f60DfBc432e24537E4C
MIN_SQRT_PRICE_PLUS_ONE=4295128740
MAX_SQRT_PRICE_MINUS_ONE=1461446703485210103287273052203988822378723970341

BUYER=$(cast wallet address --private-key "$PK")

MEME="${2:-}"
if [ -z "$MEME" ]; then
  MEME=$(cast logs --rpc-url "$RPC" --from-block 0 --to-block latest --address "$CONTROLLER" \
    "TokenCreated(address indexed token, address indexed creatorAdmin, uint256 indexed positionId, address creatorRewardRecipient, string name, string symbol)" --json \
    | python3 -c "import json,sys; l=json.load(sys.stdin); print('0x'+l[-1]['topics'][1][26:]) if l else sys.exit('no TokenCreated on controller')")
fi

# порядок валют в PoolKey: по возрастанию адреса
if [[ "$(echo "$USDC" | tr A-Z a-z)" < "$(echo "$MEME" | tr A-Z a-z)" ]]; then
  T0=$USDC; T1=$MEME; ZERO_FOR_ONE=True;  LIMIT=$MIN_SQRT_PRICE_PLUS_ONE
else
  T0=$MEME; T1=$USDC; ZERO_FOR_ONE=False; LIMIT=$MAX_SQRT_PRICE_MINUS_ONE
fi
ZFO=$(echo "$ZERO_FOR_ONE" | tr A-Z a-z)   # для cast
POOL_KEY="($T0,$T1,0,200,$HOOK)"
POOL_ID=$(cast keccak "$(cast abi-encode 'f((address,address,uint24,int24,address))' "$POOL_KEY")")

price_from_tick() { # tick -> USDC за мем (USDC 6 знаков, мем 18, raw = 1.0001^tick)
  python3 -c "raw=1.0001**$1; print(f'{(1e12/raw) if $ZERO_FOR_ONE else (raw/1e12):.8f}')"
}
fmt18() { python3 -c "print(f'{$1/1e18:,.2f}')"; }
fmt6()  { python3 -c "print(f'{$1/1e6:,.6f}')"; }

echo "buyer     $BUYER"
echo "meme      $MEME  ($(cast call "$MEME" 'symbol()(string)' --rpc-url "$RPC"))"
echo "pool      $POOL_ID"
TICK_BEFORE=$(cast call "$STATE_VIEW" 'getSlot0(bytes32)(uint160,int24,uint24,uint24)' "$POOL_ID" --rpc-url "$RPC" | sed -n 2p | awk '{print $1}')
echo "price now $(price_from_tick "$TICK_BEFORE") USDC/meme (tick $TICK_BEFORE)"

# --- 1. USDC: доминтить через masterMinter, если не хватает -------------------
USDC_BAL=$(cast call "$USDC" 'balanceOf(address)(uint256)' "$BUYER" --rpc-url "$RPC" | awk '{print $1}')
if [ "$USDC_BAL" -lt "$AMOUNT_RAW" ]; then
  NEED=$((AMOUNT_RAW - USDC_BAL))
  MASTER=$(cast call "$USDC" 'masterMinter()(address)' --rpc-url "$RPC")
  echo "minting   $(fmt6 $NEED) USDC via impersonated masterMinter $MASTER"
  cast rpc anvil_setBalance "$MASTER" 0xDE0B6B3A7640000 --rpc-url "$RPC" >/dev/null
  cast rpc anvil_impersonateAccount "$MASTER" --rpc-url "$RPC" >/dev/null
  cast send "$USDC" 'configureMinter(address,uint256)' "$MASTER" "$NEED" --from "$MASTER" --unlocked --rpc-url "$RPC" >/dev/null
  cast send "$USDC" 'mint(address,uint256)' "$BUYER" "$NEED" --from "$MASTER" --unlocked --rpc-url "$RPC" >/dev/null
  cast rpc anvil_stopImpersonatingAccount "$MASTER" --rpc-url "$RPC" >/dev/null
fi

# --- 2. котировка -------------------------------------------------------------
QUOTE=$(cast call "$QUOTER" \
  'quoteExactInputSingle(((address,address,uint24,int24,address),bool,uint128,bytes))(uint256,uint256)' \
  "($POOL_KEY,$ZFO,$AMOUNT_RAW,0x)" --rpc-url "$RPC" | head -1 | awk '{print $1}')
echo "quote     $AMOUNT USDC -> $(fmt18 "$QUOTE") meme"

# --- 3. approve + swap ----------------------------------------------------------
ALLOW=$(cast call "$USDC" 'allowance(address,address)(uint256)' "$BUYER" "$SWAP_TEST" --rpc-url "$RPC" | awk '{print $1}')
if [ "$ALLOW" -lt "$AMOUNT_RAW" ]; then
  cast send "$USDC" 'approve(address,uint256)' "$SWAP_TEST" "$AMOUNT_RAW" --private-key "$PK" --rpc-url "$RPC" >/dev/null
fi

MEME_BEFORE=$(cast call "$MEME" 'balanceOf(address)(uint256)' "$BUYER" --rpc-url "$RPC" | awk '{print $1}')
TX=$(cast send "$SWAP_TEST" \
  'swap((address,address,uint24,int24,address),(bool,int256,uint160),(bool,bool),bytes)' \
  "$POOL_KEY" "($ZFO,-$AMOUNT_RAW,$LIMIT)" "(false,false)" 0x \
  --private-key "$PK" --rpc-url "$RPC" --json)
STATUS=$(echo "$TX" | python3 -c "import json,sys; t=json.load(sys.stdin); print(t['status'], t['transactionHash'], int(t['gasUsed'],16))")
echo "tx        $STATUS"
case "$STATUS" in 0x1*) ;; *) echo "swap reverted"; exit 1;; esac

# --- 4. результат ---------------------------------------------------------------
MEME_AFTER=$(cast call "$MEME" 'balanceOf(address)(uint256)' "$BUYER" --rpc-url "$RPC" | awk '{print $1}')
GOT=$(python3 -c "print($MEME_AFTER - $MEME_BEFORE)")   # суммы > 2^63, bash-арифметика не годится
TICK_AFTER=$(cast call "$STATE_VIEW" 'getSlot0(bytes32)(uint160,int24,uint24,uint24)' "$POOL_ID" --rpc-url "$RPC" | sed -n 2p | awk '{print $1}')
echo "received  $(fmt18 $GOT) meme  (quote was $(fmt18 "$QUOTE"))"
python3 -c "print(f'paid      {$AMOUNT_RAW/1e6/($GOT/1e18):.8f} USDC/meme effective')"
echo "price now $(price_from_tick "$TICK_AFTER") USDC/meme (tick $TICK_AFTER)"
echo "balances  $(fmt6 "$(cast call "$USDC" 'balanceOf(address)(uint256)' "$BUYER" --rpc-url "$RPC" | awk '{print $1}')") USDC, $(fmt18 "$MEME_AFTER") meme"
