#!/bin/bash
# introspect-stack-output.sh

curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ __type(name: \"StackOutput\") { fields { name type { name kind } } } }"
  }' | jq '.data.__type.fields[] | .name'
