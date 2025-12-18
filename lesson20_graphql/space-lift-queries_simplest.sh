#!/bin/bash
# Spacelift Queries - Simplest Version

STACK_ID="ec2-demo-stack"

echo "=== 1. Stacks ==="
curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"query{stacks{id name state}}"}' | jq '.data.stacks'

echo ""
echo "=== 2. Stack Details ==="
curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"query\":\"query{stack(id:\\\"$STACK_ID\\\"){id name state autodeploy}}\"}" | jq '.data.stack'

echo ""
echo "=== 3. Outputs ==="
curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"query\":\"query{stack(id:\\\"$STACK_ID\\\"){outputs{id value}}}\"}" | jq '.data.stack.outputs'

echo ""
echo "=== 4. Recent Runs ==="
curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"query\":\"query{stack(id:\\\"$STACK_ID\\\"){runs{id state type}}}\"}" | jq '.data.stack.runs[:5]'
