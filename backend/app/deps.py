from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import User
from app.security import ALGO, SECRET

auth_scheme = HTTPBearer()


def get_current_user(
    creds: HTTPAuthorizationCredentials = Depends(auth_scheme),
    db: Session = Depends(get_db),
) -> User:
    token = creds.credentials
    try:
        payload = jwt.decode(token, SECRET, algorithms=[ALGO])
        email = payload.get("sub")
    except JWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        ) from exc

    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )
    return user
