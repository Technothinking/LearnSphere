from sqlalchemy.orm import Session
from app.models.student import Student
from app.core.database import supabase

def get_student(db: Session, student_id: str):
    # Try Local Cache
    student = db.query(Student).filter(Student.id == student_id).first()
    if student:
        return student
        
    # Try Supabase (Cloud Source of Truth)
    try:
        res = supabase.table("students").select("*").eq("id", student_id).execute()
        if res.data:
            data = res.data[0]
            # Backfill Local Cache
            student = Student(
                id=data['id'],
                email=data.get('email'),
                grade=data.get('grade', 9),
                attempts=data.get('attempts', 0)
                # Add other fields if synced
            )
            db.add(student)
            db.commit()
            db.refresh(student)
            return student
    except Exception as e:
        print(f"Supabase student fetch error: {e}")
        
    return None


def get_student_by_email(db: Session, email: str):
    return db.query(Student).filter(Student.email == email).first()


def create_student(db: Session, student_id: str, email: str, grade: int):
    # 1. Create in Supabase (Source of Truth)
    try:
        supabase.table("students").upsert({
            "id": student_id,
            "email": email,
            "grade": grade,
            "created_at": "now()" # Let DB handle or pass explicit
        }).execute()
    except Exception as e:
        print(f"Supabase create error: {e}")

    # 2. Create Local Cache
    student = Student(id=student_id, email=email, grade=grade)
    db.add(student)
    db.commit()
    db.refresh(student)
    return student


def update_student_state(db: Session, student: Student, performance: dict):
    prev_accuracy = student.avg_accuracy_last_5

    new_acc = performance.get("accuracy", 0.0)
    student.avg_accuracy_last_5 = (prev_accuracy * 0.8) + (new_acc * 0.2)
    
    new_time = performance.get("avg_time", student.avg_time_per_question)
    student.avg_time_per_question = (student.avg_time_per_question * 0.8) + (new_time * 0.2)

    student.topic_mastery = performance.get(
        "topic_mastery", student.topic_mastery
    )

    student.attempts += 1
    raw_improvement = student.avg_accuracy_last_5 - prev_accuracy
    student.recent_improvement = max(-1.0, min(1.0, raw_improvement))

    db.commit()
    db.refresh(student)
    return student


def update_student_difficulty(db: Session, student_id: str, new_difficulty: int):
    student = get_student(db, student_id)
    if student:
        student.current_difficulty = new_difficulty
        db.commit()
        db.refresh(student)
    return student
