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

ACTION_SPACE_SIZE = len(ACTION_MAP)
