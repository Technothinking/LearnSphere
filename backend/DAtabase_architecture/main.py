"""
Main entry point for Question Generation System
Fetches books from Supabase and generates questions using T5
"""
from graph import app
from node.supabase_client import list_books, download_book


def run_pipeline(book_name: str = None, chapter: str = "Unknown"):
    """
    Run the complete question generation pipeline
    
    Args:
        book_name: Name of the PDF in Supabase bucket (if None, uses first available)
        chapter: Chapter name for categorization
    """
    print("=" * 60)
    print("Question Generation System - T5 Transformer")
    print("=" * 60)
    
    # Step 1: List available books
    print("\n[1] Checking Supabase for available books...")
    books = list_books()
    
    if not books:
        print("No books found in Supabase 'textbook' bucket!")
        print("Please upload a PDF to the bucket first.")
        return
    
    print(f"Found {len(books)} books: {books}")
    
    # Step 2: Select book to process
    if book_name is None:
        book_name = books[0]
    elif book_name not in books:
        print(f"Book '{book_name}' not found. Using: {books[0]}")
        book_name = books[0]
    
    print(f"\n[2] Downloading '{book_name}' from Supabase...")
    pdf_bytes = download_book(book_name)
    
    if pdf_bytes is None:
        print("Failed to download book!")
        return
    
    print(f"Downloaded {len(pdf_bytes)} bytes")
    
    # Step 3: Run LangGraph pipeline
    print("\n[3] Running question generation pipeline...")
    print("-" * 40)
    
    initial_state = {
        "pdf_bytes": pdf_bytes,
        "book_name": book_name,
        "chapter": chapter
    }
    
    result = app.invoke(initial_state)
    
    # Step 4: Display results
    print("\n" + "=" * 60)
    print("GENERATED QUESTIONS")
    print("=" * 60)
    
    questions = result.get("questions", [])
    
    if not questions:
        print("No questions were generated.")
        return
    
    for i, q in enumerate(questions, 1):
        print(f"\n[{i}] {q['type'].upper()}")
        print(f"Chapter: {q.get('chapter', 'Unknown')}")
        print(f"Question:\n{q['question_text']}")
        print("-" * 40)
    
    # Summary
    print(f"\n✓ Total questions generated: {len(questions)}")
    print(f"✓ Saved to MongoDB: {result.get('saved', False)}")
    
    return result


if __name__ == "__main__":
    # Run with default settings
    run_pipeline(chapter="Physics")
