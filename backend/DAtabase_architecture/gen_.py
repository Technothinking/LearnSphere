from genni import generate_questions

chunks = [
    {
        "chapter": "Motion",
        "section": "theory",
        "text": "Motion is the change in position of an object with respect to time."
    }
]

questions = generate_questions(chunks)

for q in questions:
    print("Chapter:", q["chapter"])
    print("Type:", q["type"])
    print("Question:", q["question_text"])

    if q["type"] == "mcq":
        for i, opt in enumerate(q["options"], start=1):
            print(f"  {i}. {opt}")
        print("Answer:", q["answer"])

    if q["type"] == "fill_blank":
        print("Answer:", q["answer"])

    print("-" * 60)
