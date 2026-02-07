from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import supabase, SessionLocal, get_db
from app.schemas.quiz_schema import AdaptiveTestSubmission, AdaptiveTestResponse
from app.models.attempt import Attempt
from app.models.mastery import SubtopicMastery
from app.models.performance import PerformanceHistory
from app.models.permission import StudentPermission
from app.services.student_service import get_student, update_student_difficulty, get_student_by_email, update_student_state
from app.services.rl_service import RLService
from app.services.reward_service import compute_reward
import random
import json
import time
import re
from collections import defaultdict

router = APIRouter()
rl_service = RLService()

# Map UI chapter names (from textbook table) to actual database chapter names.
# This handles differences in punctuation, casing, and underscores.
CHAPTER_NAME_MAP = {
    "Acids, Bases and Salts": "Acids Bases and Salts",
    "Acids, Bases And Salts": "Acids Bases and Salts",
    "Carbon: An Important Element": "Carbon: An Important Element",
    "Classification Of Plants": "Classification of Plants",
    "Classification of Plants": "Classification of Plants",
    "Current Electricity": "Current Electricity",
    "Currently Electricity": "Current Electricity", 
    "Energy Flow In Ecosystem": "Energy Flow In Ecosystem",
    "Introduction To Biotechnology": "Introduction to Biotechnology",
    "Introduction to Biotechnology": "Introduction to Biotechnology",
    "Laws Of Motion": "Laws of Motion",
    "Laws of Motion": "Laws of Motion",
    "Motion": "Laws of Motion", 
    "Life Processes In Living Organisms": "Life Processes in Living Organisms",
    "Life Processes in Living Organisms": "Life Processes in Living Organisms",
    "Measurement Of Matter": "Measurement of Matter",
    "Measurement of Matter": "Measurement of Matter",
    "Reflection Of Light": "Reflection of Light",
    "Reflection of Light": "Reflection of Light",
    "Study Of Light": "Study of Light",
    "Study of Light": "Study of Light",
    "Substances In Common Use": "Substances in Common Use",
    "Substances in Common Use": "Substances in Common Use",
    "Useful And Harmful Microbes": "Useful and Harmful Microbes",
    "Useful and Harmful Microbes": "Useful and Harmful Microbes",
    "Work And Energy": "Work and Energy",
    "Work and Energy": "Work and Energy",
}

def normalize_name(name: str) -> str:
    """Normalize string by lowercasing and removing all non-alphanumeric characters."""
    if not name:
        return ""
    return re.sub(r'[^a-z0-9]', '', name.lower())

# Global Cache for Dynamic Chapter Resolution
_DB_CHAPTER_CACHE = {} # { normalized_name: db_exact_name }
_LAST_CACHE_UPDATE = 0

def _refresh_chapter_lookup():
    """Fetch all distinct chapters from common_test_questions and update the lookup map."""
    global _DB_CHAPTER_CACHE, _LAST_CACHE_UPDATE
    
    try:
        # 1. Fetch from common_test_questions
        res = supabase.table("common_test_questions").select("chapter").execute()
        chapters = set()
        if res.data:
            for row in res.data:
                if row.get('chapter'):
                    chapters.add(row['chapter'].strip())
                    
        # 2. Fetch from learning_content (to be safe)
        res_lc = supabase.table("learning_content").select("chapter").execute()
        if res_lc.data:
            for row in res_lc.data:
                if row.get('chapter'):
                    chapters.add(row['chapter'].strip())

        # 3. Update Cache
        new_cache = {}
        for c in chapters:
            norm = normalize_name(c)
            new_cache[norm] = c
            
        _DB_CHAPTER_CACHE = new_cache
        _LAST_CACHE_UPDATE = time.time()
        print(f"DEBUG: Refreshed Chapter Cache with {len(new_cache)} entries.")
        
    except Exception as e:
        print(f"Error refreshing chapter cache: {e}")

# Initial Load (Best Effort)
if not _DB_CHAPTER_CACHE:
    # We can't run this at top-level import time easily without async or blocking
    # We'll lazy load in get_db_chapter
    pass

def get_db_chapter(chapter_name: str) -> str:
    """Resolve UI chapter name to database chapter name using exact map or normalized lookup."""
    if not chapter_name:
        return chapter_name
        
    # 1. Try exact map (current behavior)
    if chapter_name in CHAPTER_NAME_MAP:
        return CHAPTER_NAME_MAP[chapter_name]
        
    # 2. Try normalized map (Dynamic Cache)
    global _DB_CHAPTER_CACHE
    if not _DB_CHAPTER_CACHE:
        _refresh_chapter_lookup()
        
    norm_name = normalize_name(chapter_name)
    if norm_name in _DB_CHAPTER_CACHE:
        return _DB_CHAPTER_CACHE[norm_name]
    
    # Refresh and try one last time if not found
    _refresh_chapter_lookup()
    if norm_name in _DB_CHAPTER_CACHE:
        return _DB_CHAPTER_CACHE[norm_name]
        
    # 3. Fallback to original
    return chapter_name

SUBTOPICS = {
    "Acids ,Bases And Salts": ['Introduction and Initial Classification of Acids, Bases, and Salts'],
    "Acids Bases and Salts": ['Acidic Radical', 'Arrhenius', 'Arrhenius Theory', 'Basic Radical', 'Common Acids', 'Common Bases', 'Concentration', 'Examples', 'Indicators', 'Introduction', 'Litmus Test', 'Neutralization', 'Salts', 'Strength', 'pH', 'pH Calculation', 'pH Scale'],
    "Carbon: An Important Element": ['Allotropy', 'Basics', 'Biogas', 'Carbon Dioxide', 'Coal', 'Covalent Bonds', 'Diamond', 'Fire Extinguisher', 'Fullerene', 'Graphite', 'Hydrocarbons', 'Methane', 'Occurrence', 'Uses'],
    "Classification of Plants": ['Angiosperms', 'Basis of Classification', 'Bryophyta', 'Cryptogams', 'Dicot', 'Gymnosperms', 'Introduction', 'Monocot', 'Pteridophyta', 'Thallophyta'],
    "Current Electricity": ['Battery', 'Conductors', 'Current Basics', 'Current Division', 'Fuse', 'Heating', 'Heating Effect', 'Internal Resistance', "Kirchhoff's Law", "Ohm's Law", 'Parallel', 'Parallel Circuit', 'Parallel Combination', 'Parallel Resistance', 'Power', 'Power Calculation', 'Power Loss', 'Resistance', 'Series', 'Series Circuit', 'Series Combination', 'Series Parallel', 'Superconductor', 'Voltmeter'],
    "Energy Flow In Ecosystem": ['Bio-geo-chemical Cycle', 'Food Chain and Food Web', 'The Carbon Cycle', 'The Energy Pyramid'],
    "Introduction to Biotechnology": ['Applications', 'Basic Concepts', 'Genetic Engineering', 'Uses'],
    "Laws Of Motion": ['Acceleration (including types)', 'Distance and Displacement', 'Distance-Time Graphs', 'Motion (Concept and Definition)', "Newton's Laws of Motion and Related Equations", 'Speed and Velocity', 'Uniform and Non-uniform Linear Motion'],
    "Life Processes in Living Organisms": ['Coordination in Humans', 'Coordination in Plants', 'Excretion in Animals', 'Excretion in Humans', 'Excretion in Plants', 'Transportation in Humans', 'Transportation in Plants'],
    "Measurement of Matter": ['Atom Basics', 'Ions', 'Mole Concept', 'Molecular Mass', 'Radicals', 'Valency'],
    "Reflection of Light": ['Focus & Focal Length', 'Image Formation', 'Image Formation Concave', 'Introduction', 'Laws of Reflection', 'Magnification', 'Mirror Formula', 'Mirrors', 'Plane Mirror', 'Ray Diagrams', 'Regular Irregular Reflection', 'Sign Convention', 'Spherical Mirrors', 'Uses', 'Uses of Mirrors'],
    "Study of Light": ['Human Ear', 'Reflection of Sound', 'Sound Characteristics', 'Sound Waves', 'Uses of Ultrasound', 'Velocity of Sound'],
    "Substances in Common Use": ['Common Salts', 'Common Substances', 'Radioactive Substances'],
    "Useful and Harmful Microbes": ['Benefits', 'Coagulation', 'Count', 'Fermentation', 'Fermentation Effect', 'Harmful Microbes', 'Health', 'Lactobacilli', 'Microbes', 'Microbial Balance', 'Microscope', 'Milk Products', 'Observation', 'Observation Time', 'Probiotics', 'Process', 'Rhizobium', 'Spoilage', 'Yeast', 'Yoghurt', 'Yoghurt Making', 'Yoghurt Problem', 'Yoghurt Spoilage', 'pH Effect'],
    "Work and Energy": ['Conservation', 'Conservation of Energy', 'Efficiency', 'Energy Conversion', 'Energy Forms', 'Energy Types', 'Kinetic Energy', 'Potential Energy', 'Power', 'Spring Energy', 'Variable Force', 'Work Concept', 'Work Done', 'Work Done by Spring'],
}

@router.get("/")
def get_questions(
    difficulty: str = None, 
    subject: str = None, 
    chapter: str = None, 
    topic: str = None, 
    student_id: str = None, 
    limit: int = 25, 
    db: Session = Depends(get_db)
):
    """
    Fetch questions from Supabase (learning_content).
    """
    # If Chapter is requested but Topic is NOT (Full Chapter Test)
    if chapter and not topic:
        # User requirement: questions for every chapter should come from common_test_question table
        db_chapter = get_db_chapter(chapter)
        try:
            res_ct = supabase.table("common_test_questions").select("*").eq("chapter", db_chapter).execute()
            if res_ct.data:
                print(f"DEBUG: Found {len(res_ct.data)} questions in common_test_questions for {chapter}")
                data = res_ct.data
                if len(data) > limit:
                    data = random.sample(data, limit)
                # Parse JSON if needed
                import json as json_lib
                for item in data:
                    if 'data' in item and isinstance(item['data'], str):
                        try:
                            item['data'] = json_lib.loads(item['data'])
                        except:
                            pass
                return data
        except Exception as e:
            print(f"Error fetching from common_test_questions in adaptive path: {e}")

    if chapter and not topic and student_id:
        # Map UI chapter name to database chapter name if needed
        db_chapter = CHAPTER_NAME_MAP.get(chapter, chapter)
        
        # Fetch Subtopics accurately from DB (learning_content)
        subtopics = []
        try:
            res = supabase.table("learning_content").select("topic").eq("chapter", db_chapter).execute()
            subtopics = list(set([item['topic'] for item in res.data if item.get('topic')]))
        except Exception as e:
            print(f"Error fetching dynamic subtopics: {e}")
            
        # Fallback to static if DB fails
        if not subtopics and chapter in SUBTOPICS:
            subtopics = SUBTOPICS[chapter]
        
        if subtopics:
            aggregated_data = []
            q_per_topic = max(1, limit // len(subtopics))
            
            for sub in subtopics:
                # Determine adaptive difficulty per subtopic
                sub_diff = "easy"
                
                # Check DB for mastery
                m_record = db.query(SubtopicMastery).filter(
                    SubtopicMastery.student_id == student_id,
                    SubtopicMastery.chapter == chapter,
                    SubtopicMastery.subtopic == sub
                ).first()
                
                if m_record:
                    if m_record.accuracy > 0.8: sub_diff = "hard"
                    elif m_record.accuracy > 0.5: sub_diff = "medium"
                    else: sub_diff = "easy"
                
                # OVERRIDE: If difficulty is explicitly provided (e.g., by user) use it
                if difficulty:
                    sub_diff = difficulty.lower()

                # Fetch specific to this subtopic
                q = supabase.table("learning_content") \
                    .select("*") \
                    .eq("chapter", db_chapter) \
                    .eq("topic", sub) \
                    .eq("difficulty", sub_diff) \
                    .limit(q_per_topic * 2) \
                    .execute()
                
                subset = q.data
                if len(subset) > q_per_topic:
                     subset = random.sample(subset, q_per_topic)
                aggregated_data.extend(subset)
            
            # If we STILL need more questions (maybe subtopics didn't have enough)
            if len(aggregated_data) < limit:
                needed = limit - len(aggregated_data)
                q_extra = supabase.table("learning_content") \
                    .select("*") \
                    .eq("chapter", db_chapter) \
                    .eq("difficulty", difficulty.lower() if difficulty else "medium") \
                    .limit(needed) \
                    .execute()
                aggregated_data.extend(q_extra.data)

            random.shuffle(aggregated_data)
            if len(aggregated_data) > limit:
                aggregated_data = aggregated_data[:limit]
                
            return aggregated_data
            
    # Standard Logic (Single Topic or Random)
    if not difficulty and student_id:
        if topic:
            # Check Subtopic Mastery level for this specific topic
            m_record = db.query(SubtopicMastery).filter(
                SubtopicMastery.student_id == student_id,
                SubtopicMastery.chapter == chapter,
                SubtopicMastery.subtopic == topic
            ).first()
            if m_record:
                diff_map = {0: "easy", 1: "medium", 2: "hard"}
                difficulty = diff_map.get(m_record.level, "easy")
        
        if not difficulty: # Fallback to global student difficulty
            student = get_student(db, student_id)
            if student:
                diff_map = {0: "easy", 1: "medium", 2: "hard"}
                difficulty = diff_map.get(student.current_difficulty, "medium")
    
    query = supabase.table("learning_content").select("*")
    if difficulty:
        query = query.eq("difficulty", difficulty.lower())
    if subject:
        query = query.eq("subject", subject)
    if chapter:
        query = query.eq("chapter", get_db_chapter(chapter))
    if topic:
        query = query.eq("topic", topic)

    response = query.limit(100).execute()
    data = response.data
    
    if len(data) > limit:
        data = random.sample(data, limit)
        
    return data

@router.get("/common-test")
def get_common_test_questions(
    chapter: str,
    subject: str = None,
    limit: int = 20,
    db: Session = Depends(get_db)
):
    """
    Fetch fixed set of common test questions for a chapter.
    Returns deterministic list of questions.
    """
    try:
        # Map UI chapter name to database chapter name if needed
        db_chapter = get_db_chapter(chapter)
        
        query = supabase.table("common_test_questions") \
            .select("*") \
            .eq("chapter", db_chapter)
            
        if subject:
            query = query.eq("subject", subject)
            
        # Order by ID to ensure fixed order for every student
        response = query.order("id").limit(limit).execute()
        
        if not response.data:
            return []
        
        # Ensure 'data' field is properly parsed (JSONB might come as string)
        import json as json_lib
        for item in response.data:
            if 'data' in item and isinstance(item['data'], str):
                try:
                    item['data'] = json_lib.loads(item['data'])
                except:
                    pass
        
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/check-diagnostic/{student_id}")
def check_diagnostic_status(student_id: str, db: Session = Depends(get_db)):
    """Check if student needs to take diagnostic test - ONLINE ONLY"""
    try:
        # Source of Truth: Supabase student_permissions
        res = supabase.table("student_permissions").select("*").eq("student_id", student_id).execute()
        
        has_taken = False
        completed = []
        
        if res.data:
            data = res.data[0]
            has_taken = data.get("has_taken_diagnostic", False)
            completed_str = data.get("completed_chapters", "[]")
            try:
                completed = json.loads(completed_str)
            except:
                completed = []
                
        # Also check if student exists in 'students' table with a grade
        # If they don't have a grade, they might still need setup screen
        student_res = supabase.table("students").select("grade").eq("id", student_id).execute()
        has_grade = student_res.data and student_res.data[0].get("grade") is not None

        return {
            "needs_diagnostic": not has_taken,
            "has_grade": bool(has_grade),
            "completed_chapters": completed
        }
    except Exception as e:
        print(f"ERROR: Online-only diagnostic check failed: {e}")
        # Fallback to local only as a last resort to find ANY record
        perm = db.query(StudentPermission).filter(StudentPermission.student_id == student_id).first()
        return {
            "needs_diagnostic": not (perm.has_taken_diagnostic if perm else False),
            "has_grade": True, # Assume true to avoid setup loop on error
            "completed_chapters": []
        }

@router.get("/subjects")
def get_subjects(student_id: str = None, db: Session = Depends(get_db)):
    """Fetch unique subjects from the textbook table online"""
    try:
        print(f"DEBUG: Fetching subjects. Student ID: {student_id}")
        query = supabase.table("textbook").select("subject")
        
        # If student_id provided, filter by their specific grade
        if student_id:
            student_res = supabase.table("students").select("grade").eq("id", student_id).execute()
            if student_res.data:
                grade = student_res.data[0].get("grade")
                if grade:
                    query = query.eq("grade", str(grade))
                    print(f"DEBUG: Filtering subjects by grade: {grade}")

        response = query.execute()
        
        if not response.data:
            print("WARNING: No subjects found in Supabase 'textbook' table.")
            # Final fallback: fetch ANY subjects if grade filter returned nothing
            if student_id:
                print("DEBUG: Retrying subject fetch without grade filter...")
                response = supabase.table("textbook").select("subject").execute()

        subjects = sorted(list(set([item['subject'] for item in response.data if item.get('subject')])))
        print(f"DEBUG: Returning subjects: {subjects}")
        return subjects
    except Exception as e:
        print(f"ERROR: Failed to fetch subjects: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/chapters")
def get_chapters(subject: str):
    """Fetch unique chapters for a subject from the textbook table online"""
    try:
        print(f"DEBUG: Fetching chapters for subject: {subject}")
        response = supabase.table("textbook") \
            .select("chapter") \
            .eq("subject", subject) \
            .execute()
        
        if not response.data:
            print(f"WARNING: No chapters found for subject '{subject}' in 'textbook' table.")
            return []
            
        chapters = sorted(list(set([item['chapter'] for item in response.data if item.get('chapter')])))
        print(f"DEBUG: Found {len(chapters)} chapters.")
        return chapters
    except Exception as e:
        print(f"ERROR: Failed to fetch chapters: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/textbooks")
def get_textbooks():
    """Fetch all unique book entries from the textbook table."""
    try:
        response = supabase.table("textbook").select("subject", "chapter", "grade").execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/topics")
def get_topics(subject: str, chapter: str):
    """Fetch unique topics (subtopics) for a chapter from learning_content table online"""
    try:
        print(f"DEBUG: Fetching topics for Subject: {subject}, Chapter: {chapter}")
        # Use mapping for DB compatibility if needed, but try direct first
        db_chapter = CHAPTER_NAME_MAP.get(chapter, chapter)
        
        # Query learning_content table for unique topics
        response = supabase.table("learning_content") \
            .select("topic") \
            .eq("subject", subject) \
            .eq("chapter", db_chapter) \
            .execute()
        
        if not response.data:
             # Try without mapping if it failed
             if db_chapter != chapter:
                 print(f"DEBUG: Retrying topic fetch with original name: {chapter}")
                 response = supabase.table("learning_content") \
                    .select("topic") \
                    .eq("subject", subject) \
                    .eq("chapter", chapter) \
                    .execute()

        topics = sorted(list(set([item['topic'] for item in response.data if item.get('topic')])))
        print(f"DEBUG: Found {len(topics)} topics.")
        return topics
    except Exception as e:
        print(f"ERROR: Failed to fetch topics: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/notes/{chapter}")
def get_revision_notes(chapter: str):
    try:
        # textbook table might be missing, so handle this gracefully
        try:
            response = supabase.table("textbook") \
                .select("notes") \
                .eq("chapter", chapter) \
                .execute()
            if response.data:
                return {"notes": response.data[0].get("notes", "# No notes found")}
        except:
            pass
            
        return {"notes": f"# {chapter}\nNo revision notes available yet for this chapter. Use the AI Content Lab to generate them!"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))




@router.post("/submit/adaptive", response_model=AdaptiveTestResponse)
def submit_adaptive_test(submission: AdaptiveTestSubmission, db: Session = Depends(get_db)):
    print(f"DEBUG: Received submission for student {submission.student_id}, chapter {submission.chapter}")
    """
    Submit test results and get adaptive recommendation based on the specific flow:
    - Excellent (> 90%) -> Hard
    - OK (70-90%) -> Medium
    - Bad (< 70%) -> Previous Topic (Easy)
    - If Hard Passed -> Next Subtopic (Easy)
    """
    # 1. Resolve Student (by ID or Email)
    student = None
    if submission.email:
        student = get_student_by_email(db, submission.email)
    
    if not student:
        student = get_student(db, submission.student_id)
        
    if not student:
        from app.services.student_service import create_student
        student = create_student(db, submission.student_id, submission.email or f"{submission.student_id}@example.com", 9)

    # 2. Calculate Accuracy & Reward
    # 2. Calculate Accuracy & Reward
    accuracy = (submission.score / submission.total_questions) if submission.total_questions > 0 else 0.0
    avg_time_per_q = (submission.time_taken / submission.total_questions) if submission.total_questions > 0 else 0.0
    
    # Prepare Pre-Update State (for RL & Logging)
    prev_state = {
        "avg_accuracy_last_5": student.avg_accuracy_last_5,
        "avg_time_per_question": student.avg_time_per_question,
        "current_difficulty": student.current_difficulty,
        "topic_mastery": student.topic_mastery,
        "attempts": student.attempts,
        "recent_improvement": student.recent_improvement
    }

    # Reward Logic using Service (Clipped)
    perf_data = {
        "correct": accuracy >= 0.7, 
        "accuracy": accuracy,
        "avg_time": avg_time_per_q,
        "failure_streak": 0
    }
    raw_reward = compute_reward(prev_state, perf_data)
    reward_score = max(-1.0, min(1.0, raw_reward))

    # 3. Determine Next Difficulty
    current_diff = submission.difficulty_level
    new_difficulty = current_diff
    
    if reward_score > 1:
        new_difficulty = min(2, current_diff + 1)
        difficulty_change = "INCREASED"
    elif reward_score < 0:
        new_difficulty = max(0, current_diff - 1)
        difficulty_change = "DECREASED"
    else:
        difficulty_change = "SAME"

    # 4. Determine Action & Next Content
    action = "RETRY"
    message = ""
    recommended_chapter = submission.chapter
    recommended_subtopic = submission.subtopic
    fallback_topics = []
    
    # 3. Topic-wise Performance Analysis (for Common Tests or multi-topic quizzes)
    topic_performance = defaultdict(lambda: {"correct": 0, "total": 0})
    if submission.answers:
        for ans in submission.answers:
            q_id = ans.get("question_id")
            is_correct = ans.get("is_correct")
            
            # Fetch topic info from Supabase if not provided in answer (required for common test)
            q_topic = ans.get("topic")
            if not q_topic and q_id:
                try:
                    # Check common_test_questions first
                    q_res = supabase.table("common_test_questions").select("topic").eq("id", q_id).execute()
                    if q_res.data:
                        q_topic = q_res.data[0].get("topic")
                    else:
                        # Fallback to learning_content
                        q_res = supabase.table("learning_content").select("topic").eq("id", q_id).execute()
                        if q_res.data:
                            q_topic = q_res.data[0].get("topic")
                except:
                    pass
            
            if q_topic:
                print(f"DEBUG: Resolved Question {q_id} to Topic: '{q_topic}'")
                ans["topic"] = q_topic # Save back to answer for later use
                topic_performance[q_topic]["total"] += 1
                if is_correct:
                    topic_performance[q_topic]["correct"] += 1

    # Identify Fallback Topics & Initialize Mastery
    is_common_test = not submission.subtopic or submission.subtopic == ""
    
    if is_common_test:
        # Fetch ALL subtopics for this chapter from learning_content to track them
        try:
            db_chapter = CHAPTER_NAME_MAP.get(submission.chapter, submission.chapter)
            
            # Fix: Define all_chapter_subtopics
            all_chapter_subtopics = SUBTOPICS.get(db_chapter, [])
            if not all_chapter_subtopics:
                # Fallback to DB fetch
                 try:
                    res = supabase.table("learning_content").select("topic").eq("chapter", db_chapter).execute()
                    all_chapter_subtopics = list(set([item['topic'] for item in res.data if item.get('topic')]))
                 except:
                    pass

            for sub in all_chapter_subtopics:
                # ONLY update or initialize if the subtopic was actually part of this test
                if topic_performance[sub]["total"] == 0:
                    continue
                    
                sub_acc = topic_performance[sub]["correct"] / topic_performance[sub]["total"]
                print(f"DEBUG: Updating mastery for {sub} with acc {sub_acc}")
                
                m_record = db.query(SubtopicMastery).filter(
                    SubtopicMastery.student_id == student.id,
                    SubtopicMastery.chapter == submission.chapter,
                    SubtopicMastery.subtopic == sub
                ).first()
                
                if not m_record:
                    m_record = SubtopicMastery(
                        student_id=student.id,
                        chapter=submission.chapter,
                        subtopic=sub,
                        accuracy=sub_acc,
                        level=0, # Let RL decide level up
                        is_completed=False,
                        last_action="RETRY" # Default
                    )
                    db.add(m_record)
                else:
                    # Update accuracy (weighted average)
                    m_record.accuracy = (m_record.accuracy + sub_acc) / 2
                    
                # --- PPO Model Decision for Subtopic (Decisive for BOTH new and existing) ---
                # 6 Inputs: accuracy, time, difficulty, mastery, attempts, improvement
                subtopic_state = {
                    "avg_accuracy_last_5": sub_acc, # Current performance is key
                    "avg_time_per_question": avg_time_per_q, # Global avg for this test
                    "current_difficulty": submission.difficulty_level,
                    "topic_mastery": m_record.accuracy, # Using subtopic accuracy as proxy for mastery
                    "attempts": student.attempts, # Using global attempts as proxy
                    "recent_improvement": student.recent_improvement
                }
                
                print(f"DEBUG: RL State for {sub}: {subtopic_state}")
                
                try:
                    # Action: 0(Easy/Prac), 1(Med/Prac), 2(Hard/Prac), 3(Easy/Rev), 4(Med/Adv)
                    # We map this to Target Difficulty: 0, 1, 2
                    action_idx = rl_service.select_action(subtopic_state)
                    print(f"DEBUG: RL Action for {sub}: {action_idx}")
                    
                    # Map Action to Target Difficulty
                    # 0->0(Easy), 1->1(Med), 2->2(Hard), 3->0(Easy), 4->1(Med/Adv - wait, 4 usually means explicit advance)
                    # Let's use the explicit mapping
                    target_difficulty_map = {0: 0, 1: 1, 2: 2, 3: 0, 4: 2} # 4 is Med/Adv, maybe map to 2 (Hard) or 1? 
                    # If I am level 0, and get 4 (Med/Adv), I should go to 1.
                    # As per user "decisive level to hit":
                    # If Action suggests Difficulty > Current Level => ADVANCE
                    
                    target_diff = target_difficulty_map.get(action_idx, 0)
                    if action_idx == 4: target_diff = m_record.level + 1 # Explicit Advance logic
                    
                    # Decisive Logic
                    if target_diff > m_record.level:
                        if m_record.level < 2:
                            m_record.level += 1
                        else:
                            m_record.is_completed = True
                        m_record.last_action = "ADVANCE"
                    else:
                        # PPO Override: Even if accuracy is high, if RL says so, we RETRY.
                        m_record.last_action = "RETRY"
                        
                except Exception as e:
                    print(f"RL Error for subtopic {sub}: {e}")
                    # Fallback Rule
                    if sub_acc >= 0.8:
                        if m_record.level < 2:
                             m_record.level += 1
                        else:
                             m_record.is_completed = True
                        m_record.last_action = "ADVANCE"
                    else:
                        m_record.last_action = "RETRY"
                
                # Add to fallback topics if RL/Rule decided RETRY
                if m_record.last_action == "RETRY":
                    fallback_topics.append(sub)
            
        except Exception as e:
            print(f"Error initializing subtopic mastery: {e}")
    else:
        # Subtopic Test - Handle Progression
        m_record = db.query(SubtopicMastery).filter(
            SubtopicMastery.student_id == student.id,
            SubtopicMastery.chapter == submission.chapter,
            SubtopicMastery.subtopic == submission.subtopic
        ).first()
        
        if m_record:
            m_record.accuracy = (m_record.accuracy + accuracy) / 2
            
            # Progression: Easy(0) -> Medium(1) -> Hard(2)
            if accuracy >= 0.8: # Passed current level
                if m_record.level < 2:
                    m_record.level += 1
                    message = f"Level Up! You've mastered {submission.subtopic} at level {m_record.level-1}. Now try Level {m_record.level}."
                else:
                    m_record.is_completed = True
                    message = f"Mastery Achieved! You've cleared the Hard level for {submission.subtopic}."
            elif accuracy < 0.5: # Struggled
                message = f"Keep practicing! Focus on the {submission.subtopic} fundamentals."
            else:
                message = f"Good effort! Consistency is key to mastering {submission.subtopic}."
        else:
            # Handle case where it wasn't initialized
            m_record = SubtopicMastery(
                student_id=student.id,
                chapter=submission.chapter,
                subtopic=submission.subtopic,
                accuracy=accuracy,
                level=0,
                is_completed=(accuracy >= 0.8 and submission.difficulty_level == 2)
            )
            db.add(m_record)
    
    # 4. RL-Driven Difficulty Adjustment
    student_state = prev_state
    
    # Get action from RL Service
    try:
        action_idx = rl_service.select_action(student_state)
        # Action Map per Audit Spec: 
        # 0 -> easy/practice, 1 -> med/practice, 2 -> hard/practice, 3 -> easy/revise, 4 -> med/advance
        new_diff_map = {0: 0, 1: 1, 2: 2, 3: 0, 4: 1}
        new_difficulty = new_diff_map.get(action_idx, student.current_difficulty)
        
        action_labels = {
            0: "RETRY", 1: "RETRY", 2: "RETRY", 3: "RETRY", 4: "ADVANCE"
        }
        action = action_labels.get(action_idx, "RETRY")
        
        if action == "ADVANCE":
            message = "The AI model recommends advancing to a higher difficulty!"
        elif fallback_topics:
            message = f"You fell back on {len(fallback_topics)} topics. Let's practice them."
        else:
            message = "Focus on reinforcing your current understanding."
            
    except Exception as e:
        print(f"RL Prediction failed: {e}. Falling back to rule-based logic.")
        # ... existing rule-based logic below ...
    
    # Translate chapter name if necessary (mapping long names to internal keys)
    mapped_chapter = CHAPTER_NAME_MAP.get(submission.chapter, submission.chapter)
    
    subtopic_list = SUBTOPICS.get(mapped_chapter, [])
    curr_subtopic_idx = subtopic_list.index(submission.subtopic) if submission.subtopic in subtopic_list else -1

    # Logic for Content Progression
    # If we promoted difficulty or stayed high, we might advance
    # distinct from simple accuracy check, but let's blend them
    
    passed_threshold = accuracy >= 0.7
    
    if passed_threshold:
        if new_difficulty > current_diff:
             message = "Great job! Moving to a harder difficulty."
             action = "ADVANCE"
        elif current_diff == 2:
            # Mastered Hard -> Next Subtopic
             message = "Excellent! You've mastered this topic."
             action = "ADVANCE"
             if curr_subtopic_idx + 1 < len(subtopic_list):
                 recommended_subtopic = subtopic_list[curr_subtopic_idx + 1]
                 new_difficulty = 0 # Reset to Easy for new topic
             else:
                 action = "COMPLETE"
                 message = f"Chapter {submission.chapter} Complete!"
                 
                 # Next Chapter Logic
                 all_chapters = list(SUBTOPICS.keys())
                 curr_chap_idx = all_chapters.index(mapped_chapter) if mapped_chapter in all_chapters else -1
                 if curr_chap_idx != -1 and curr_chap_idx + 1 < len(all_chapters):
                     recommended_chapter = all_chapters[curr_chap_idx + 1]
                     recommended_subtopic = SUBTOPICS[recommended_chapter][0]
                 else:
                     recommended_chapter = "Course Complete"
                     recommended_subtopic = None
        else:
             # Passed but stay same difficulty or just moved up
             if difficulty_change == "INCREASED":
                 action = "ADVANCE" 
             else:
                 # Passed easy/med but reward didn't bump difficulty? 
                 # Maybe allow advance if consistent
                 action = "ADVANCE"
                 new_difficulty = min(2, current_diff + 1)
                 message = "Good work. Let's try the next level."
    else:
        # Failed threshold (< 0.7)
        action = "RETRY"
        if new_difficulty < current_diff:
            message = "Let's try an easier level to build confidence."
        else:
            message = "Let's review this topic again."
            
        # Specific Fallback Recommendations for Subtopic Tests
        if not is_common_test and submission.subtopic:
             # Suggest related subtopics or the current one
             fallback_topics = [submission.subtopic]
             # Maybe add previous subtopic if exists
             if curr_subtopic_idx > 0:
                 fallback_topics.append(subtopic_list[curr_subtopic_idx - 1])
            
        if difficulty_change == "DECREASED" and current_diff == 0:
            # Already failed easy -> go back a subtopic potentially?
            if curr_subtopic_idx > 0:
                recommended_subtopic = subtopic_list[curr_subtopic_idx - 1]
                message = "Let's reinforce the previous concept."

    # 5. DB Updates
    # Update Student State (Rolling Averages & RL State)
    performance_block = {
        "accuracy": accuracy,
        "avg_time": avg_time_per_q,
        "topic_mastery": (student.topic_mastery + accuracy) / 2 # Simple topic mastery aggregate
    }
    update_student_state(db, student, performance_block)
    update_student_difficulty(db, student.id, new_difficulty)
    
    # Store Action in Mastery Records
    if not is_common_test and submission.subtopic:
        m_rec = db.query(SubtopicMastery).filter(
            SubtopicMastery.student_id == student.id,
            SubtopicMastery.chapter == submission.chapter,
            SubtopicMastery.subtopic == submission.subtopic
        ).first()
        if m_rec:
            m_rec.last_action = action
    
    # Log Performance History (Per Question if details available, else aggregate)
    if submission.answers:
        for ans in submission.answers:
            perf_entry = PerformanceHistory(
                student_id=student.id,
                content_id=ans.get("question_id"),
                accuracy=1.0 if ans.get("is_correct") else 0.0,
                time_spent=avg_time_per_q, # Approximation if per-question time not tracked
                difficulty_level=submission.difficulty_level,
                chapter=submission.chapter,
                subtopic=ans.get("topic") or submission.subtopic,
                reward_score=reward_score, # Global reward applied to all for now, or calc individual? logic implies session reward
                outcome=action
            )
            db.add(perf_entry)
            
            # Sync to Supabase
            try:
                supabase.table("performance_history").insert({
                    "student_id": student.id,
                    "content_id": ans.get("question_id"),
                    "accuracy": 1.0 if ans.get("is_correct") else 0.0,
                    "time_spent": avg_time_per_q,
                    "difficulty_level": submission.difficulty_level,
                    "chapter": submission.chapter,
                    "topic": ans.get("topic") or submission.subtopic,
                    "outcome": action,
                    "reward_score": reward_score
                }).execute()
            except:
                pass
    else:
        # Fallback to aggregate if no detailed answers
        perf_entry = PerformanceHistory(
            student_id=student.id,
            content_id=None,
            accuracy=accuracy,
            time_spent=submission.time_taken,
            difficulty_level=submission.difficulty_level,
            chapter=submission.chapter,
            subtopic=submission.subtopic,
            reward_score=reward_score,
            outcome=action
        )
        db.add(perf_entry)

    # Record Mastery (Legacy support for UI)
    current_mastery = db.query(SubtopicMastery).filter(
        SubtopicMastery.student_id == student.id,
        SubtopicMastery.chapter == submission.chapter,
        SubtopicMastery.subtopic == submission.subtopic
    ).first()

    if not current_mastery:
        current_mastery = SubtopicMastery(
            student_id=student.id,
            chapter=submission.chapter,
            subtopic=submission.subtopic,
            accuracy=accuracy,
            level=submission.difficulty_level if hasattr(submission, 'difficulty_level') else 0,
            is_completed=(accuracy >= 0.7)
        )
        db.add(current_mastery)
    else:
        if accuracy > current_mastery.accuracy:
            current_mastery.accuracy = accuracy
        if hasattr(submission, 'difficulty_level'):
            current_mastery.level = submission.difficulty_level
        if accuracy >= 0.7:
            current_mastery.is_completed = True
    
    # Calculate Mastery Score (0.0 to 1.0)
    # Formula: (level * 0.4) + (accuracy * 0.2)
    # level 0 -> 0.0-0.2 (Red), level 1 -> 0.4-0.6 (Orange), level 2 -> 0.8-1.0 (Green)
    current_mastery.mastery = (current_mastery.level * 0.4) + (current_mastery.accuracy * 0.2)
    
    # Sync to Supabase Mastery Table
    try:
        # Fetch updated mastery records for this chapter
        chapter_mastery = db.query(SubtopicMastery).filter(
            SubtopicMastery.student_id == student.id,
            SubtopicMastery.chapter == submission.chapter
        ).all()
        
        for m in chapter_mastery:
            supabase.table("subtopic_mastery").upsert({
                "student_id": m.student_id,
                "chapter": m.chapter,
                "subtopic": m.subtopic,
                "accuracy": m.accuracy,
                "mastery": m.mastery,
                "level": m.level,
                "is_completed": m.is_completed,
                "last_action": m.last_action
            }).execute()
    except Exception as e:
        print(f"Supabase mastery sync warning: {e}")

    # Update Permission Flag if Diagnostic or Common Test
    perm = db.query(StudentPermission).filter(StudentPermission.student_id == student.id).first()
    if not perm:
        perm = StudentPermission(student_id=student.id)
        db.add(perm)
        
    if submission.chapter == "Diagnostic":
        perm.has_taken_diagnostic = True
        
    # If this was a "Common Test" (no subtopic) and passed/completed
    if submission.chapter and not submission.subtopic:
        # Assuming any submission of Common Test counts as "given" (passed or fail)
        # Or should we check for specific score? User said "if given then skip".
        # So we mark it as done.
        print(f"DEBUG: Common test detected for chapter: {submission.chapter}")
        current_list = []
        if perm.completed_chapters:
            try:
                current_list = json.loads(perm.completed_chapters)
            except:
                pass
        
        print(f"DEBUG: Current completed_chapters before: {current_list}")
        if submission.chapter not in current_list:
            current_list.append(submission.chapter)
            perm.completed_chapters = json.dumps(current_list)
            print(f"DEBUG: Updated completed_chapters to: {current_list}")
        else:
            print(f"DEBUG: Chapter already in list, skipping")
            
        # Also ensure chapter-level mastery record is marked completed
        chapter_mastery = db.query(SubtopicMastery).filter(
            SubtopicMastery.student_id == student.id,
            SubtopicMastery.chapter == submission.chapter,
            SubtopicMastery.subtopic == None
        ).first()
        if not chapter_mastery:
            chapter_mastery = SubtopicMastery(
                student_id=student.id,
                chapter=submission.chapter,
                subtopic=None,
                is_completed=True,
                accuracy=accuracy,
                level=submission.difficulty_level,
                mastery=(submission.difficulty_level * 0.4) + (accuracy * 0.2)
            )
            db.add(chapter_mastery)
        else:
            chapter_mastery.is_completed = True
            if accuracy > chapter_mastery.accuracy:
                chapter_mastery.accuracy = accuracy
            chapter_mastery.level = submission.difficulty_level
            chapter_mastery.mastery = (chapter_mastery.level * 0.4) + (chapter_mastery.accuracy * 0.2)
        
        # Sync chapter-level mastery to Supabase
        try:
            supabase.table("subtopic_mastery").upsert({
                "student_id": student.id,
                "chapter": submission.chapter,
                "subtopic": None, # Represents chapter-level
                "accuracy": chapter_mastery.accuracy,
                "mastery": chapter_mastery.mastery,
                "level": chapter_mastery.level,
                "is_completed": True,
                "last_action": chapter_mastery.last_action
            }).execute()
        except Exception as e:
            print(f"Supabase chapter mastery sync warning: {e}")

    db.commit()

    # 5. Sync with Supabase (Required by Spec)
    try:
        # Sync Permissions
        print(f"DEBUG: Syncing to Supabase - student_id: {student.id}, completed_chapters: {perm.completed_chapters}")
        supabase.table("student_permissions").upsert({
            "student_id": student.id,
            "has_taken_diagnostic": perm.has_taken_diagnostic,
            "completed_chapters": perm.completed_chapters
        }).execute()
        print(f"DEBUG: Supabase sync successful!")

        # Update RL State
        supabase.table("rl_states").upsert({
            "student_id": student.id,
            "topic_mastery": student.topic_mastery,
            "avg_accuracy_last_5": student.avg_accuracy_last_5,
            "avg_time_per_question": student.avg_time_per_question,
            "total_attempts": student.attempts,
            "current_difficulty_index": new_difficulty,
            "recent_improvement": student.recent_improvement
        }).execute()
    except Exception as e:
        print(f"Supabase post-commit sync warning: {e}")

    # Log RL Transition
    next_state = {
        "avg_accuracy_last_5": student.avg_accuracy_last_5,
        "avg_time_per_question": student.avg_time_per_question,
        "current_difficulty": new_difficulty,
        "topic_mastery": student.topic_mastery,
        "attempts": student.attempts,
        "recent_improvement": student.recent_improvement
    }
    try:
        if 'action_idx' in locals():
            rl_service.log_transition(
                db=db,
                student_id=student.id,
                prev_state=prev_state,
                action=action_idx,
                reward=reward_score,
                next_state=next_state
            )
    except Exception as e:
        print(f"RL Logging Failed: {e}")

    return AdaptiveTestResponse(
        action=action,
        message=message,
        new_difficulty=new_difficulty,
        recommended_chapter=recommended_chapter,
        recommended_subtopic=recommended_subtopic,
        fallback_topics=fallback_topics
    )

@router.get("/mastery/{student_id}")
def get_mastery(student_id: str, db: Session = Depends(get_db)):
    """Get completion status for all subtopics/chapters for a student from ONLINE database ONLY"""
    result = {}
    
    # 1. Fetch Subtopic Mastery from Supabase
    try:
        mastery_res = supabase.table("subtopic_mastery").select("*").eq("student_id", student_id).execute()
        for entry in mastery_res.data:
            chapter = entry.get("chapter")
            if not chapter: continue
            
            if chapter not in result:
                result[chapter] = {}
            
            subtopic = entry.get("subtopic")
            target = subtopic if subtopic else "CHAPTER_COMPLETE"
            
            result[chapter][target] = {
                "is_completed": entry.get("is_completed", False),
                "level": entry.get("level", 0),
                "accuracy": entry.get("accuracy", 0.0),
                "mastery": entry.get("mastery", 0.0),
                "last_action": entry.get("last_action")
            }
    except Exception as e:
        print(f"ERROR: Failed to fetch Supabase mastery: {e}")

    # 2. Fetch Completed Chapters from Student Permissions (Supabase)
    try:
        perm_res = supabase.table("student_permissions").select("completed_chapters").eq("student_id", student_id).execute()
        if perm_res.data:
            completed_str = perm_res.data[0].get("completed_chapters", "[]")
            completed_from_perms = json.loads(completed_str)
            
            for chapter in completed_from_perms:
                if chapter not in result:
                    result[chapter] = {}
                
                # If not already marked completed by subtopic_mastery records, mark it now
                if "CHAPTER_COMPLETE" not in result[chapter] or not result[chapter]["CHAPTER_COMPLETE"]["is_completed"]:
                    result[chapter]["CHAPTER_COMPLETE"] = {
                        "is_completed": True,
                        "level": 0,
                        "accuracy": 1.0
                    }
    except Exception as e:
        print(f"ERROR: Failed to fetch Supabase permissions: {e}")
        
    return result

def _fetch_chapters_internal(subject: str):
    try:
        # Fetch chapters exclusively from the textbook table per user request
        response = supabase.table("textbook") \
            .select("chapter") \
            .eq("subject", subject) \
            .execute()
        
        # Use set only to remove exact duplicates if any exist in the table
        chapters = set()
        for item in response.data:
            if item.get('chapter'):
                chapters.add(item['chapter'])
                
        return sorted(list(chapters))
    except Exception as e:
        print(f"Error fetching chapters from textbook table: {e}")
        return []
