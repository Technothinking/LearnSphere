from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey
from app.core.database import Base

class Attempt(Base):
    __tablename__ = "attempts"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(String, ForeignKey("students.id"))
    quiz_id = Column(Integer, ForeignKey("quizzes.id"))

    accuracy = Column(Float, nullable=False)
    avg_time = Column(Float, nullable=False)
    correct = Column(Boolean, nullable=False)
    failure_streak = Column(Integer, default=0)
