#!/bin/bash
# trigger-destroy-run.sh

STACK_ID="ec2-demo-stack"

echo "======================================"
echo "Triggering Run (Check for Destroy Options)"
echo "======================================"

# Check what parameters runTrigger accepts
curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ __type(name: \"Mutation\") { fields(includeDeprecated: true) { name args { name type { name kind ofType { name } } } } } }"
  }' | jq '.data.__type.fields[] | select(.name | contains("run") or contains("trigger"))'
