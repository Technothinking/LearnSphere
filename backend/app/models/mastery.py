from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey
from app.core.database import Base

class SubtopicMastery(Base):
    __tablename__ = "subtopic_mastery"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(String, ForeignKey("students.id"), index=True)
    chapter = Column(String, nullable=False, index=True)
    subtopic = Column(String, nullable=True, index=True) # Null means full chapter mastery
    accuracy = Column(Float, default=0.0)
    mastery = Column(Float, default=0.0) # Weighted score (0.0 to 1.0)
    level = Column(Integer, default=0) # 0: Easy, 1: Medium, 2: Hard
    is_completed = Column(Boolean, default=False)
    last_action = Column(String, nullable=True) # RETRY or ADVANCE
