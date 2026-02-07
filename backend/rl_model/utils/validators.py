# rl_model/utils/validators.py
"""
Safety checks on student state or PPO inputs.
"""

def validate_state(state: dict) -> bool:
    """
    Checks that all required state keys exist and values are within reasonable bounds.
    Returns True if valid, False otherwise.
    """
    required_keys = [
        "avg_accuracy_last_5",
        "avg_time_per_question",
        "current_difficulty",
        "topic_mastery",
        "attempts",
        "recent_improvement"
    ]

    for key in required_keys:
        if key not in state:
            print(f"Validation error: missing key {key}")
            return False

        value = state[key]
        if key in ["avg_accuracy_last_5", "topic_mastery", "recent_improvement"] and not (-1.0 <= value <= 1.0):
            print(f"Validation error: {key} out of range {value}")
            return False
        if key == "avg_time_per_question" and not (0 <= value <= 300):
            print(f"Validation error: {key} out of range {value}")
            return False
        if key == "current_difficulty" and not (0 <= value <= 2):
            print(f"Validation error: {key} out of range {value}")
            return False
        if key == "attempts" and value < 0:
            print(f"Validation error: {key} negative value {value}")
            return False

    return True
