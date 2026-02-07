from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# API routers
from app.api.v1.auth import router as auth_router
from app.api.v1.students import router as students_router
from app.api.v1.quizzes import router as quizzes_router
from app.api.v1.rl_policy import router as rl_router
from app.api.v1.content import router as content_router

# App metadata
app = FastAPI(
    title="Adaptive Learning Platform API",
    description="Backend for PPO-based adaptive learning system using real student data",
    version="1.0.0"
)

# -----------------------------
# CORS (for Flutter frontend)
# -----------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False, # Disable for '*' origins if not needed
    allow_methods=["*"],
    allow_headers=["*"],
)

# -----------------------------
# Health Check
# -----------------------------
@app.get("/", tags=["Health"])
def health_check():
    return {
        "status": "running",
        "message": "Adaptive Learning Backend is up 🚀"
    }

# -----------------------------
# API Routers
# -----------------------------
app.include_router(
    auth_router,
    prefix="/api/v1/auth",
    tags=["Authentication"]
)

app.include_router(
    students_router,
    prefix="/api/v1/students",
    tags=["Students"]
)

app.include_router(
    quizzes_router,
    prefix="/api/v1/quizzes",
    tags=["Quizzes"]
)

app.include_router(
    rl_router,
    prefix="/api/v1/rl",
    tags=["Adaptive Policy (PPO)"]
)

app.include_router(
    content_router,
    prefix="/api/v1/content",
    tags=["Content Generation"]
)

# -----------------------------
# Startup & Shutdown Events
# -----------------------------
@app.on_event("startup")
async def startup_event():
    """
    Initialize heavy components here:
    - Load PPO model
    - Initialize DB connection
    """
    # Create Tables if they don't exist
    from app.core.database import engine, Base
    from app.models import student, quiz, attempt, rl_transition, mastery, performance, permission
    Base.metadata.create_all(bind=engine)
    
    print("🚀 Backend startup complete")

@app.on_event("shutdown")
async def shutdown_event():
    """
    Cleanup resources
    """
    print("🛑 Backend shutdown complete")
