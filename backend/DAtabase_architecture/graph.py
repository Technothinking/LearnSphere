"""
LangGraph pipeline for question generation from PDF books
Flow: extract -> chunk -> generate -> classify -> save
"""
from langgraph.graph import StateGraph, END
from node.Extract import extract_text
from node.Chu import chunk_text
from node.gen import generate_questions
from node.cliaas import classify_type
from node.Mongo import save_to_mongo

# Define the graph with dict state
graph = StateGraph(dict)

# Add nodes
graph.add_node("extract", extract_text)
graph.add_node("chunk", chunk_text)
graph.add_node("generate", generate_questions)
graph.add_node("classify", classify_type)
graph.add_node("save", save_to_mongo)

# Set entry point
graph.set_entry_point("extract")

# Define edges (linear flow)
graph.add_edge("extract", "chunk")
graph.add_edge("chunk", "generate")
graph.add_edge("generate", "classify")
graph.add_edge("classify", "save")
graph.add_edge("save", END)

# Compile the graph
app = graph.compile()

if __name__ == "__main__":
    # Test the graph visualization
    try:
        print("Graph compiled successfully!")
        print("Nodes:", list(app.nodes.keys()))
    except Exception as e:
        print(f"Error: {e}")