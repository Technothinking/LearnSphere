from sqlalchemy.orm import Session
from app.models.quiz import Quiz

def create_quiz(
    db: Session,
    student_id: str,
    topic: str,
    difficulty: int,
    mode: str,
    total_questions: int
):
    quiz = Quiz(
        student_id=student_id,
        topic=topic,
        difficulty=difficulty,
        mode=mode,
        total_questions=total_questions
    )
    db.add(quiz)
    db.commit()
    db.refresh(quiz)
    return quiz
