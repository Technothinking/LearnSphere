import google.generativeai as genai

API_KEY = "AIzaSyCvluchfye2mn6jY7L-77HPC2OEfou_3-k"
genai.configure(api_key=API_KEY)

print("Checking available models...")
models = [m.name for m in genai.list_models() if "generateContent" in m.supported_generation_methods]
print(f"Found {len(models)} models: {models}")

for model_name in models:
    print(f"Testing {model_name}...", end=" ")
    try:
        model = genai.GenerativeModel(model_name)
        response = model.generate_content("hi")
        print("WORKING!")
        print(f"Recommended model name to use: {model_name}")
        break
    except Exception as e:
        print(f"FAILED: {e}")
