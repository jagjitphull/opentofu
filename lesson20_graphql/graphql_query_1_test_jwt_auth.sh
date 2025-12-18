#!/bin/bash
# test-jwt-auth.sh

curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { stacks { id name state } }"
  }' | jq .
