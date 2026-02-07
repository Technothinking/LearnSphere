import numpy as np
from sqlalchemy.orm import Session
from stable_baselines3 import PPO

from app.core.config import settings
from app.models.rl_transition import RLTransition
from app.utils.state_encoder import StudentStateEncoder
from app.utils.action_mask import get_allowed_actions

class RLService:
    def __init__(self):
        try:
            self.model = PPO.load(settings.PPO_MODEL_PATH)
        except Exception as e:
            print(f"Warning: RL Model not found at {settings.PPO_MODEL_PATH}. Using rule-based fallback.")
            self.model = None
        self.encoder = StudentStateEncoder()

    def select_action(self, student_state: dict):
        if self.model:
            state_vec = self.encoder.encode(student_state)
            action, _ = self.model.predict(state_vec, deterministic=True)
            
            # Apply Action Masking
            allowed = get_allowed_actions(student_state)
            if allowed[int(action)] == 0:
                # Fallback to the first allowed action (usually Easy Practice)
                valid_indices = [i for i, x in enumerate(allowed) if x == 1]
                if valid_indices:
                    action = valid_indices[0]
            
            return int(action)
        else:
            # Rule-based fallback
            accuracy = student_state.get("avg_accuracy_last_5", 0.0)
            if accuracy > 0.8:
                return 3 # Med Adv
            elif accuracy < 0.4:
                return 0 # Easy Revise
            else:
                return 1 # Easy Test

    def log_transition(
        self,
        db: Session,
        student_id: str,
        prev_state: dict,
        action: int,
        reward: float,
        next_state: dict
    ):
        transition = RLTransition(
            student_id=student_id,

            s_accuracy=prev_state["avg_accuracy_last_5"],
            s_time=prev_state["avg_time_per_question"],
            s_difficulty=prev_state["current_difficulty"],
            s_mastery=prev_state["topic_mastery"],
            s_attempts=prev_state["attempts"],
            s_improvement=prev_state["recent_improvement"],

            action=action,
            reward=reward,

            ns_accuracy=next_state["avg_accuracy_last_5"],
            ns_time=next_state["avg_time_per_question"],
            ns_difficulty=next_state["current_difficulty"],
            ns_mastery=next_state["topic_mastery"],
            ns_attempts=next_state["attempts"],
            ns_improvement=next_state["recent_improvement"]
        )

        db.add(transition)
        db.commit()
