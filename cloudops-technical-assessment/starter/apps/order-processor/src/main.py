from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel
import boto3
import httpx
import logging
import os
import uuid

from datetime import datetime, timezone
from typing import Optional

DYNAMODB_ENDPOINT = os.getenv("DYNAMODB_ENDPOINT", None)
DYNAMODB_TABLE = os.getenv("DYNAMODB_TABLE", "inventory")
ORDER_HISTORY_URL = os.getenv("ORDER_HISTORY_URL", "").rstrip("/")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - [%(name)s - %(levelname)s - %(message)s",
)

logger = logging.getLogger(__name__)


app = FastAPI(title="Order Processor")


class OrderRequest(BaseModel):
    product_id: str
    quantity: int
    customer_id: str


class ProcessedOrder(BaseModel):
    order_id: str
    status: str
    total_price: int
    processed_at: str


class InventoryRepository:
    def __init__(self):
        dynamodb = boto3.resource("dynamodb", endpoint_url=DYNAMODB_ENDPOINT)
        self.table = dynamodb.Table(DYNAMODB_TABLE)

    async def check_and_update_inventory(
        self, product_id: str, quantity: int
    ) -> Optional[int]:
        try:
            response = self.table.get_item(Key={"product_id": product_id})

            item = response.get("Item")
            if not item or item["stock"] < quantity:
                logger.error(
                    f"Insufficient stock for product {product_id}",
                )
                return None

            self.table.update_item(
                Key={"product_id": product_id},
                UpdateExpression="SET stock = stock - :quantity",
                ExpressionAttributeValues={":quantity": quantity},
            )

            return int(item["price"] * quantity)

        except Exception as e:
            logger.error(
                f"Inventory operation failed: {str(e)}",
            )
            raise HTTPException(
                status_code=500, detail="Inventory operation failed"
            )


@app.on_event("startup")
async def startup_event():
    logger.info("Application started")


async def update_order_history_projection(order_id: str, order: OrderRequest, processed_at: str, total_price: int) -> None:
    if not ORDER_HISTORY_URL:
        return

    # This starter uses direct calls for local bootstrap; candidates can replace with async queue-driven projection.
    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            await client.post(
                f"{ORDER_HISTORY_URL}/users",
                json={
                    "id": order.customer_id,
                    "email": f"{order.customer_id.lower()}@example.com",
                    "status": "active",
                },
            )
            await client.post(
                f"{ORDER_HISTORY_URL}/users/{order.customer_id}/orders",
                json={
                    "id": order_id,
                    "status": "confirmed",
                    "total_amount": total_price,
                    "currency": "USD",
                    "created_at": processed_at,
                },
            )
    except Exception as exc:
        logger.warning("Failed to update order-history projection for order %s: %s", order_id, exc)


@app.post("/process-order", response_model=ProcessedOrder)
async def process_order(order: OrderRequest, request: Request):

    logger.info(
        f"Processing order for product {order.product_id}",
    )

    repository = InventoryRepository()
    total_price = await repository.check_and_update_inventory(
        order.product_id, order.quantity
    )

    if total_price is None:
        raise HTTPException(status_code=400, detail="Insufficient inventory")

    order_id = str(uuid.uuid4())
    processed_at = datetime.now(timezone.utc).isoformat()
    await update_order_history_projection(
        order_id=order_id,
        order=order,
        processed_at=processed_at,
        total_price=total_price,
    )

    return ProcessedOrder(
        order_id=order_id,
        status="confirmed",
        total_price=total_price,
        processed_at=processed_at,
    )


@app.get("/health")
async def health_check():
    try:
        repository = InventoryRepository()
        repository.table.scan(Limit=1)

        return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        raise HTTPException(status_code=503, detail=f"Database is unhealthy: {str(e)}")


@app.get("/health/live")
async def health_live():
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8001)
