from sqlalchemy import Column, Integer, String, Float
from app.core.database import Base

class Quiz(Base):
    __tablename__ = "quizzes"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(String, index=True)

    topic = Column(String, nullable=False)
    difficulty = Column(Integer, nullable=False)  # 0,1,2
    mode = Column(String, nullable=False)         # revise / test / advance

    total_questions = Column(Integer, nullable=False)
