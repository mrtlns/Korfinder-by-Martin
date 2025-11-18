from datetime import datetime
from typing import List, Optional, Literal

from pydantic import BaseModel, EmailStr, AnyUrl


# базовый класс для ORM-объектов
class ORMBase(BaseModel):
    class Config:
        orm_mode = True


# ---------- Subjects ----------


class SubjectOut(ORMBase):
    id: int
    name: str


# ---------- Auth ----------


class RegisterIn(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    role: Literal["student", "tutor"]
    password: str


class LoginIn(BaseModel):
    email: EmailStr
    password: str


class AuthOut(BaseModel):
    token: str
    new_user: Optional[bool] = None


class UserOut(ORMBase):
    id: int
    first_name: str
    last_name: str
    email: EmailStr
    role: str
    onboarding_done: bool


# ---------- Onboarding ----------


class OnboardingIn(BaseModel):
    online: bool = True
    offline: bool = False
    group_classes: bool = False
    city: Optional[str] = None
    hourly_rate: Optional[float] = None
    # свободный список типа "matura", "egzamin", ...
    types: Optional[List[str]] = None
    # список id предметов (Subject.id)
    subjects: Optional[List[int]] = None


# ---------- Listings / Feed ----------


class ListingOut(ORMBase):
    """
    Форма, в которой карточка отдаётся во feed и в iOS.
    Названия полей в snake_case -> в Swift через .convertFromSnakeCase
    """

    id: int
    tutor_id: Optional[int] = None

    title: str
    description: Optional[str] = None

    subject: Optional[str] = None
    level: Optional[str] = None

    price_per_hour: Optional[float] = None
    city: Optional[str] = None
    is_published: Optional[bool] = None
    created_at: Optional[datetime] = None

    photo_url: Optional[AnyUrl] = None
    role: Optional[str] = None


class ListingCreate(BaseModel):
    subject_id: int
    title: str
    description: str

    city: Optional[str] = None
    is_online: bool = True
    is_offline: bool = False

    hourly_rate: Optional[float] = None
    level: Optional[str] = None
    is_published: bool = True
    photo_url: Optional[AnyUrl] = None


class ListingUpdate(BaseModel):
    subject_id: Optional[int] = None
    title: Optional[str] = None
    description: Optional[str] = None

    city: Optional[str] = None
    is_online: Optional[bool] = None
    is_offline: Optional[bool] = None

    hourly_rate: Optional[float] = None
    level: Optional[str] = None
    is_published: Optional[bool] = None
    photo_url: Optional[AnyUrl] = None


# ---------- Swipes & Matches ----------


class SwipeIn(BaseModel):
    target_user_id: int
    like: bool


class SwipeOut(BaseModel):
    match: bool

class MatchOut(ORMBase):
    id: int
    user_id: int
    target_user_id: int
    created_at: datetime

class MessageOut(ORMBase):
    id: int
    match_id: int
    sender_id: int
    body: str
    created_at: datetime


class MessageCreate(BaseModel):
    match_id: int
    body: str

