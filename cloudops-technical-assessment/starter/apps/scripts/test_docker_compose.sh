#!/bin/bash

SERVER_ENDPOINT=${SERVER_ENDPOINT:-"http://localhost:8001"}
ORDER_HISTORY_ENDPOINT=${ORDER_HISTORY_ENDPOINT:-"http://localhost:8003"}

echo "Seeding order-history user CUST001..."
curl -s -X POST "${ORDER_HISTORY_ENDPOINT}/users" \
  -H "Content-Type: application/json" \
  -d '{"id":"CUST001","email":"cust001@example.com","status":"active"}'
echo ""

echo "Calling endpoint ${SERVER_ENDPOINT}"
ORDER=$(
  curl -s -X POST $SERVER_ENDPOINT/orders/ \
    -H "Content-Type: application/json" \
    -d @- <<'EOF'
{
    "product_id": "PROD001",
    "quantity": 1,
    "customer_id": "CUST001"
}
EOF
)
echo "$ORDER"
ORDER_ID=$(echo "$ORDER" | python3 -c 'import sys, json; d=json.loads(sys.stdin.read()); print(d.get("order_id",""))')

echo "$ORDER_ID"
curl -X GET ${SERVER_ENDPOINT}/orders/$ORDER_ID

echo ""
echo "Checking order-history-service endpoints at ${ORDER_HISTORY_ENDPOINT}"
curl -s -X GET ${ORDER_HISTORY_ENDPOINT}/users/CUST001
echo ""
curl -s -X GET "${ORDER_HISTORY_ENDPOINT}/users/CUST001/orders?limit=5&status=confirmed"
echo ""
curl -s -X GET "${ORDER_HISTORY_ENDPOINT}/users/CUST001/orders/summary?days=30"
echo ""
