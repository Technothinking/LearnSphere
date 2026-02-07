# rl_model/model/ppo_agent.py
import numpy as np
from stable_baselines3 import PPO
from rl_model.utils.state_encoder import StudentStateEncoder
from rl_model.config.ppo_config import settings
from rl_model.model.policy_loader import load_model

class PPOAgent:
    """
    PPO agent wrapper for real student inference.
    """

    def __init__(self):
        # Load pre-trained PPO
        self.model: PPO = load_model(settings.PPO_MODEL_PATH)
        self.encoder = StudentStateEncoder()

    def predict(self, state_vec: np.ndarray, mask: list = None) -> int:
        """
        Predict action from state vector.
        Optionally applies an action mask.
        """
        # Add batch dimension for SB3
        state_vec = np.array(state_vec, dtype=np.float32).reshape(1, -1)

        # PPO predicts raw action
        action, _ = self.model.predict(state_vec, deterministic=True)
        action = int(action[0] if isinstance(action, (list, np.ndarray)) else action)

        # Apply action mask if provided
        if mask is not None:
            allowed_actions = [i for i, m in enumerate(mask) if m == 1]
            if not allowed_actions:
                action = 0  # fallback if no allowed action
            elif action not in allowed_actions:
                action = allowed_actions[0]  # fallback to first allowed

        # Optional: debug log
        # print(f"[RL] Predicted action: {action}, Mask: {mask}")

        return action
