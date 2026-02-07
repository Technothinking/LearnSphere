# rl_model/data/action_mapper.py

# ACTION INDEX MAPPING
# 0 → Easy questions
# 1 → Medium questions
# 2 → Hard questions
# 3 → Revise topic
# 4 → Advance to next topic
ACTION_MAP = {
    0: {"difficulty": 0, "mode": "practice"},
    1: {"difficulty": 1, "mode": "practice"},
    2: {"difficulty": 2, "mode": "practice"},
    3: {"difficulty": 0, "mode": "revise"},
    4: {"difficulty": 1, "mode": "advance"}
}

def map_action_to_quiz(action: int) -> dict:
    """
    Converts PPO action index to quiz difficulty and mode metadata.
    
    Args:
        action (int): PPO action (0-4)
    
    Returns:
        dict: {"difficulty": int, "mode": str}
    """
    if action not in ACTION_MAP:
        raise ValueError(f"Invalid action {action}. Must be 0-4.")
    
    return ACTION_MAP[action]
