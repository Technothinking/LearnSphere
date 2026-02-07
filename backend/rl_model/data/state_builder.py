# rl_model/data/state_builder.py
from app.models.student import Student
import numpy as np

def build_state_vector(student: Student) -> np.ndarray:
    """
    Convert a Student model object into PPO-compatible state vector.
    Matches StudentStateEncoder.
    
    State vector layout:
    [avg_accuracy_last_5, avg_time_per_question, current_difficulty,
     topic_mastery, attempts, recent_improvement]
    """
    return np.array([
        student.avg_accuracy_last_5,
        student.avg_time_per_question,
        student.current_difficulty,
        student.topic_mastery,
        student.attempts,
        student.recent_improvement
    ], dtype=np.float32)
