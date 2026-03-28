from datetime import date, datetime, timezone
import logging
import os
from typing import Optional

from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel
import psycopg
from psycopg.rows import dict_row

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - [%(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

DATABASE_URL = os.getenv("DATABASE_URL")
DEFAULT_PAGE_SIZE = int(os.getenv("DEFAULT_PAGE_SIZE", "20"))
MAX_PAGE_SIZE = 100

app = FastAPI(title="Order History Service")


class UserCreate(BaseModel):
    id: str
    email: str
    status: str = "active"


class OrderCreate(BaseModel):
    id: str
    status: str
    total_amount: float
    currency: str = "USD"
    created_at: Optional[datetime] = None


def _connect() -> psycopg.Connection:
    if not DATABASE_URL:
        raise HTTPException(status_code=500, detail="DATABASE_URL is not configured")
    return psycopg.connect(DATABASE_URL, row_factory=dict_row)


@app.get("/health/live")
def health_live() -> dict:
    """Liveness only (no DB). Use for Docker/K8s probes so the process can be up before the first DB connection succeeds."""
    return {"status": "ok"}


@app.get("/health")
def health_check() -> dict:
    try:
        with _connect() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                cur.fetchone()
        return {"status": "healthy", "timestamp": datetime.now(timezone.utc).isoformat()}
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("Health check failed: %s", exc)
        raise HTTPException(status_code=503, detail="Database is unhealthy")


@app.get("/users/{user_id}")
def get_user(user_id: str) -> dict:
    try:
        with _connect() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT id, email, status, created_at FROM users WHERE id = %s",
                    (user_id,),
                )
                user = cur.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return user
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("Failed to fetch user %s: %s", user_id, exc)
        raise HTTPException(status_code=500, detail="Failed to fetch user")


@app.post("/users")
def create_or_update_user(payload: UserCreate) -> dict:
    try:
        with _connect() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO users (id, email, status)
                    VALUES (%s, %s, %s)
                    ON CONFLICT (id) DO UPDATE
                    SET email = EXCLUDED.email,
                        status = EXCLUDED.status
                    RETURNING id, email, status, created_at
                    """,
                    (payload.id, payload.email, payload.status),
                )
                user = cur.fetchone()
                conn.commit()
        return user
    except Exception as exc:
        logger.error("Failed to upsert user %s: %s", payload.id, exc)
        raise HTTPException(status_code=500, detail="Failed to upsert user")


@app.post("/users/{user_id}/orders")
def create_or_update_user_order(user_id: str, payload: OrderCreate) -> dict:
    created_at = payload.created_at or datetime.now(timezone.utc)
    try:
        with _connect() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO orders (id, user_id, status, total_amount, currency, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, NOW())
                    ON CONFLICT (id) DO UPDATE
                    SET user_id = EXCLUDED.user_id,
                        status = EXCLUDED.status,
                        total_amount = EXCLUDED.total_amount,
                        currency = EXCLUDED.currency,
                        created_at = EXCLUDED.created_at,
                        updated_at = NOW()
                    RETURNING id, user_id, status, total_amount, currency, created_at, updated_at
                    """,
                    (
                        payload.id,
                        user_id,
                        payload.status,
                        payload.total_amount,
                        payload.currency,
                        created_at,
                    ),
                )
                order = cur.fetchone()
                conn.commit()
        return order
    except Exception as exc:
        logger.error("Failed to upsert order %s for user %s: %s", payload.id, user_id, exc)
        raise HTTPException(status_code=500, detail="Failed to upsert order")


@app.get("/users/{user_id}/orders")
def get_user_orders(
    user_id: str,
    limit: int = Query(default=DEFAULT_PAGE_SIZE, ge=1, le=MAX_PAGE_SIZE),
    offset: int = Query(default=0, ge=0),
    status: Optional[str] = Query(default=None),
    from_date: Optional[date] = Query(default=None),
    to_date: Optional[date] = Query(default=None),
) -> dict:
    filters = ["user_id = %s"]
    params: list = [user_id]

    if status:
        filters.append("status = %s")
        params.append(status)
    if from_date:
        filters.append("created_at >= %s")
        params.append(from_date)
    if to_date:
        filters.append("created_at <= %s")
        params.append(to_date)

    where_clause = " AND ".join(filters)
    query = f"""
        SELECT id, user_id, status, total_amount, currency, created_at, updated_at
        FROM orders
        WHERE {where_clause}
        ORDER BY created_at DESC
        LIMIT %s OFFSET %s
    """
    params.extend([limit, offset])

    try:
        with _connect() as conn:
            with conn.cursor() as cur:
                cur.execute(query, tuple(params))
                rows = cur.fetchall()
        return {"items": rows, "limit": limit, "offset": offset, "count": len(rows)}
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("Failed to fetch orders for user %s: %s", user_id, exc)
        raise HTTPException(status_code=500, detail="Failed to fetch orders")


@app.get("/users/{user_id}/orders/summary")
def get_user_order_summary(
    user_id: str,
    days: int = Query(default=30, ge=1, le=3650),
) -> dict:
    try:
        with _connect() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT
                        COUNT(*) AS order_count,
                        COALESCE(SUM(total_amount), 0) AS total_spend,
                        COALESCE(AVG(total_amount), 0) AS average_order_value
                    FROM orders
                    WHERE user_id = %s
                      AND created_at >= NOW() - (%s || ' days')::interval
                    """,
                    (user_id, days),
                )
                aggregate = cur.fetchone()

                cur.execute(
                    """
                    SELECT status, COUNT(*) AS cnt
                    FROM orders
                    WHERE user_id = %s
                      AND created_at >= NOW() - (%s || ' days')::interval
                    GROUP BY status
                    """,
                    (user_id, days),
                )
                by_status_rows = cur.fetchall()

        by_status = {row["status"]: row["cnt"] for row in by_status_rows}
        return {
            "user_id": user_id,
            "days": days,
            "order_count": aggregate["order_count"],
            "total_spend": float(aggregate["total_spend"]),
            "average_order_value": float(aggregate["average_order_value"]),
            "orders_by_status": by_status,
        }
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("Failed to fetch summary for user %s: %s", user_id, exc)
        raise HTTPException(status_code=500, detail="Failed to fetch summary")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
