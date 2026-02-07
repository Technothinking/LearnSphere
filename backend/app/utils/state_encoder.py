import numpy as np

class StudentStateEncoder:
    def __init__(self):
        self.state_dim = 6

    def encode(self, state: dict) -> np.ndarray:
        return np.array([
            state["avg_accuracy_last_5"],
            state["avg_time_per_question"],
            state["current_difficulty"],
            state["topic_mastery"],
            state["attempts"],
            state["recent_improvement"]
        ], dtype=np.float32)
