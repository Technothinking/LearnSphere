# rl_model/config/env_config.py

class EnvConfig:
    """
    Environment configuration for the real-student RL setup.
    Defines state/action space and constraints.
    """

    # Environment settings
    MAX_QUESTIONS_PER_QUIZ = 10
    MAX_STEPS_PER_EPISODE = 50
    START_DIFFICULTY = 0  # 0 = easy, 1 = medium, 2 = hard
    MAX_DIFFICULTY = 2
    MIN_DIFFICULTY = 0

    # Observation space (state vector length)
    STATE_DIM = 6  # avg_accuracy, avg_time, difficulty, mastery, attempts, recent_improvement

    # Reward tuning parameters
    CORRECT_ANSWER_REWARD = 1.0
    INCORRECT_ANSWER_PENALTY = -0.5
    IMPROVEMENT_BONUS = 0.5
    TIME_EFFICIENCY_BONUS = 0.3
    FAILURE_STREAK_PENALTY = -1.0

    # Action space
    ACTIONS = 5  # 0: easy, 1: medium, 2: hard, 3: revise, 4: advance
