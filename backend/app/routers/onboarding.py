from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import get_current_user
from app.models import (
    User,
    UserRole,
    UserPreference,
    Subject,
    Listing,
)
from app.schemas import OnboardingIn

router = APIRouter()


def _upsert_listing_from_profile(user: User, db: Session) -> None:
    """
    Для репетитора гарантирует, что есть ровно одно объявление,
    и его поля синхронизированы с профилем/преференциями.
    """
    if user.role != UserRole.tutor:
        return

    pref = user.preferences
    subject = user.subjects[0] if user.subjects else None

    # Берём существующее объявление (если есть) или создаём новое
    listing = (
        db.query(Listing)
        .filter(Listing.owner_id == user.id)
        .order_by(Listing.created_at.asc())
        .first()
    )

    if listing is None:
        listing = Listing(owner_id=user.id)

    # Поля заполняем на основании профиля/преференций
    listing.subject_id = subject.id if subject else None
    listing.title = (
        f"Korepetycje z {subject.name}" if subject else "Korepetycje"
    )
    listing.description = listing.description or ""  # пока пустое, будет UI-редактор — дополнишь
    if pref:
        listing.city = pref.city
        listing.is_online = pref.online
        listing.is_offline = pref.offline
        listing.hourly_rate = pref.hourly_rate
    else:
        listing.city = None
        listing.is_online = True
        listing.is_offline = False
        listing.hourly_rate = None

    listing.level = None
    listing.is_published = True
    # photo_url оставляем как есть — позже добавим загрузку аватарки

    db.add(listing)
    db.commit()
    db.refresh(listing)


@router.post("/onboarding")
def save_onboarding(
    data: OnboardingIn,
    current: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # preferences
    pref = current.preferences or UserPreference(user_id=current.id)
    pref.online = data.online
    pref.offline = data.offline
    pref.group_classes = data.group_classes
    pref.city = data.city
    pref.hourly_rate = data.hourly_rate
    pref.types = ",".join(data.types) if data.types else None
    db.add(pref)

    # subjects
    if data.subjects:
        subjects = db.query(Subject).filter(Subject.id.in_(data.subjects)).all()
        current.subjects = subjects

    current.onboarding_done = True
    db.add(current)
    db.commit()
    db.refresh(current)

    # 🔁 каждый раз после обновления анкеты — синхронизируем объявление
    _upsert_listing_from_profile(current, db)

    return {"ok": True}