#!/bin/bash
# discover-mutations.sh

echo "======================================"
echo "Discovering Available Mutations"
echo "======================================"

curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ __schema { mutationType { fields { name description } } } }"
  }' | jq -r '.data.__schema.mutationType.fields[] | "\(.name) - \(.description)"' | grep -i "destroy\|delete\|stack"
