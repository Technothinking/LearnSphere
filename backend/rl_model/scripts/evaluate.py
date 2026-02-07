# rl_model/scripts/evaluate.py
"""
Evaluate PPO policy using a set of test transitions.
"""
from rl_model.persistence.rollout_logger import RolloutLogger
from rl_model.model.ppo_agent import PPOAgent

def main():
    logger = RolloutLogger()
    transitions = logger.read_all_transitions()

    if not transitions:
        print("No transitions to evaluate.")
        return

    agent = PPOAgent()
    correct = 0
    total = len(transitions)

    for t in transitions:
        state = list(t["state"].values())
        predicted_action = agent.predict(state)
        if predicted_action == t["action"]:
            correct += 1

    accuracy = correct / total * 100
    print(f"PPO action prediction accuracy on logged transitions: {accuracy:.2f}%")

if __name__ == "__main__":
    main()
