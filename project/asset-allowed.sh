#!/bin/bash
signature='setAssetAllowed(address,bool)'
tx='(0x1234567890123456789012345678901234567890,true)'

json=$(cat ${PWD}/project/args-deploy.json|jq -r '.asset_allow')

out=$(cast send "0x8FcB2ED22b7D0F50561bD756bDdb345D0C670113" \
  "${signature}" \
  "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238" \
  true \
  --rpc-url https://anvil.devinside.tech \
  --private-key "0x3dede3458561d2b630b85480bd1478cef39cc0c9f1079d504c8d253f74f609b5" 2>&1
)

if [ $? -ne 0 ]; then
  echo "Error: Failed to send transaction"
  echo "$out"

  # Извлекаем полный calldata кастомной ошибки (селектор + аргументы)
  error_data=$(echo "$out" | grep -oE 'custom error 0x[0-9a-fA-F]+' | sed 's/custom error //' | head -1)

  if [ -n "$error_data" ]; then
    echo ""
    echo "=== Decoding custom error ==="
    echo "Raw calldata: $error_data"

    # Пробуем декодировать через 4byte.directory
    decoded=$(cast 4byte-decode "$error_data" 2>/dev/null)
    if [ -n "$decoded" ]; then
      echo "Decoded (4byte):"
      echo "$decoded"
    else
      echo "Selector not found in 4byte.directory"
    fi
  fi

  exit 1
fi

echo "Check if asset is allowed:"
out=$(cast call 0x8FcB2ED22b7D0F50561bD756bDdb345D0C670113 "isAssetAllowed(address)" 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238 --rpc-url https://anvil.devinside.tech)


if [[ $out == "0x0000000000000000000000000000000000000000000000000000000000000001" ]]; then
  echo "Asset is allowed"
else
  echo "Asset is NOT allowed"
fi

echo "Success!"