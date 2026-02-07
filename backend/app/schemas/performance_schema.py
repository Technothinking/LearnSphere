from pydantic import BaseModel

class PerformanceCreate(BaseModel):
    accuracy: float
    avg_time: float
    correct: bool
    failure_streak: int
