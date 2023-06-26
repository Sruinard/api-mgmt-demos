import json

import requests
import uvicorn
from azure.monitor.opentelemetry.exporter import AzureMonitorTraceExporter
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from webshop.config import Config
from fastapi import FastAPI, Request, Form
from fastapi.templating import Jinja2Templates
import random
import time
from pydantic import BaseModel

class Order(BaseModel):
    item_id: int
    price: float
    quantity: int



def raise_error_or_delay():
    probs = random.random()
    if probs < 0.1:
        raise Exception("Webshop Error")
    elif probs < 0.2:
        sleep_seconds = random.randint(0, 3)
        time.sleep(sleep_seconds)


templates = Jinja2Templates(directory="templates/")
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
    resource=Resource.create({SERVICE_NAME: "webshop"})
))
tracer = trace.get_tracer(__name__)


@app.on_event("startup")
def startup_event():
    # This line causes your calls made with the requests library to be tracked.
    RequestsInstrumentor().instrument()
    span_processor = BatchSpanProcessor(
        AzureMonitorTraceExporter.from_connection_string(
            Config.APPINSIGHTS_CONNECTION_STRING
        )
    )
    trace.get_tracer_provider().add_span_processor(span_processor)

    RequestsInstrumentor().instrument()
    FastAPIInstrumentor.instrument_app(
        app, tracer_provider=trace.get_tracer_provider())


@app.get("/")
async def get():
    return "Distributed tracing"


@app.get("/orders")
def post_form(request: Request):
    return templates.TemplateResponse('form.html', context={'request': request})


@app.get("/shipments")
def get_shipments():
    response = requests.get(Config.SHIPMENTS_ENDPOINT + "shipments")
    return response.json()




@app.post("/orders")
def post_form(order: Order):
    raise_error_or_delay()

    order = {
        'item_id': order.item_id,
        'price': order.price,
        'quantity': order.quantity
    }
    response = requests.post(Config.PAYMENTS_ENDPOINT +
                             "payments", data=json.dumps(order)).json()
    return response


if __name__ == "__main__":
    uvicorn.run(app)
