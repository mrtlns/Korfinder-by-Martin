from typing import List, Optional
from sqlalchemy import func, and_

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import get_current_user
from app.models import User, UserRole, Listing
from app.schemas import ListingOut

router = APIRouter()


def _to_listing_out(entity: Listing) -> ListingOut:
    owner = entity.owner
    subject = entity.subject
    return ListingOut(
        id=entity.id,
        tutor_id=owner.id if owner else None,
        title=entity.title,
        description=entity.description,
        subject=subject.name if subject else None,
        level=entity.level,
        price_per_hour=entity.hourly_rate,
        city=entity.city,
        is_published=entity.is_published,
        created_at=entity.created_at,
        photo_url=entity.photo_url,
        role=owner.role.value if owner and owner.role else None,
    )


@router.get("/feed", response_model=List[ListingOut])
def feed(
    current_user: User = Depends(get_current_user),
    exclude_ids: Optional[str] = Query(default=None, description="1,2,3"),
    limit: int = 20,
    db: Session = Depends(get_db),
):
    # Базовый запрос: опубликованные объявления, не свои
    base_q = (
        db.query(Listing)
        .join(User, Listing.owner_id == User.id)
        .filter(Listing.is_published == True)  # noqa: E712
        .filter(Listing.owner_id != current_user.id)
    )

    # student видит только tutorów, tutor — только uczniów
    if current_user.role == UserRole.student:
        base_q = base_q.filter(User.role == UserRole.tutor)
    else:
        base_q = base_q.filter(User.role == UserRole.student)

    # исключаем уже просмотренные
    if exclude_ids:
        ex = {int(x) for x in exclude_ids.split(",") if x.strip().isdigit()}
        if ex:
            base_q = base_q.filter(~Listing.id.in_(ex))

    # ⚠️ ВАЖНО: берём по ОДНОМУ объявлению на владельца (самое свежее)
    subq = (
        base_q.with_entities(
            Listing.owner_id,
            func.max(Listing.created_at).label("max_created_at"),
        )
        .group_by(Listing.owner_id)
        .subquery()
    )

    q = (
        db.query(Listing)
        .join(
            subq,
            and_(
                Listing.owner_id == subq.c.owner_id,
                Listing.created_at == subq.c.max_created_at,
            ),
        )
        .order_by(Listing.created_at.desc())
        .limit(max(1, min(limit, 100)))
    )

    listings = q.all()
    return [_to_listing_out(l) for l in listings]