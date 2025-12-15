from fastapi import FastAPI
import os

app = FastAPI()

@app.get("/healthz")
def healthz():
    return {"status": "ok"}

@app.get("/readyz")
def readyz():
    # In real setups you might check DB/Redis connectivity
    return {"ready": True}

@app.get("/version")
def version():
    return {"version": os.getenv("APP_VERSION", "dev")}