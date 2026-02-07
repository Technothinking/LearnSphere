from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_NAME: str = "Adaptive Learning Platform"
    API_V1_STR: str = "/api/v1"

    # Database
    DATABASE_URL: str = "sqlite:///./adaptive_learning.db"

    # Security
    SECRET_KEY: str = "super-secret-key"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # RL Model
    PPO_MODEL_PATH: str = "rl_model/models/ppo_adaptive_learning.zip"

    class Config:
        env_file = ".env"


settings = Settings()
