#!/bin/bash
# spacelift-jwt-tester.sh (CORRECTED)

echo "======================================"
echo "Spacelift JWT Authentication Test"
echo "======================================"

# Check environment variables
if [ -z "$SPACELIFT_ENDPOINT" ]; then
    echo "❌ SPACELIFT_ENDPOINT not set"
    echo "   Run: export SPACELIFT_ENDPOINT=https://ilglabs.app.spacelift.io/graphql"
    exit 1
fi

if [ -z "$SPACELIFT_TOKEN" ]; then
    echo "❌ SPACELIFT_TOKEN not set"
    echo "   Run: export SPACELIFT_TOKEN=\"your-jwt-token-here\""
    exit 1
fi

echo "✅ Endpoint: $SPACELIFT_ENDPOINT"
echo "✅ Token: ${SPACELIFT_TOKEN:0:50}..."
echo ""

# Check if it looks like a JWT
if [[ "$SPACELIFT_TOKEN" == eyJ* ]]; then
    echo "✅ Token format looks like JWT (starts with 'eyJ')"
else
    echo "⚠️  Warning: Token doesn't start with 'eyJ' - might not be a JWT"
fi

echo ""
echo "======================================"
echo "1. Testing Authentication"
echo "======================================"

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { stacks { id name state } }"
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Authentication successful!"
    echo ""
    echo "Your Stacks:"
    echo "$BODY" | jq '.data.stacks[] | {id, name, state}'
else
    echo "❌ Authentication failed"
    echo "$BODY" | jq .
    exit 1
fi

echo ""
echo "======================================"
echo "2. Testing Stack Query"
echo "======================================"

# Try to get the first stack
STACK_ID=$(echo "$BODY" | jq -r '.data.stacks[0].id // empty')

if [ -z "$STACK_ID" ]; then
    echo "⚠️  No stacks found"
    exit 0
fi

echo "Querying stack: $STACK_ID"
echo ""

curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"query { stack(id: \\\"$STACK_ID\\\") { id name state description worker trackedCommit { hash authorName message } } }\"
  }" | jq .

echo ""
echo "======================================"
echo "3. Testing Runs Query"
echo "======================================"

curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"query { stack(id: \\\"$STACK_ID\\\") { runs { id state type createdAt } } }\"
  }" | jq '.data.stack.runs[:5]'

echo ""
echo "======================================"
echo "4. Testing Outputs Query (CORRECTED)"
echo "======================================"

curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"query { stack(id: \\\"$STACK_ID\\\") { outputs { id value } } }\"
  }" | jq .



echo ""
echo "======================================"
echo "5. Testing Environment Variables"
echo "======================================"
curl -s -X POST "$SPACELIFT_ENDPOINT" \
  -H "Authorization: Bearer $SPACELIFT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"query { stack(id: \\\"$STACK_ID\\\") { environment { id name value writeOnly } } }\"
  }" | jq .

echo ""
echo "======================================"
echo "✅ All tests completed!"
echo "======================================"
