# rl_model/inference/decision_engine.py
import numpy as np
from rl_model.model.ppo_agent import PPOAgent
from rl_model.env.student_env import StudentEnv
from rl_model.utils.action_mask import get_allowed_actions
from rl_model.utils.normalizer import normalize_state

class DecisionEngine:
    """
    Inference engine to get next PPO action for a student.
    """

    def __init__(self, db_session):
        self.db = db_session
        self.agent = PPOAgent()             # Loads pre-trained PPO
        self.env = StudentEnv(db_session)

    def predict_next_quiz(self, student_obj, performance: dict = None):
        """
        Predicts the next quiz action for a student.
        Args:
            student_obj: SQLAlchemy Student object
            performance (dict, optional): last quiz outcome, used for reward and logging
        Returns:
            quiz_meta (dict): {"difficulty": int, "mode": str} for next quiz
        """
        # Step 1: Encode current student state as dict
        state_dict = {
            "avg_accuracy_last_5": student_obj.avg_accuracy_last_5,
            "avg_time_per_question": student_obj.avg_time_per_question,
            "current_difficulty": student_obj.current_difficulty,
            "topic_mastery": student_obj.topic_mastery,
            "attempts": student_obj.attempts,
            "recent_improvement": student_obj.recent_improvement
        }

        # Normalize state
        state_vec = normalize_state(state_dict)

        # Step 2: Get allowed actions (action mask)
        mask = get_allowed_actions(state_dict)

        # Step 3: PPO predicts action (deterministic)
        action_index = self.agent.predict(state_vec, mask=mask)

        # Step 4: If performance provided, log transition & compute reward
        if performance:
            next_state, reward, quiz_meta = self.env.step(student_obj, action_index, performance)
            # Normally, you would call RLService.log_transition here
            return quiz_meta
        else:
            # Just return the next action metadata
            from rl_model.data.action_mapper import map_action_to_quiz
            return map_action_to_quiz(action_index)
