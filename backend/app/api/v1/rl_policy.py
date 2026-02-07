from fastapi import APIRouter, HTTPException
import numpy as np
from stable_baselines3 import PPO

# Import from existing modules
from app.utils.state_encoder import StudentStateEncoder
from app.utils.action_mask import get_allowed_actions
from app.core.database import supabase

router = APIRouter()

# Load PPO model
try:
    model = PPO.load("rl_model/models/ppo_adaptive_learning.zip")
except Exception:
    model = None

state_encoder = StudentStateEncoder()

ACTION_MAP = {
    0: {"difficulty": "easy", "mode": "revise", "label": "Review Basics"},
    1: {"difficulty": "easy", "mode": "test", "label": "Starter Quiz"},
    2: {"difficulty": "medium", "mode": "test", "label": "Progressive Quiz"},
    3: {"difficulty": "medium", "mode": "advance", "label": "Challenge Level"},
    4: {"difficulty": "hard", "mode": "advance", "label": "Mastery Challenge"},
    5: {"difficulty": "medium", "mode": "common_test", "label": "Full Chapter Challenge"},
}

@router.get("/next-action/{student_id}")
def get_next_action(student_id: str):
    """
    Fetches student data from Supabase and uses PPO model to predict the next best learning action.
    """
    # Fetch student RL state from Supabase
    response = supabase.table("rl_states").select("*").eq("student_id", student_id).execute()
    if not response.data:
        raise HTTPException(status_code=404, detail="Student state not found. Please initialize student first.")
    
    db_state = response.data[0]
    
    # 1. Check if common test is completed for the current focus chapter
    # (For demo/logic simplicity, we check if the student has taken any common test recorded in permissions)
    perm_res = supabase.table("student_permissions").select("completed_chapters").eq("student_id", student_id).execute()
    has_completed_any = False
    if perm_res.data:
        completed = perm_res.data[0].get("completed_chapters", "[]")
        if isinstance(completed, str):
            import json
            completed = json.loads(completed)
        if len(completed) > 0:
            has_completed_any = True
            
    # If no common test completed yet, override and suggest it first
    if not has_completed_any:
        return {
            "student_id": student_id,
            "recommended_action": ACTION_MAP[5],
            "state_snapshot": db_state,
            "message": "Complete your first Full Chapter Challenge to unlock adaptive learning!"
        }

    # Map Supabase state to the format expected by utils (Encoder & Action Mask)
    # Adding defaults for fields not currently in DB to prevent breakage
    student_data = {
        "avg_accuracy_last_5": db_state.get("avg_accuracy_last_5", 0.0),
        "topic_mastery": db_state.get("topic_mastery", 0.0),
        "attempts": db_state.get("total_attempts", 0),
        "current_difficulty": db_state.get("current_difficulty_index", 0),
        "avg_time_per_question": db_state.get("avg_time_per_question", 20.0), # Use DB value, fallback to 20
        "recent_improvement": 0.0      # Defaulting for now
    }

    # Encode state for PPO
    state = state_encoder.encode(student_data)
    
    # PPO inference
    if model:
        action_id, _ = model.predict(state, deterministic=True)
        action_id = int(action_id)
    else:
        # Fallback logic if model is not trained yet (Rule-based)
        if student_data["avg_accuracy_last_5"] > 0.8:
            action_id = 3 # Advance Medium
        elif student_data["avg_accuracy_last_5"] < 0.4:
            action_id = 0 # Revise Easy
        else:
            action_id = 1 # Test Easy

    # Action Masking (Safety check)
    allowed_mask = get_allowed_actions(student_data)
    if not allowed_mask[action_id]:
        # Fallback to first allowed action
        for idx, is_allowed in enumerate(allowed_mask):
            if is_allowed:
                action_id = idx
                break

    return {
        "student_id": student_id,
        "recommended_action": ACTION_MAP[action_id],
        "state_snapshot": student_data
    }
