# rl_model/config/__init__.py

from .env_config import EnvConfig
from .ppo_config import PPOConfig

# Optional: centralized settings object
class Settings:
    env = EnvConfig()
    ppo = PPOConfig()

settings = Settings()