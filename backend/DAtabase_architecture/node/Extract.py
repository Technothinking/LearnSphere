"""
Extract text from PDF books fetched from Supabase
"""
import fitz  # PyMuPDF
import io


def extract_text(state: dict) -> dict:
    """
    LangGraph node: Extract text from PDF bytes
    
    Input state:
        - pdf_bytes: bytes of the PDF file
        - book_name: name of the book
        - chapter: chapter name (optional)
    
    Output state:
        - pages: list of {page_num, text} dicts
    """
    pdf_bytes = state.get("pdf_bytes")
    book_name = state.get("book_name", "Unknown")
    chapter = state.get("chapter", "Unknown")
    
    if pdf_bytes is None:
        print("Error: No PDF bytes provided")
        state["pages"] = []
        return state
    
    try:
        # Open PDF from bytes
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")
        
        pages = []
        for page_num, page in enumerate(doc):
            text = page.get_text()
            if len(text.strip()) > 50:  # Skip nearly empty pages
                pages.append({
                    "page_num": page_num + 1,
                    "text": text.strip(),
                    "book_name": book_name,
                    "chapter": chapter
                })
        
        doc.close()
        state["pages"] = pages
        print(f"Extracted {len(pages)} pages from '{book_name}'")
        
    except Exception as e:
        print(f"Error extracting text: {e}")
        state["pages"] = []
    
    return state


def extract_from_file(file_path: str, chapter: str = "Unknown") -> dict:
    """Extract text from a local PDF file"""
    with open(file_path, "rb") as f:
        pdf_bytes = f.read()
    
    return extract_text({
        "pdf_bytes": pdf_bytes,
        "book_name": file_path,
        "chapter": chapter
    })
