#!/bin/bash
# query-stack-jwt.sh

STACK_ID="ec2-demo-stack"

curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"query { stack(id: \\\"$STACK_ID\\\") { id name state description trackedCommit { hash authorName message } } }\"
  }" | jq .
