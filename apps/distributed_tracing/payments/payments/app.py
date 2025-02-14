import uvicorn
import json
import requests
from azure.monitor.opentelemetry.exporter import AzureMonitorTraceExporter
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import (BatchSpanProcessor,
                                            ConsoleSpanExporter,
                                            SimpleSpanProcessor)

from payments.models import Order
from payments.config import Config

import random
import time


def raise_error_or_delay():
    probs = random.random()
    if probs < 0.1:
        raise Exception("Webshop Error")
    elif probs < 0.2:
        sleep_seconds = random.randint(0, 3)
        time.sleep(sleep_seconds)


load_dotenv()

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

trace.set_tracer_provider(TracerProvider(
    resource=Resource.create({SERVICE_NAME: "payments"})
))
tracer = trace.get_tracer(__name__)


@app.on_event("startup")
def startup_event():
    # This line causes your calls made with the requests library to be tracked.
    span_processor = BatchSpanProcessor(
        AzureMonitorTraceExporter.from_connection_string(
            Config.appinsights_connection_string
        )
    )
    trace.get_tracer_provider().add_span_processor(span_processor)

    # trace.get_tracer_provider().add_span_processor(
    #     SimpleSpanProcessor(ConsoleSpanExporter())
    # )
    RequestsInstrumentor().instrument()
    FastAPIInstrumentor.instrument_app(
        app, tracer_provider=trace.get_tracer_provider())


@app.get("/")
async def get():
    return "Distributed tracing"


@app.post("/payments")
async def create_order(order: Order):
    raise_error_or_delay()
    # order_to_place = order.json()

    order_to_place = {
        "item_id": order.item_id,
        "quantity": order.quantity,
        "price": order.price
    }

    data = json.dumps(order_to_place)
    placed_order = requests.post(
        Config.shipping_endpoint + "shipments", data=data,
        headers={"Content-Type": "application/json"}
        ).json()
    return placed_order


if __name__ == "__main__":
    uvicorn.run(app)
