#!/bin/bash
# discover-stack-fields.sh

echo "======================================"
echo "Discovering Stack Type Fields"
echo "======================================"

curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ __type(name: \"Stack\") { fields { name description type { name kind } } } }"
  }' | jq '.data.__type.fields[] | {name, description}'
