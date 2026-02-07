# rl_model/model/policy_loader.py
from stable_baselines3 import PPO
from rl_model.config.ppo_config import PPOConfig

def load_model(path: str = None):
    """
    Load PPO model from file or create a new one.
    """
    if path:
        model = PPO.load(path)
    else:
        from stable_baselines3.common.env_util import DummyVecEnv
        import gym
        # Placeholder env for initialization; replaced in real usage
        dummy_env = DummyVecEnv([lambda: gym.make('CartPole-v1')])
        model = PPO("MlpPolicy", dummy_env, **PPOConfig.to_dict())
    return model

def save_model(model: PPO, path: str):
    """
    Save PPO model to file.
    """
    model.save(path)
