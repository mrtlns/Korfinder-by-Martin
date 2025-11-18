import os, re
from datetime import datetime, timedelta, timezone
from jose import jwt
from passlib.context import CryptContext

SECRET = os.getenv("JWT_SECRET", "dev-secret")
ALGO = "HS256"
EXPIRES_MIN = int(os.getenv("JWT_EXPIRES_MIN", "1440"))
pwd = CryptContext(schemes=["bcrypt"], deprecated="auto")

EMAIL_RE = re.compile(r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$")
PASS_RE  = re.compile(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$")

def hash_password(raw: str) -> str:        return pwd.hash(raw)
def verify_password(raw: str, hashed: str) -> bool: return pwd.verify(raw, hashed)
def validate_email(email: str) -> bool:    return bool(EMAIL_RE.match(email))
def validate_password_strength(p: str) -> bool: return bool(PASS_RE.match(p))

def create_access_token(sub: str) -> str:
    now = datetime.now(timezone.utc)
    payload = {"sub": sub, "iat": int(now.timestamp()), "exp": int((now + timedelta(minutes=EXPIRES_MIN)).timestamp())}
    return jwt.encode(payload, SECRET, algorithm=ALGO)
