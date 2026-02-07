def get_allowed_actions(student_state: dict):
    allowed = [1] * 5

    # Cannot advance if mastery is low
    if student_state["topic_mastery"] < 0.6:
        allowed[4] = 0

    # Prevent hard questions for beginners
    if student_state["avg_accuracy_last_5"] < 0.4:
        allowed[2] = 0

    # Force revision after repeated failures
    if student_state["recent_improvement"] < -0.2:
        allowed[3] = 1

    return allowed
