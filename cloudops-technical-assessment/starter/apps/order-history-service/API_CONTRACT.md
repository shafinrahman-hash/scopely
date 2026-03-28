# Order History Service API Contract

This service provides SQL-backed user profile and historical order views.

## Base URL
- Local: `http://localhost:8003`

## Endpoints

### `GET /health`
Health check for service and database connectivity.

Response `200`:
```json
{
  "status": "healthy",
  "timestamp": "2026-03-10T13:00:00Z"
}
```

### `GET /users/{user_id}`
Return user profile metadata.

Response `200`:
```json
{
  "id": "user-123",
  "email": "user@example.com",
  "status": "active",
  "created_at": "2026-02-01T10:00:00Z"
}
```

Response `404`:
```json
{ "detail": "User not found" }
```

### `POST /users`
Create or update a user profile.

Request body:
```json
{
  "id": "user-123",
  "email": "user@example.com",
  "status": "active"
}
```

Response `200`:
```json
{
  "id": "user-123",
  "email": "user@example.com",
  "status": "active",
  "created_at": "2026-02-01T10:00:00Z"
}
```

### `POST /users/{user_id}/orders`
Create or update an order in the SQL read model for a user.

Request body:
```json
{
  "id": "order-1001",
  "status": "confirmed",
  "total_amount": 54.9,
  "currency": "USD",
  "created_at": "2026-03-01T09:10:00Z"
}
```

Response `200`:
```json
{
  "id": "order-1001",
  "user_id": "user-123",
  "status": "confirmed",
  "total_amount": 54.9,
  "currency": "USD",
  "created_at": "2026-03-01T09:10:00Z",
  "updated_at": "2026-03-01T09:11:00Z"
}
```

### `GET /users/{user_id}/orders`
Return paginated historical orders for a user.

Query params:
- `limit` (default: 20, max: 100)
- `offset` (default: 0)
- `status` (optional)
- `from_date` (optional, ISO date)
- `to_date` (optional, ISO date)

Response `200`:
```json
{
  "items": [
    {
      "id": "order-1001",
      "user_id": "user-123",
      "status": "confirmed",
      "total_amount": 54.9,
      "currency": "USD",
      "created_at": "2026-03-01T09:10:00Z",
      "updated_at": "2026-03-01T09:11:00Z"
    }
  ],
  "limit": 20,
  "offset": 0,
  "count": 1
}
```

### `GET /users/{user_id}/orders/summary`
Return aggregate summary over a rolling window.

Query params:
- `days` (default: 30)

Response `200`:
```json
{
  "user_id": "user-123",
  "days": 30,
  "order_count": 12,
  "total_spend": 840.3,
  "average_order_value": 70.03,
  "orders_by_status": {
    "confirmed": 10,
    "cancelled": 2
  }
}
```

## Data and Consistency Notes
- This API is intended as a SQL read model (query-optimized projection).
- Projection may be eventually consistent relative to write-path services.
- Consumers should treat this as analytical/order-history view, not source of write truth.
