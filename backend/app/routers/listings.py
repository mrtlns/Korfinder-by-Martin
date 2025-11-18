from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import get_current_user
from app.models import Listing, Subject, User, UserRole
from app.schemas import ListingCreate, ListingOut, ListingUpdate

router = APIRouter(prefix="/listings")


def serialize_listing(listing: Listing) -> ListingOut:
    owner = listing.owner
    subject = listing.subject
    owner_id = owner.id if owner else None
    return ListingOut(
        id=listing.id,
        owner_id=owner_id,
        tutor_id=owner_id,  # historical field kept for backwards compatibility
        title=listing.title,
        description=listing.description,
        subject=subject.name if subject else None,
        level=listing.level,
        price_per_hour=listing.hourly_rate,
        city=listing.city,
        is_published=listing.is_published,
        created_at=listing.created_at,
        photo_url=listing.photo_url,
        role=owner.role.value if owner and owner.role else None,
    )


@router.post("", response_model=ListingOut, status_code=status.HTTP_201_CREATED)
def create_listing(
    payload: ListingCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.role != UserRole.tutor:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only tutors can create listings",
        )

    subject = db.query(Subject).get(payload.subject_id)
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Subject not found",
        )

    listing = Listing(owner_id=current_user.id, **payload.dict())
    db.add(listing)
    db.commit()
    db.refresh(listing)
    return serialize_listing(listing)


@router.get("/me", response_model=List[ListingOut])
def my_listings(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    listings = (
        db.query(Listing)
        .filter(Listing.owner_id == current_user.id)
        .order_by(Listing.created_at.desc())
        .all()
    )
    return [serialize_listing(item) for item in listings]


@router.get("/{listing_id}", response_model=ListingOut)
def get_listing(
    listing_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    listing = db.query(Listing).get(listing_id)
    if not listing:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    if listing.owner_id != current_user.id and current_user.role == UserRole.tutor:
        # репетитор может запрашивать только свои объявления, ученику можно смотреть всех
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
    return serialize_listing(listing)


@router.patch("/{listing_id}", response_model=ListingOut)
def update_listing(
    listing_id: int,
    payload: ListingUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    listing = db.query(Listing).get(listing_id)
    if not listing:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    if listing.owner_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    data = payload.dict(exclude_unset=True)
    if "subject_id" in data:
        subject = db.query(Subject).get(data["subject_id"])
        if not subject:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Subject not found",
            )

    for key, value in data.items():
        setattr(listing, key, value)

    db.add(listing)
    db.commit()
    db.refresh(listing)
    return serialize_listing(listing)


@router.delete("/{listing_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_listing(
    listing_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    listing = db.query(Listing).get(listing_id)
    if not listing:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    if listing.owner_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    db.delete(listing)
    db.commit()
    return None
