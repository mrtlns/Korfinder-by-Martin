from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db import get_db
from app.models import User, UserRole
from app.schemas import RegisterIn, LoginIn, AuthOut, UserOut
from app.security import validate_email, validate_password_strength, hash_password, verify_password, create_access_token
from app.deps import get_current_user

router = APIRouter()

@router.post("/register", response_model=AuthOut)
def register(payload: RegisterIn, db: Session = Depends(get_db)):
    if not validate_email(payload.email): raise HTTPException(400, "Invalid email")
    if not validate_password_strength(payload.password): raise HTTPException(400, "Weak password")
    if db.query(User).filter(User.email == payload.email.lower()).first():
        raise HTTPException(status_code=409, detail="Email already registered")
    user = User(first_name=payload.first_name.strip(),
                last_name=payload.last_name.strip(),
                email=payload.email.lower(),
                hashed_password=hash_password(payload.password),
                role=UserRole(payload.role),
                onboarding_done=False)
    db.add(user); db.commit(); db.refresh(user)
    return AuthOut(token=create_access_token(user.email), new_user=True)

@router.post("/login", response_model=AuthOut)
def login(payload: LoginIn, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email.lower()).first()
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    return AuthOut(token=create_access_token(user.email), new_user=False)

@router.get("/me", response_model=UserOut)
def me(current: User = Depends(get_current_user)):
    return UserOut(id=current.id, first_name=current.first_name, last_name=current.last_name,
                   email=current.email, role=current.role.value, onboarding_done=current.onboarding_done)
