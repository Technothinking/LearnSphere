from sqlalchemy import Column, Integer, String, Float
from sqlalchemy.orm import relationship
from app.core.database import Base

class Student(Base):
    __tablename__ = "students"

    id = Column(String, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    grade = Column(Integer, nullable=False)

    # Aggregated performance metrics (RL state)
    avg_accuracy_last_5 = Column(Float, default=0.0)
    avg_time_per_question = Column(Float, default=0.0)
    current_difficulty = Column(Integer, default=0)  # 0-easy,1-med,2-hard
    topic_mastery = Column(Float, default=0.0)
    attempts = Column(Integer, default=0)
    recent_improvement = Column(Float, default=0.0)

    performance_history = relationship("PerformanceHistory", back_populates="student")
    permissions = relationship("StudentPermission", back_populates="student", uselist=False)
