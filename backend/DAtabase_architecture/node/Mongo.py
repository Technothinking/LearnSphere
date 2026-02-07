"""
Save generated questions to MongoDB
"""
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError

# MongoDB connection with timeout settings
MONGO_URL = "mongodb+srv://ujjwal123warade_db_user:CH04GleYczY6QSaD@cluster0.eeiufn6.mongodb.net/?appName=Cluster0"

try:
    client = MongoClient(
        MONGO_URL,
        serverSelectionTimeoutMS=5000,  # 5 second timeout
        connectTimeoutMS=5000,
        socketTimeoutMS=10000
    )
    # Test connection
    client.admin.command('ping')
    db = client["question_generator"]
    print("MongoDB connected successfully")
except Exception as e:
    print(f"MongoDB connection warning: {e}")
    client = None
    db = None


def save_to_mongo(state: dict) -> dict:
    """
    LangGraph node: Save questions to MongoDB
    
    Input state:
        - questions: list of generated questions
    
    Output state:
        - saved: True if successful
        - saved_count: number of questions saved
    """
    questions = state.get("questions", [])
    
    if not questions:
        print("No questions to save")
        state["saved"] = False
        state["saved_count"] = 0
        return state
    
    formatted = []
    for i, q in enumerate(questions):
        formatted.append({
            "chapter": q.get("chapter", "Unknown"),
            "type": q.get("type", "unknown"),
            "detected_type": q.get("detected_type", q.get("type")),
            "question_text": q.get("question_text", ""),
            "options": q.get("options", []),
            "correct_answer": q.get("answer", ""),
            "raw_output": q.get("raw_output", ""),
            "difficulty": 2,
            "marks": 1,
            "time_limit": 30,
            "tags": ["generated", "t5"]
        })

    # If MongoDB is connected, try to insert
    if db is not None:
        try:
            result = db.questions.insert_many(formatted)
            print(f"Saved {len(result.inserted_ids)} questions to MongoDB")
            state["saved"] = True
            state["saved_count"] = len(result.inserted_ids)
            return state
        except Exception as e:
            print(f"Error saving to MongoDB: {e}")
    else:
        print("MongoDB not connected - falling back to JSON")

    # Fallback: save to local JSON file
    import json
    import os
    from datetime import datetime
    
    try:
        output_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        json_path = os.path.join(output_dir, f"questions_{timestamp}.json")
        
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(formatted, f, indent=2, ensure_ascii=False)
        
        print(f"Saved {len(formatted)} questions to: {json_path}")
        state["saved"] = True
        state["saved_count"] = len(formatted)
        state["saved_to_json"] = True
        state["json_path"] = json_path
    except Exception as e:
        print(f"Critical error during JSON fallback: {e}")
        state["saved"] = False
        state["saved_count"] = 0
    
    return state


def detect_questions(state: dict) -> dict:
    """Legacy function - just passes through"""
    return state