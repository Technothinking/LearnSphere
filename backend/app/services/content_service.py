import fitz  # PyMuPDF
import google.generativeai as genai
import json
import os
import re
from typing import List, Dict
from app.core.database import supabase
from app.core.config import settings

# Configure Gemini
# Using Gemini 1.5 Flash as requested for generation
GEMINI_API_KEY = "AIzaSyCvluchfye2mn6jY7L-77HPC2OEfou_3-k"
genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel('models/gemini-1.5-flash') 

class ContentGenerationService:
    @staticmethod
    def extract_text_from_pdf(pdf_bytes: bytes) -> str:
        """Extract all text from PDF bytes."""
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")
        text = ""
        for page in doc:
            text += page.get_text() + "\n"
        doc.close()
        return text

    @staticmethod
    async def identify_topics(text: str, chapter_name: str) -> List[str]:
        """Use AI to identify sub-topics/sections in the chapter."""
        # Use a portion of text if too large, but enough to get structure
        context = text[:10000] 
        prompt = f"""
        Analyze the following text from a Physics textbook chapter titled '{chapter_name}'.
        Identify the main sub-topics or sections covered.
        
        Text:
        {context}
        
        Return ONLY a JSON list of strings representing the topic names.
        Example: ["Ohm's Law", "Combination of Resistances", "Heating Effect of Electric Current"]
        """
        
        try:
            response = model.generate_content(prompt)
            topics_json = response.text.strip()
            # Clean markdown JSON blocks
            if "```json" in topics_json:
                topics_json = topics_json.split("```json")[1].split("```")[0].strip()
            elif "```" in topics_json:
                topics_json = topics_json.split("```")[1].strip()
                
            return json.loads(topics_json)
        except Exception as e:
            print(f"Error identifying topics: {e}")
            return [chapter_name] # Fallback to chapter name as a single topic

    @staticmethod
    async def generate_common_test_questions(text: str, chapter: str, subject: str) -> List[Dict]:
        """
        Generate exactly 30 Easy questions (10 MCQ, 10 Fill, 10 T/F) for the Common Test.
        """
        prompt = f"""
        You are an expert Physics teacher. Based on the provided textbook material for chapter '{chapter}', generate exactly 30 EASY-level questions.
        
        Text Material:
        {text[:20000]}
        
        Requirements:
        1. Total Questions: 30
        2. Difficulty: ALL questions must be EASY (basic recall, definitions).
        3. Types Distribution:
           - 10 Multiple Choice (MCQ) - Provide 4 options and correct answer.
           - 10 Fill-in-the-blank - Provide incomplete sentence and correct word.
           - 10 True/False - Provide statement and 'True' or 'False'.
        
        Output Format:
        Return ONLY a raw JSON list of objects. DO NOT include any comments or other text.
        {{
            "question_type": "multiple_choice" | "fill_blank" | "true_false",
            "subject": "{subject}",
            "chapter": "{chapter}",
            "topic": "Specific sub-topic from the text",
            "data": {{
                "question_text": "...",
                "options": ["...", "...", "...", "..."],
                "answer": "..." 
            }}
        }}
        """
        
        try:
            response = model.generate_content(prompt)
            res_text = response.text.strip()
            
            # Comprehensive JSON cleaning
            if "```json" in res_text:
                res_text = res_text.split("```json")[1].split("```")[0].strip()
            elif "```" in res_text:
                res_text = res_text.split("```")[1].split("```")[0].strip()
            
            # Remove any leading/trailing text that isn't part of the JSON array
            start_idx = res_text.find("[")
            end_idx = res_text.rfind("]")
            if start_idx != -1 and end_idx != -1:
                res_text = res_text[start_idx:end_idx+1]
                
            questions = json.loads(res_text)
            return questions
        except Exception as e:
            print(f"Error in Gemini for {chapter}: {e}")
            # Propagate rate limit error to handle it in loops
            if "429" in str(e) or "quota" in str(e).lower():
                raise e
            if 'res_text' in locals():
                 print(f"Raw response preview: {res_text[:200]}...")
            return []

    @staticmethod
    async def generate_questions_for_topic(text: str, topic: str, chapter: str, subject: str) -> List[Dict]:
        """Generate 30 questions for a specific topic."""
        # Find relevant text for the topic
        # For now, we'll provide a chunk of text. In a refined version, we'd search for the topic.
        # But since we want 30 questions, we need enough context.
        # We'll use a sliding window or a large enough chunk.
        
        prompt = f"""
        You are an expert Physics teacher. Based on the provided textbook material, generate 30 high-quality questions for the topic: '{topic}' from the chapter '{chapter}'.
        
        Text Material:
        {text[:15000]} 
        
        Requirements:
        1. Total Questions: 30
        2. Distribution: 
           - 10 Multiple Choice (MCQ)
           - 10 Fill-in-the-blank
           - 10 True/False
        3. Difficulty Categorization:
           - **Easy**: Direct definitions, facts, or simple recall (e.g., "What is the unit of...?").
           - **Medium**: Understanding concepts and simple numerical applications (e.g., "If mass is doubled, what happens to...?").
           - **Hard**: Complex multi-step reasoning, analytical problems, or "tricky" conceptual questions that require deep understanding.
        4. Accuracy: Must be scientifically correct.
        
        Output Format:
        Return ONLY a JSON list of objects with the following structure:
        {{
            "question_type": "multiple_choice" | "fill_blank" | "true_false",
            "difficulty": "easy" | "medium" | "hard",
            "subject": "{subject}",
            "chapter": "{chapter}",
            "topic": "{topic}",
            "data": {{
                "question_text": "...",
                "options": ["A", "B", "C", "D"], // Only for multiple_choice
                "answer": "A" | "word" | "True" // For MCQ use A, B, C or D
            }}
        }}
        """
        
        try:
            response = model.generate_content(prompt)
            res_text = response.text.strip()
            if "```json" in res_text:
                res_text = res_text.split("```json")[1].split("```")[0].strip()
            elif "```" in res_text:
                res_text = res_text.split("```")[1].strip()
                
            questions = json.loads(res_text)
            return questions
        except Exception as e:
            print(f"Error generating questions for {topic}: {e}")
            return []

    @staticmethod
    async def generate_summary_for_chapter(text: str, chapter: str, subject: str) -> str:
        """Generate a concise Markdown summary/revision notes for the chapter."""
        prompt = f"""
        You are an expert Physics teacher. Create a concise, high-quality Revision Summary for the chapter: '{chapter}'.
        Use the provided textbook material to extract key concepts, formulas, and definitions.
        
        Text Material:
        {text[:20000]}
        
        Requirements:
        1. Format: Use Markdown (Headings, Bullet points, Bold text).
        2. Content: Focus on core principles, essential formulas, and key definitions.
        3. Tone: Encouraging and easy to read for a 9th-grade student.
        4. Length: 500-800 words, covering everything important for a test.
        
        Output:
        Return ONLY the Markdown content. Do not include a preamble.
        """
        
        try:
            response = model.generate_content(prompt)
            return response.text.strip()
        except Exception as e:
            print(f"Error generating summary for {chapter}: {e}")
            return f"# {chapter}\n\nSummary generation failed. Please refer to your textbook for {chapter} notes."

    @classmethod
    async def process_textbook_pdf(cls, bucket_name: str, filename: str, subject: str, chapter_name: str):
        """Full pipeline: download, extract, identify topics, generate questions, save."""
        print(f"Processing {filename} from {bucket_name}...")
        
        # 1. Download from Supabase Storage
        try:
            pdf_bytes = supabase.storage.from_(bucket_name).download(filename)
        except Exception as e:
            print(f"Failed to download PDF: {e}")
            # Try local file if download fails (for user's specific setup)
            local_path = f"DAtabase_architecture/node/{filename}"
            if os.path.exists(local_path):
                print(f"Loading local file: {local_path}")
                with open(local_path, "rb") as f:
                    pdf_bytes = f.read()
            else:
                return {"error": f"Could not find {filename}"}

        # 2. Extract Text
        text = cls.extract_text_from_pdf(pdf_bytes)
        
        # 3. Generate Revision Summary
        print(f"Generating revision notes for {chapter_name}...")
        summary = await cls.generate_summary_for_chapter(text, chapter_name, subject)
        
        # 4. Identify Topics
        topics = await cls.identify_topics(text, chapter_name)
        print(f"Identified topics: {topics}")
        
        all_questions = []
        
        # 5. Generate Common Test Questions (Fixed 30 Easy) - PRIORITIZED
        print(f"Generating Common Test Questions for {chapter_name}...")
        common_questions = await cls.generate_common_test_questions(text, chapter_name, subject)
        
        if common_questions:
            try:
                # Save to common_test_questions table
                mapped_common = []
                for q in common_questions:
                    mapped_common.append({
                        "subject": q.get("subject", subject),
                        "chapter": q.get("chapter", chapter_name),
                        "topic": q.get("topic", "General"),
                        "question_type": q.get("question_type", "multiple_choice"),
                        "data": q.get("data")
                    })
                
                supabase.table("common_test_questions").insert(mapped_common).execute()
                print(f"Saved {len(mapped_common)} Common Test questions.")
            except Exception as e:
                print(f"Error saving common test questions: {e}")

        # Wait to avoid rate limits
        import asyncio
        await asyncio.sleep(5)

        # 6. Generate Questions for each topic (Adaptive)
        for topic in topics:
            print(f"Generating questions for topic: {topic}...")
            topic_questions = await cls.generate_questions_for_topic(text, topic, chapter_name, subject)
            all_questions.extend(topic_questions)
            # Wait between topics
            await asyncio.sleep(5)
            
        # 7. Save to Database (Adaptive Content)
        results = {"status": "partial_success", "questions_generated": 0, "summary_generated": False}
        
        # Save Summary to 'textbook' table (assuming it has a 'notes' or 'summary' column, 
        # or we'll try to upsert it)
        try:
            # Upsert into textbook table
            # We assume unique on (subject, grade, chapter)
            supabase.table("textbook").upsert({
                "subject": subject,
                "chapter": chapter_name,
                "grade": "9",
                "notes": summary
            }).execute()
            results["summary_generated"] = True
        except Exception as e:
            print(f"Error saving summary to textbook table: {e}")

        if all_questions:
            print(f"Saving {len(all_questions)} questions to database...")
            try:
                # Supabase insert expects a list of dicts
                res = supabase.table("learning_content").insert(all_questions).execute()
                results["status"] = "success"
                results["questions_generated"] = len(all_questions)
                results["topics"] = topics
            except Exception as e:
                print(f"Error saving to DB: {e}")
                results["error"] = str(e)
        
        return results

    @classmethod
    async def process_all_in_bucket(cls, bucket_name: str, subject: str):
        """Scan bucket and process every PDF found."""
        try:
            # List files in bucket (Supabase Storage API)
            # storage.from_(bucket).list() returns a list of dicts: [{'name': '...'}, ...]
            files = supabase.storage.from_(bucket_name).list()
            
            summary = {
                "total_found": 0,
                "processed": [],
                "errors": []
            }
            
            for f in files:
                fname = f.get('name', '')
                if fname.lower().endswith('.pdf'):
                    summary["total_found"] += 1
                    # Derive Chapter Name from Filename (e.g. "Force.pdf" -> "Force")
                    chapter_name = os.path.splitext(fname)[0]
                    # Clean up filename (replace underscores with spaces if needed)
                    chapter_name_clean = chapter_name.replace('_', ' ').title()
                    
                    print(f"Bulk Processing: Found {fname}, treating as Chapter: {chapter_name_clean}")
                    
                    try:
                        # We await here to not overload the API/LLM limits (Sequential processing)
                        # In a rugged sys, this might be a queue.
                        res = await cls.process_textbook_pdf(bucket_name, fname, subject, chapter_name_clean)
                        summary["processed"].append({
                            "file": fname,
                            "status": res.get("status"), 
                            "questions": res.get("questions_generated")
                        })
                    except Exception as e:
                        summary["errors"].append({"file": fname, "error": str(e)})
            
            return summary
            
        except Exception as e:
            print(f"Bulk processing error: {e}")
            return {"error": str(e)}
