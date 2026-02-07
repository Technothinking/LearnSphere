def compute_reward(previous_state: dict, performance: dict) -> float:
    reward = 0.0

    # Correctness
    reward += 1.0 if performance["correct"] else -0.5

    # Accuracy improvement
    if performance["accuracy"] > previous_state["avg_accuracy_last_5"]:
        reward += 0.5

    # Time efficiency
    if performance["avg_time"] < previous_state["avg_time_per_question"]:
        reward += 0.3

    # Repeated failure penalty
    if performance["failure_streak"] >= 3:
        reward -= 1.0

    return reward
