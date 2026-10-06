#!/bin/bash

signature="deployToken(((string,string,(string,string,string,string),string,string,(address,bool)[]),(uint256,address,address),(address,uint16)[]))"
tx='((https://img.url,desc,(fc,tw,tg,web),MyToken3,MTK4,[(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238,true)]),(1000000000000000000,0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238,0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238),[(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238,10000)])'

json=$(cat ${PWD}/project/args-deploy.json|jq -r '.deploy')


out=$(cast send "0x4a9F25C077e7487969f8dd60F92218FD6111bF85" \
  "${signature}" \
  "${tx}" \
  --json ${PWD}/project/args.json \
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

echo "Success!"
echo "$out"