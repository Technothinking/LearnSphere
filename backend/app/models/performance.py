from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base

class PerformanceHistory(Base):
    __tablename__ = "performance_history"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(String, ForeignKey("students.id"), index=True)
    content_id = Column(String, nullable=True) # Optional, if linking to specific question ID
    
    # Core Metrics
    accuracy = Column(Float, nullable=False)
    time_spent = Column(Float, default=0.0) # In seconds
    difficulty_level = Column(Integer, default=0) # 0=Easy, 1=Med, 2=Hard
    
    # Context
    chapter = Column(String, nullable=True)
    subtopic = Column(String, nullable=True) # or 'topic'
    
    # RL Specifics
    reward_score = Column(Float, default=0.0) # +2, +1, -1, +0.5
    outcome = Column(String, nullable=True) # ADVANCE, RETRY, COMPLETE
    
    timestamp = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    student = relationship("Student", back_populates="performance_history")
