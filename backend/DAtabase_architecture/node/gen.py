"""
Generate questions using Google Gemini API
Generates: MCQ, Fill-in-blank, True/False questions in structured JSON format
"""
import google.generativeai as genai
import json
import re

# Configure Gemini
API_KEY = "AIzaSyCvluchfye2mn6jY7L-77HPC2OEfou_3-k"
genai.configure(api_key=API_KEY)
model = genai.GenerativeModel('models/gemini-2.5-flash')

def is_relevant_physics_text(text: str) -> bool:
    """Check if the text chunk is likely relevant physics content"""
    irrelevant_keywords = [
        "preface", "index", "committee", "bureau", "textbook production",
        "curriculum research", "diksha app", "qr code", "all rights reserved"
    ]
    text_lower = text.lower()
    if sum(1 for word in irrelevant_keywords if word in text_lower) >= 2:
        return False
        
    physics_keywords = [
        "motion", "force", "energy", "work", "power", "mass", "velocity",
        "acceleration", "speed", "distance", "displacement", "gravity", "law",
        "unit", "measure", "momentum", "inertia", "friction", "vector", "electric",
        "voltage", "current", "resistance", "light", "sound", "heat"
    ]
    return any(word in text_lower for word in physics_keywords)

def generate_questions(state: dict) -> dict:
    """LangGraph node: Generate high-quality questions using Gemini"""
    chunks = state.get("chunks", [])
    all_generated_questions = []
    
    # Filter for physics-relevant theory chunks
    relevant_chunks = [c for c in chunks if c.get("section") == "theory" and is_relevant_physics_text(c.get("text", ""))]
    
    # Process in batches or one by one? 
    # Let's do one large prompt for multiple chunks to be efficient, or 5-10 chunks max.
    relevant_chunks = relevant_chunks[:15] 
    
    if not relevant_chunks:
        print("No relevant physics chunks found.")
        state["questions"] = []
        return state

    print(f"Generating physics questions from {len(relevant_chunks)} chunks using Gemini...")
    
    # Combine chunks for context or handle individually?
    # Handling collectively usually gives better variety.
    context_text = "\n\n".join([f"Source Chunk {i+1}:\n{c['text']}" for i, c in enumerate(relevant_chunks)])
    
    prompt = f"""
    You are an expert Physics teacher. Based on the provided textbook excerpts, generate a set of high-quality questions.
    
    Excerpts:
    {context_text}
    
    Task:
    Generate at least 10 questions covering these types:
    1. Multiple Choice Questions (MCQ) - include 4 options and the correct answer.
    2. Fill-in-the-blank - the answer should be a single word or short phrase.
    3. True/False - a statement that is either True or False.
    
    Output Format:
    Return ONLY a JSON list of objects. Each object must follow this structure:
    {{
        "type": "mcq" | "fill_blank" | "true_false",
        "question_text": "text of the question",
        "options": ["Option A", "Option B", "Option C", "Option D"], // ONLY for mcq, else empty list
        "answer": "A/B/C/D" | "the blank word" | "True/False",
        "chapter": "Related physics topic or chapter name"
    }}
    
    Constraints:
    - Questions must be scientifically accurate.
    - Questions must be directly based on the provided text.
    - DO NOT include any markdown preamble or blockquotes, just the raw JSON list.
    """

    try:
        response = model.generate_content(prompt)
        text_response = response.text.strip()
        
        # Clean potential markdown code blocks
        if text_response.startswith("```json"):
            text_response = text_response.replace("```json", "", 1).replace("```", "", 1).strip()
        elif text_response.startswith("```"):
            text_response = text_response.split("```")[1].strip()
            
        questions = json.loads(text_response)
        
        for q in questions:
            q["raw_output"] = text_response # For debugging
            # Ensure consistency with previous format
            q["detected_type"] = q["type"]
            all_generated_questions.append(q)
            print(f"  ✓ {q['type']} generated: {q['question_text'][:50]}...")

    except Exception as e:
        print(f"  ✗ Gemini Error: {e}")
        # Fallback empty list
        
    state["questions"] = all_generated_questions
    return state

if __name__ == "__main__":
    # Test
    test_state = {"chunks": [{"text": "Work is done when a force acts on an object and causes displacement. W = Fs cos theta.", "section": "theory", "chapter": "Work and Energy"}]}
    result = generate_questions(test_state)
    print(f"\nTotal questions: {len(result['questions'])}")
