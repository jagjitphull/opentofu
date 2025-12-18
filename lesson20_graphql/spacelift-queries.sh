#!/bin/bash
# Spacelift GraphQL Query Script (Fixed Escaping)

STACK_ID="ec2-demo-stack"

query() {
    curl -s -X POST "$SPACELIFT_ENDPOINT" \
        -H "Authorization: Bearer $SPACELIFT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$1"
}

echo "=== Stacks ==="
query '{"query":"query{stacks{id name state}}"}' | jq '.data.stacks'

echo -e "\n=== Stack Details ==="
query "{\"query\":\"query{stack(id:\\\"$STACK_ID\\\"){id name state autodeploy}}\"}" | jq '.data.stack'

echo -e "\n=== Outputs ==="
query "{\"query\":\"query{stack(id:\\\"$STACK_ID\\\"){outputs{id value}}}\"}" | jq '.data.stack.outputs'

echo -e "\n=== Recent Runs ==="
query "{\"query\":\"query{stack(id:\\\"$STACK_ID\\\"){runs{id state type createdAt}}}\"}" | jq '.data.stack.runs[:5]'
