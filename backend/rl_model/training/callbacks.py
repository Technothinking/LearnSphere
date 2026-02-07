# rl_model/training/callbacks.py
"""
Custom callback for PPO training:
- Logs episode rewards
- Saves model checkpoints periodically
"""

from stable_baselines3.common.callbacks import BaseCallback
from rl_model.model.policy_loader import save_model
from rl_model.config.ppo_config import PPOConfig

class TrainingCallback(BaseCallback):
    def __init__(self, save_freq=10000, verbose=1):
        super().__init__(verbose)
        self.save_freq = save_freq
        self.step_count = 0

    def _on_step(self) -> bool:
        self.step_count += 1

        if self.step_count % self.save_freq == 0:
            save_path = PPOConfig.MODEL_PATH.replace(".zip", f"_step{self.step_count}.zip")
            save_model(self.model, save_path)
            if self.verbose > 0:
                print(f"[Callback] Model checkpoint saved at step {self.step_count}: {save_path}")
        return True
