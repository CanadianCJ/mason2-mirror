from fastapi import FastAPI, Request
from pydantic import BaseModel

app = FastAPI()

class OnyxCommand(BaseModel):
    action: str

@app.post("/onyx/execute")
async def onyx_execute(cmd: OnyxCommand):
    print(f"Onyx received: {cmd.action}")
    # Here you'd call Onyx features like report generation, etc.
    return {"status": "Onyx executed", "action": cmd.action}
