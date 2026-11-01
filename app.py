from fastapi import BackgroundTasks, FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Sicherheitsrichtlinien API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"status": "online", "service": "Sicherheitsrichtlinien API"}

@app.post("/task")
async def run_task(background_tasks: BackgroundTasks):
    return {"message": "Hintergrundaufgabe wurde eingereiht."}

if __name__ == "__main__":
    import uvicorn
    # Feste Bindung ohne Watchfiles/Reload-Probleme unter Windows
    uvicorn.run(app, host="127.0.0.1", port=8000)
