#!/bin/bash
# query-outputs-jwt.sh (CORRECTED)

STACK_ID="ec2-demo-stack"

curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"query { stack(id: \\\"$STACK_ID\\\") { outputs { id value } } }\"
  }" | jq .
