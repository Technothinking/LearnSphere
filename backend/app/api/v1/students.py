from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from app.core.database import supabase

router = APIRouter()

class StudentCreate(BaseModel):
    student_id: str
    grade: int
    full_name: Optional[str] = None
    email: Optional[str] = None

@router.post("/")
def create_student(student: StudentCreate):
    student_id = student.student_id
    grade = student.grade
    full_name = student.full_name
    email = student.email

    print(f"DEBUG: Initializing student {student_id} (Grade: {grade}, Name: {full_name}, Email: {email})")

    # 1. Initialize 'students' table
    try:
        supabase.table("students").upsert({
            "id": student_id,
            "email": email or f"{student_id}@student.edu",
            "grade": grade,
        }).execute()
    except Exception as e:
        print(f"ERROR: Supabase 'students' table initialization failed: {e}")

    # 2. Initialize 'student_data' table
    try:
        student_record = {
            "id": student_id,
            "name": full_name or f"Student {student_id[:8]}",
            "standard": str(grade), 
            "email": email or f"{student_id}@student.edu"
        }
        supabase.table("student_data").upsert(student_record).execute()
    except Exception as e:
        # This table might be missing in some environments, log but don't crash
        print(f"WARNING: Supabase 'student_data' initialization failed: {e}")
    
    # 3. Profiles table for backward compatibility
    try:
        supabase.table("profiles").upsert(student_record).execute()
    except Exception as e:
        print(f"WARNING: Supabase 'profiles' initialization failed: {e}")

    # 4. Initialize 'rl_states' table
    try:
        rl_data = {
            "student_id": student_id,
            "topic_mastery": 0.0,
            "avg_accuracy_last_5": 0.0,
            "total_attempts": 0,
            "current_difficulty_index": 0
        }
        supabase.table("rl_states").upsert(rl_data).execute()
    except Exception as e:
        print(f"ERROR: Supabase 'rl_states' initialization failed: {e}")

    # 5. Initialize 'student_permissions' table
    try:
        supabase.table("student_permissions").upsert({
            "student_id": student_id,
            "has_taken_diagnostic": True,
            "completed_chapters": "[]"
        }).execute()
    except Exception as e:
        print(f"ERROR: Supabase 'student_permissions' initialization failed: {e}")
    
    return {"status": "success", "message": "Student profile synchronized", "student_id": student_id}


@router.get("/{student_id}")
def get_student(student_id: str):
    response = supabase.table("profiles").select("*").eq("id", student_id).execute()
    if not response.data:
        raise HTTPException(status_code=404, detail="Student not found")
    return response.data[0]


@router.put("/{student_id}/performance")
def update_performance(student_id: str, performance: dict):
    """
    Update performance in Supabase rl_states table
    """
    # Fetch current state
    response = supabase.table("rl_states").select("*").eq("student_id", student_id).execute()
    if not response.data:
        raise HTTPException(status_code=404, detail="Student RL state not found")
    
    student_state = response.data[0]
    
    # Update values
    update_data = {
        "avg_accuracy_last_5": performance.get("accuracy", student_state["avg_accuracy_last_5"]),
        "topic_mastery": performance.get("topic_mastery", student_state["topic_mastery"]),
        "total_attempts": student_state["total_attempts"] + 1
    }
    
    res = supabase.table("rl_states").update(update_data).eq("student_id", student_id).execute()
    return {"message": "Performance updated in Supabase"}
