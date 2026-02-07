def generate_questions(chunks):
    questions = [
        # 1. Fill in the Blank
        {
            "chapter": "Motion",
            "type": "fill_blank",
            "question_text": "Motion is the change in _____ of an object with respect to time.",
            "answer": "position"
        },

        # 2. MCQ
        {
            "chapter": "Motion",
            "type": "mcq",
            "question_text": "Which of the following best defines motion?",
            "options": [
                "Change in speed only",
                "Change in direction only",
                "Change in position with respect to time",
                "Change in shape"
            ],
            "answer": "Change in position with respect to time"
        },

        # 3. True / False
        {
            "chapter": "Motion",
            "type": "true_false",
            "question_text": "An object is said to be in motion if it changes its position with time.",
            "answer": "True"
        },

        # 4. Fill in the Blank
        {
            "chapter": "Motion",
            "type": "fill_blank",
            "question_text": "The study of motion without considering its causes is called _____.",
            "answer": "kinematics"
        },

        # 5. MCQ
        {
            "chapter": "Motion",
            "type": "mcq",
            "question_text": "Which physical quantity has both magnitude and direction?",
            "options": [
                "Speed",
                "Distance",
                "Displacement",
                "Time"
            ],
            "answer": "Displacement"
        },

        # 6. True / False
        {
            "chapter": "Motion",
            "type": "true_false",
            "question_text": "Speed can be negative.",
            "answer": "False"
        }
    ]

    return questions
