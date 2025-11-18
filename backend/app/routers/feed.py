from typing import List, Optional, Sequence
from sqlalchemy import func, and_

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session, joinedload

from app.db import get_db
from app.deps import get_current_user
from app.models import User, UserRole, Listing
from app.schemas import ListingOut
from app.routers.listings import serialize_listing

router = APIRouter()


@router.get("/feed", response_model=List[ListingOut])
def feed(
    current_user: User = Depends(get_current_user),
    exclude_ids: Optional[str] = Query(default=None, description="1,2,3"),
    limit: int = 20,
    db: Session = Depends(get_db),
):
    parsed_exclude: set[int] = set()
    if exclude_ids:
        parsed_exclude = {
            int(x) for x in exclude_ids.split(",") if x.strip().lstrip("-").isdigit()
        }

    safe_limit = max(1, min(limit, 100))

    if current_user.role == UserRole.tutor:
        return _student_profiles_feed(
            current_user=current_user,
            limit=safe_limit,
            exclude_ids=parsed_exclude,
            db=db,
        )

    listings = _tutor_listings_feed(
        current_user=current_user,
        limit=safe_limit,
        exclude_ids=parsed_exclude,
        db=db,
    )
    return listings


def _tutor_listings_feed(
    *,
    current_user: User,
    limit: int,
    exclude_ids: set[int],
    db: Session,
) -> List[ListingOut]:
    base_q = (
        db.query(Listing)
        .join(User, Listing.owner_id == User.id)
        .filter(Listing.is_published == True)  # noqa: E712
        .filter(Listing.owner_id != current_user.id)
        .filter(User.role == UserRole.tutor)
    )

    if exclude_ids:
        base_q = base_q.filter(~Listing.id.in_(exclude_ids))

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
        .limit(limit)
    )

    listings = [serialize_listing(item) for item in q.all()]
    return listings


def _student_profiles_feed(
    *,
    current_user: User,
    limit: int,
    exclude_ids: set[int],
    db: Session,
) -> List[ListingOut]:
    candidates: Sequence[User] = (
        db.query(User)
        .options(
            joinedload(User.preferences),
            joinedload(User.subjects),
        )
        .filter(User.role == UserRole.student)
        .filter(User.onboarding_done == True)  # noqa: E712
        .filter(User.id != current_user.id)
        .order_by(User.created_at.desc())
        .limit(limit * 3)
        .all()
    )

    feed_items: List[ListingOut] = []
    for student in candidates:
        listing = _serialize_student_profile(student)
        if listing.id in exclude_ids:
            continue
        feed_items.append(listing)
        if len(feed_items) >= limit:
            break
    return feed_items


def _serialize_student_profile(user: User) -> ListingOut:
    pref = user.preferences
    subject_name = user.subjects[0].name if user.subjects else None

    def _split_types(raw: Optional[str]) -> List[str]:
        if not raw:
            return []
        return [piece.strip() for piece in raw.split(",") if piece.strip()]

    types = _split_types(pref.types if pref else None)
    level = ", ".join(types) if types else None

    desc_parts: List[str] = []
    if types:
        desc_parts.append("Potrzebuje wsparcia w: " + ", ".join(types) + ".")
    if pref:
        if pref.online and pref.offline:
            desc_parts.append("Zajęcia online lub stacjonarnie.")
        elif pref.online:
            desc_parts.append("Preferuje zajęcia online.")
        elif pref.offline:
            desc_parts.append("Preferuje zajęcia stacjonarne.")
        if pref.city:
            desc_parts.append(f"Miasto: {pref.city}.")
    description = " ".join(desc_parts) or "Aktywny uczeń szuka korepetycji."

    title_subject = f" z {subject_name}" if subject_name else ""
    title = f"{user.first_name} szuka korepetytora{title_subject}"

    return ListingOut(
        id=-user.id,
        owner_id=user.id,
        tutor_id=user.id,
        title=title,
        description=description,
        subject=subject_name,
        level=level,
        price_per_hour=pref.hourly_rate if pref else None,
        city=pref.city if pref else None,
        is_published=True,
        created_at=user.created_at,
        photo_url=None,
        role=user.role.value,
    )
