from fastapi import APIRouter, HTTPException

router = APIRouter()

@router.post("/login")
def login(email: str, password: str):
    # Dummy auth for prototype
    if email and password:
        return {
            "message": "Login successful",
            "token": "dummy-jwt-token"
        }
    raise HTTPException(status_code=401, detail="Invalid credentials")


@router.post("/signup")
def signup(email: str, password: str, name: str):
    return {
        "message": "User registered successfully",
        "user": {
            "email": email,
            "name": name
        }
    }
