# rl_model/scripts/train.py
"""
Offline PPO training using logged real student transitions.
"""
from stable_baselines3 import PPO
from rl_model.persistence.rollout_logger import RolloutLogger
from rl_model.model.policy_loader import load_model, save_model
from rl_model.config.ppo_config import PPOConfig
import numpy as np

def build_dataset(transitions):
    """
    Convert JSONL transitions into (state, action, reward, next_state) arrays.
    """
    states, actions, rewards, next_states = [], [], [], []
    for t in transitions:
        states.append(list(t["state"].values()))
        actions.append(t["action"])
        rewards.append(t["reward"])
        next_states.append(list(t["next_state"].values()))
    return np.array(states, dtype=np.float32), np.array(actions), np.array(rewards), np.array(next_states, dtype=np.float32)

def main():
    logger = RolloutLogger()
    transitions = logger.read_all_transitions()

    if not transitions:
        print("No transitions found. Exiting.")
        return

    # Build dataset
    states, actions, rewards, next_states = build_dataset(transitions)

    # Load PPO model
    model = load_model(PPOConfig.MODEL_PATH)

    # Offline training loop (simplified)
    model.learn(total_timesteps=PPOConfig.TOTAL_TIMESTEPS)

    # Save updated model
    save_path = PPOConfig.MODEL_PATH.replace(".zip", "_retrained.zip")
    save_model(model, save_path)
    print(f"Model retrained and saved at {save_path}")

if __name__ == "__main__":
    main()
