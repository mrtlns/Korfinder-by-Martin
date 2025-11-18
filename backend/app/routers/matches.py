from typing import List

from fastapi import APIRouter, Depends
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import get_current_user
from app.models import User, Match
from app.schemas import MatchOut

router = APIRouter()


@router.get("/matches", response_model=List[MatchOut])
def list_matches(
    current: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    rows = (
        db.query(Match)
        .filter(Match.is_active == True)  # noqa: E712
        .filter(or_(Match.user1_id == current.id, Match.user2_id == current.id))
        .order_by(Match.created_at.desc())
        .all()
    )

    result: List[MatchOut] = []
    for m in rows:
        other_id = m.user2_id if m.user1_id == current.id else m.user1_id
        result.append(
            MatchOut(
                id=m.id,
                user_id=current.id,
                target_user_id=other_id,
                created_at=m.created_at,
            )
        )
    return result
