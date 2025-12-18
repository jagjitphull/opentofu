#!/bin/bash
# discover-destroy-methods.sh

echo "========================================="
echo "Discovering Spacelift Destruction Methods"
echo "========================================="

# 1. Find all destroy/delete related mutations
echo ""
echo "1. Searching for destroy/delete mutations:"
echo "-----------------------------------------"
curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ __schema { mutationType { fields { name } } } }"
  }' | jq -r '.data.__schema.mutationType.fields[].name' | grep -E "destroy|delete|remove" | sort

# 2. Find all run-related mutations
echo ""
echo "2. All run-related mutations:"
echo "-----------------------------------------"
curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ __schema { mutationType { fields { name } } } }"
  }' | jq -r '.data.__schema.mutationType.fields[].name' | grep -i "run" | sort

# 3. Check runTrigger parameters
echo ""
echo "3. runTrigger mutation details:"
echo "-----------------------------------------"
curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ __type(name: \"Mutation\") { fields { name args { name type { name kind ofType { name } } } } } }"
  }' | jq '.data.__type.fields[] | select(.name == "runTrigger")'

# 4. Check stackDestroy if it exists
echo ""
echo "4. stackDestroy mutation details (if exists):"
echo "-----------------------------------------"
curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ __type(name: \"Mutation\") { fields { name args { name type { name } } } } }"
  }' | jq '.data.__type.fields[] | select(.name | contains("stack") and contains("estroy"))'

# 5. List ALL mutations for reference
echo ""
echo "5. All available mutations:"
echo "-----------------------------------------"
curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ __schema { mutationType { fields { name } } } }"
  }' | jq -r '.data.__schema.mutationType.fields[].name' | sort
