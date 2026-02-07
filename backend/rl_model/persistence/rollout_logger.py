# rl_model/persistence/rollout_logger.py
import os
import json
from datetime import datetime

class RolloutLogger:
    """
    Logs real student transitions (state, action, reward, next_state) for offline RL training.
    """

    def __init__(self, log_dir="rollouts"):
        self.log_dir = log_dir
        os.makedirs(self.log_dir, exist_ok=True)
        self.filepath = os.path.join(self.log_dir, "transitions.jsonl")

    def log_transition(self, transition: dict):
        """
        Append a single transition to the log file.
        Transition example:
        {
            "student_id": "s123",
            "state": {...},
            "action": 2,
            "reward": 0.8,
            "next_state": {...},
            "timestamp": "2026-01-28T13:00:00"
        }
        """
        transition["timestamp"] = datetime.utcnow().isoformat()
        with open(self.filepath, "a") as f:
            f.write(json.dumps(transition) + "\n")

    def read_all_transitions(self):
        """
        Read all logged transitions.
        Returns a list of dictionaries.
        """
        if not os.path.exists(self.filepath):
            return []

        transitions = []
        with open(self.filepath, "r") as f:
            for line in f:
                transitions.append(json.loads(line.strip()))
        return transitions
