# rl_model/utils/normalizer.py
"""
Normalize numeric values of student states for PPO input.
"""

import numpy as np

# Define normalization ranges
STATE_RANGES = {
    "avg_accuracy_last_5": (0.0, 1.0),
    "avg_time_per_question": (0.0, 300.0),  # e.g., seconds
    "current_difficulty": (0, 2),
    "topic_mastery": (0.0, 1.0),
    "attempts": (0, 100),
    "recent_improvement": (-1.0, 1.0),
}

def normalize_state(state: dict) -> np.ndarray:
    """
    Normalize state dictionary into 0-1 range array.
    """
    normalized = []
    for key, (min_val, max_val) in STATE_RANGES.items():
        value = state.get(key, 0.0)
        # Clip to range
        value = max(min_val, min(value, max_val))
        # Normalize
        norm_value = (value - min_val) / (max_val - min_val)
        normalized.append(norm_value)
    return np.array(normalized, dtype=np.float32)
