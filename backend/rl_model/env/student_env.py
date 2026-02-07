# rl_model/env/student_env.py
from rl_model.data.state_builder import build_state_vector
from rl_model.data.action_mapper import map_action_to_quiz
from rl_model.env.reward import compute_reward
from app.models.student import Student
from app.services.student_service import update_student_state

class StudentEnv:
    """
    Real student environment for PPO inference & logging.
    """

    def __init__(self, db_session):
        self.db = db_session

    def step(self, student: Student, action: int, performance: dict):
        """
        Apply PPO action to the student environment, update state, and compute reward.

        Args:
            student (Student): SQLAlchemy student object
            action (int): PPO action index
            performance (dict): actual performance after quiz attempt
        
        Returns:
            next_state (np.ndarray): next state vector
            reward (float): computed reward
        """
        # Previous state
        prev_state = {
            "avg_accuracy_last_5": student.avg_accuracy_last_5,
            "avg_time_per_question": student.avg_time_per_question,
            "current_difficulty": student.current_difficulty,
            "topic_mastery": student.topic_mastery,
            "attempts": student.attempts,
            "recent_improvement": student.recent_improvement
        }

        # Update student state in DB
        student = update_student_state(self.db, student, performance)

        # Compute reward
        reward = compute_reward(prev_state, performance)

        # Build next state
        next_state = build_state_vector(student)

        # Map action → quiz metadata (optional, for logging or next quiz)
        quiz_meta = map_action_to_quiz(action)

        return next_state, reward, quiz_meta
