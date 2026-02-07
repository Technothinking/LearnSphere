"""
Test script - Run pipeline with local PDF file
"""
import sys
sys.path.insert(0, r'd:\IPD\DAtabase_architecture')

from graph import app
from node.Extract import extract_from_file

# Test with local PDF
local_pdf = r"d:\IPD\DAtabase_architecture\node\motion.pdf"

print("=" * 60)
print("Testing Question Generation with Local PDF")
print("=" * 60)

# Extract from local file
print("\n[1] Extracting text from local PDF...")
with open(local_pdf, "rb") as f:
    pdf_bytes = f.read()
print(f"PDF size: {len(pdf_bytes)} bytes")

# Run pipeline
print("\n[2] Running LangGraph pipeline...")
initial_state = {
    "pdf_bytes": pdf_bytes,
    "book_name": "motion.pdf",
    "chapter": "Motion"
}

result = app.invoke(initial_state)

# Display results
print("\n" + "=" * 60)
print("GENERATED QUESTIONS")
print("=" * 60)

questions = result.get("questions", [])
for i, q in enumerate(questions, 1):
    print(f"\n[{i}] {q['type'].upper()}")
    print(f"Question:\n{q['question_text']}")
    print("-" * 40)

print(f"\n✓ Total: {len(questions)} questions")
