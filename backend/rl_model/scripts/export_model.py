# rl_model/scripts/export_model.py
"""
Export PPO model to production-ready path.
"""
from rl_model.model.policy_loader import load_model, save_model
from rl_model.config.ppo_config import PPOConfig

def main():
    model = load_model(PPOConfig.MODEL_PATH)
    save_path = PPOConfig.MODEL_EXPORT_PATH
    save_model(model, save_path)
    print(f"PPO model exported for production at {save_path}")

if __name__ == "__main__":
    main()
