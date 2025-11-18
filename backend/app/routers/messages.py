from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import get_current_user
from app.models import User, Match, Message
from app.schemas import MessageOut, MessageCreate

router = APIRouter()


def _get_match_for_user(match_id: int, current: User, db: Session) -> Match:
    match = (
        db.query(Match)
        .filter(Match.id == match_id, Match.is_active == True)  # noqa: E712
        .first()
    )
    if not match:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match not found")

    if current.id not in (match.user1_id, match.user2_id):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your match")
    return match


@router.get("/messages", response_model=List[MessageOut])
def list_messages(
    match_id: int,
    limit: int = 100,
    db: Session = Depends(get_db),
    current: User = Depends(get_current_user),
):
    """Сообщения внутри чата (матча), по умолчанию до 100 шт."""
    match = _get_match_for_user(match_id, current, db)

    q = (
        db.query(Message)
        .filter(Message.match_id == match.id)
        .order_by(Message.created_at.asc())
        .limit(max(1, min(limit, 500)))
    )

    return q.all()


@router.post("/messages", response_model=MessageOut, status_code=status.HTTP_201_CREATED)
def send_message(
    payload: MessageCreate,
    db: Session = Depends(get_db),
    current: User = Depends(get_current_user),
):
    """Отправить сообщение в матч (чат)."""
    match = _get_match_for_user(payload.match_id, current, db)

    msg = Message(
        match_id=match.id,
        sender_id=current.id,
        body=payload.body,
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)
    return msg
