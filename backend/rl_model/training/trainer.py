# rl_model/training/trainer.py
"""
Offline PPO training using real student transitions from RolloutLogger.
"""
import numpy as np
from stable_baselines3 import PPO
from rl_model.persistence.rollout_logger import RolloutLogger
from rl_model.model.policy_loader import load_model, save_model
from rl_model.config.ppo_config import PPOConfig
from rl_model.training.callbacks import TrainingCallback
from rl_model.utils.normalizer import normalize_state

def prepare_dataset(transitions):
    """
    Convert list of transitions into states, actions, rewards.
    Normalize states for PPO.
    """
    states, actions, rewards = [], [], []

    for t in transitions:
        s = normalize_state(t["state"])
        ns = normalize_state(t["next_state"])
        states.append(s)
        actions.append(t["action"])
        rewards.append(t["reward"])
    
    return np.array(states, dtype=np.float32), np.array(actions), np.array(rewards, dtype=np.float32)

def main():
    logger = RolloutLogger()
    transitions = logger.read_all_transitions()

    if not transitions:
        print("No transitions found. Exiting trainer.")
        return

    states, actions, rewards = prepare_dataset(transitions)
    print(f"Loaded {len(states)} transitions for training.")

    # Load or initialize PPO model
    model = load_model(PPOConfig.MODEL_PATH)

    # Define callback for logging & checkpoints
    callback = TrainingCallback(save_freq=PPOConfig.CHECKPOINT_FREQ)

    # Offline training (learning from transitions)
    print("Starting PPO training...")
    model.learn(
        total_timesteps=PPOConfig.TOTAL_TIMESTEPS,
        callback=callback,
        reset_num_timesteps=False
    )

    # Save final trained model
    save_model(model, PPOConfig.MODEL_PATH.replace(".zip", "_trained.zip"))
    print(f"Training completed. Model saved at {PPOConfig.MODEL_PATH.replace('.zip','_trained.zip')}")

if __name__ == "__main__":
    main()
