from sqlalchemy import Column, Integer, String, Float
from app.core.database import Base

class RLTransition(Base):
    __tablename__ = "rl_transitions"

    id = Column(Integer, primary_key=True, index=True)

    student_id = Column(String, index=True)

    # State (flattened for simplicity)
    s_accuracy = Column(Float)
    s_time = Column(Float)
    s_difficulty = Column(Integer)
    s_mastery = Column(Float)
    s_attempts = Column(Integer)
    s_improvement = Column(Float)

    action = Column(Integer)
    reward = Column(Float)

    # Next state
    ns_accuracy = Column(Float)
    ns_time = Column(Float)
    ns_difficulty = Column(Integer)
    ns_mastery = Column(Float)
    ns_attempts = Column(Integer)
    ns_improvement = Column(Float)
