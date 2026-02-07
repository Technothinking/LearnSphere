# rl_model/persistence/model_store.py
import os
from stable_baselines3 import PPO

class ModelStore:
    """
    Handles saving and loading PPO models for the real-student environment.
    """

    def __init__(self, save_dir="rl_model_storage"):
        self.save_dir = save_dir
        os.makedirs(self.save_dir, exist_ok=True)

    def save_model(self, model: PPO, name: str):
        """
        Save PPO model weights.
        """
        path = os.path.join(self.save_dir, f"{name}.zip")
        model.save(path)
        return path

    def load_model(self, name: str) -> PPO:
        """
        Load PPO model weights.
        """
        path = os.path.join(self.save_dir, f"{name}.zip")
        if not os.path.exists(path):
            raise FileNotFoundError(f"Model file not found: {path}")
        return PPO.load(path)
