from pydantic import BaseModel
from typing import Optional

class QuizCreate(BaseModel):
    student_id: str
    topic: str
    difficulty: int
    mode: str
    total_questions: int

class AdaptiveTestSubmission(BaseModel):
    student_id: str
    email: Optional[str] = None
    chapter: str
    subtopic: Optional[str] = None
    score: int
    total_questions: int
    time_taken: float  # in seconds
    mastery_level: float # 0.0 to 1.0 (estimated by frontend or previous state)
    difficulty_level: int # The difficulty of the test taken
    answers: Optional[list[dict]] = None # List of {question_id: str, is_correct: bool}

class AdaptiveTestResponse(BaseModel):
    action: str  # "ADVANCE", "RETRY", "COMPLETE"
    message: str
    new_difficulty: int
    recommended_chapter: Optional[str] = None
    recommended_subtopic: Optional[str] = None
    fallback_topics: Optional[list[str]] = []

class ContentGenerateRequest(BaseModel):
    filename: str
    subject: str
    chapter: str
    bucket_name: Optional[str] = "Textbook"
