# log_sample_transitions.py
from rl_model.persistence.rollout_logger import RolloutLogger

logger = RolloutLogger()

# Example transitions
sample_transitions = [
    {
        "student_id": "stu_001",
        "state": {"avg_accuracy_last_5": 0.6, "avg_time_per_question": 30,
                  "current_difficulty": 1, "topic_mastery": 0.7, "attempts": 5, "recent_improvement": 0.1},
        "action": 2,
        "reward": 0.8,
        "next_state": {"avg_accuracy_last_5": 0.65, "avg_time_per_question": 28,
                       "current_difficulty": 2, "topic_mastery": 0.72, "attempts": 6, "recent_improvement": 0.05}
    },
    {
        "student_id": "stu_002",
        "state": {"avg_accuracy_last_5": 0.4, "avg_time_per_question": 40,
                  "current_difficulty": 0, "topic_mastery": 0.5, "attempts": 2, "recent_improvement": 0.0},
        "action": 0,
        "reward": 0.3,
        "next_state": {"avg_accuracy_last_5": 0.42, "avg_time_per_question": 38,
                       "current_difficulty": 0, "topic_mastery": 0.52, "attempts": 3, "recent_improvement": 0.02}
    }
]

# Log transitions
for t in sample_transitions:
    logger.log_transition(t)

print("Sample transitions logged!")
