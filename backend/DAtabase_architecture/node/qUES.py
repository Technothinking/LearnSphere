"""
Save generated questions (alias for Mongo module)
"""
from .Mongo import save_to_mongo


def save_questions(questions: list) -> bool:
    """Save questions to database"""
    state = {"questions": questions}
    result = save_to_mongo(state)
    return result.get("saved", False)
