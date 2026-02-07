"""
Verify generated questions from MongoDB
"""
from pymongo import MongoClient

MONGO_URL = "mongodb+srv://ujjwal123warade_db_user:CH04GleYczY6QSaD@cluster0.eeiufn6.mongodb.net/?appName=Cluster0"

try:
    client = MongoClient(MONGO_URL)
    db = client["question_generator"]
    # Get the latest 10 questions
    questions = list(db.questions.find().sort("_id", -1).limit(10))
    
    print(f"Retrieved {len(questions)} questions from MongoDB:\n")
    for i, q in enumerate(questions, 1):
        print(f"[{i}] {q['type'].upper()}")
        print(f"Q: {q['question_text']}")
        if q.get('options'):
            print(f"Options: {q['options']}")
        print(f"A: {q['correct_answer']}")
        print("-" * 30)

except Exception as e:
    print(f"Error: {e}")
