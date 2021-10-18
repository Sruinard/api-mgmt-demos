from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import graphene
from starlette.graphql import GraphQLApp
from payments.query import Query
from payments.mutation import Mutation
from payments.orm import Base, engine
import uvicorn

Base.metadata.create_all(bind=engine)

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_route("/graphql", GraphQLApp(schema=graphene.Schema(query=Query, mutation=Mutation)))

@app.get("/")
def homepage():
    return "Fast API + GraphQL"

if __name__ == "__main__":
    uvicorn.run(app=app, host="0.0.0.0", port=8000)
