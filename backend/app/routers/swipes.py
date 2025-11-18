from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import get_current_user
from app.models import User, Swipe, Match
from app.schemas import SwipeIn, SwipeOut

router = APIRouter()


@router.post("/swipes", response_model=SwipeOut)
def swipe(
    payload: SwipeIn,
    current: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    current_user_id = current.id
    target_user_id = payload.target_user_id

    # найдём или создадим запись свайпа
    swipe = (
        db.query(Swipe)
        .filter(Swipe.from_user_id == current_user_id, Swipe.to_user_id == target_user_id)
        .first()
    )
    if swipe is None:
        swipe = Swipe(
            from_user_id=current_user_id,
            to_user_id=target_user_id,
            like=payload.like,
        )
        db.add(swipe)
    else:
        swipe.like = payload.like

    is_match = False

    if payload.like:
        # есть ли обратный лайк?
        reverse = (
            db.query(Swipe)
            .filter(
                Swipe.from_user_id == target_user_id,
                Swipe.to_user_id == current_user_id,
                Swipe.like == True,  # noqa: E712
            )
            .first()
        )
        if reverse:
            # нормализуем пару (user1_id < user2_id), чтобы не было дублей
            user1_id, user2_id = sorted([current_user_id, target_user_id])
            match = (
                db.query(Match)
                .filter(Match.user1_id == user1_id, Match.user2_id == user2_id)
                .first()
            )
            if match is None:
                match = Match(user1_id=user1_id, user2_id=user2_id)
                db.add(match)
            is_match = True

    db.commit()
    return SwipeOut(match=is_match)
