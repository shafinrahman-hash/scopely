# order-history-service (Starter)

SQL-backed read model for user profile and historical order views.

## Purpose
- Add relational data modeling and query/index design to the challenge.
- Demonstrate event-driven projection from order events into a SQL read model.

## Environment Variables
- `DATABASE_URL` (required)
- `DEFAULT_PAGE_SIZE` (optional, default: `20`)

## Run Locally
```bash
cd starter/apps/order-history-service
pip install -r requirements.txt
uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
```

## Suggested Next Steps for Candidates
- Populate this service from queue-consumed order events.
- Add idempotent upsert logic for projection updates.
- Extend schema for richer analytics/reporting queries.
