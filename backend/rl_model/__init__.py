# rl_model/__init__.py
"""
rl_model package

This package contains all modules required for:
- Real student PPO environment
- Offline training and inference
- State encoding, normalization, and validation
- Model persistence and logging
"""

# Expose key submodules for easy import
from .config import ppo_config, env_config
from .data import state_builder, action_mapper
from .env import student_env, reward
from .model import ppo_agent, policy_loader
from .inference import decision_engine
from .persistence import model_store, rollout_logger
from .utils import normalizer, validators
from .training import trainer, callbacks

# Optional: define top-level version
__version__ = "1.0.0"
