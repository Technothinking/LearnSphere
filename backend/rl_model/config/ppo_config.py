# rl_model/config/ppo_config.py

class PPOConfig:
    """
    PPO hyperparameters for real-student adaptive learning.
    """

    # Training parameters
    LEARNING_RATE = 0.0003
    GAMMA = 0.99  # discount factor
    N_STEPS = 2048
    BATCH_SIZE = 64
    N_EPOCHS = 10
    CLIP_RANGE = 0.2

    # Exploration / policy
    ENT_COEF = 0.01  # entropy bonus
    VF_COEF = 0.5    # value function loss coefficient
    MAX_GRAD_NORM = 0.5

    # PPO model paths
    MODEL_PATH = "rl_model/persistence/ppo_model"
    LOG_PATH = "rl_model/persistence/logs"

    # Misc
    VERBOSE = 1
    SEED = 42
