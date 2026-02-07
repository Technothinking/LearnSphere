from pydantic import BaseModel

class StudentCreate(BaseModel):
    id: str
    grade: int


class StudentState(BaseModel):
    avg_accuracy_last_5: float
    avg_time_per_question: float
    current_difficulty: int
    topic_mastery: float
    attempts: int
    recent_improvement: float
