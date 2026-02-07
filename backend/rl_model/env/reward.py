# rl_model/env/reward.py

def compute_reward(previous_state: dict, performance: dict) -> float:
    """
    Converts student outcome into a numeric reward for PPO.
    Args:
        previous_state (dict): previous student state
        performance (dict): actual performance from quiz attempt
    Returns:
        float: reward
    """
    reward = 0.0

    # Correctness
    reward += 1.0 if performance.get("correct", False) else -0.5

    # Accuracy improvement
    if performance.get("accuracy", 0) > previous_state.get("avg_accuracy_last_5", 0):
        reward += 0.5

    # Time efficiency
    if performance.get("avg_time", 999) < previous_state.get("avg_time_per_question", 999):
        reward += 0.3

    # Penalty for repeated failure
    if performance.get("failure_streak", 0) >= 3:
        reward -= 1.0

    # Clip reward to [-1, 1] to stabilize PPO
    reward = max(-1.0, min(reward, 1.0))

    return reward
