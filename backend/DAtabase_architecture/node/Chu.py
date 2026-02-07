"""
Chunk text into smaller sections for question generation
"""
import re


def chunk_text(state: dict) -> dict:
    """
    LangGraph node: Split extracted pages into smaller chunks
    
    Input state:
        - pages: list of {page_num, text, book_name, chapter} dicts
    
    Output state:
        - chunks: list of {text, section, chapter, page_num} dicts
    """
    pages = state.get("pages", [])
    chunks = []
    
    for page in pages:
        text = page.get("text", "")
        chapter = page.get("chapter", "Unknown")
        page_num = page.get("page_num", 0)
        
        # Split by double newlines (paragraphs)
        blocks = re.split(r"\n\n+", text)
        
        for block in blocks:
            block = block.strip()
            if len(block) < 50:  # Skip very short blocks
                continue
            
            # Determine section type
            if re.search(r"(Exercise|Q\d+|Question|Problem)", block, re.IGNORECASE):
                section = "exercise"
            elif re.search(r"(Example|Solution)", block, re.IGNORECASE):
                section = "example"
            else:
                section = "theory"
            
            chunks.append({
                "text": block,
                "section": section,
                "chapter": chapter,
                "page_num": page_num
            })
    
    state["chunks"] = chunks
    print(f"Created {len(chunks)} chunks from {len(pages)} pages")
    return state
