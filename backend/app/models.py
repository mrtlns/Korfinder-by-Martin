from datetime import datetime
import enum

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Integer,
    String,
    Table,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from app.db import Base


class UserRole(str, enum.Enum):
    student = "student"
    tutor = "tutor"


# ассоциация user–subject
user_subject = Table(
    "user_subject",
    Base.metadata,
    Column("user_id", Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("subject_id", Integer, ForeignKey("subjects.id", ondelete="CASCADE"), primary_key=True),
)


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String(80), nullable=False)
    last_name = Column(String(80), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    role = Column(Enum(UserRole, name="user_role"), nullable=False, default=UserRole.student)
    onboarding_done = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    # отношения
    preferences = relationship(
        "UserPreference",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )
    subjects = relationship(
        "Subject",
        secondary=user_subject,
        back_populates="users",
    )

    listings = relationship(
        "Listing",
        back_populates="owner",
        cascade="all, delete-orphan",
    )

    sent_swipes = relationship(
        "Swipe",
        foreign_keys="Swipe.from_user_id",
        back_populates="from_user",
        cascade="all, delete-orphan",
    )
    received_swipes = relationship(
        "Swipe",
        foreign_keys="Swipe.to_user_id",
        back_populates="to_user",
        cascade="all, delete-orphan",
    )

    matches_as_user1 = relationship(
        "Match",
        foreign_keys="Match.user1_id",
        back_populates="user1",
        cascade="all, delete-orphan",
    )
    matches_as_user2 = relationship(
        "Match",
        foreign_keys="Match.user2_id",
        back_populates="user2",
        cascade="all, delete-orphan",
    )


class UserPreference(Base):
    __tablename__ = "user_preferences"

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    online = Column(Boolean, default=True)
    offline = Column(Boolean, default=False)
    group_classes = Column(Boolean, default=False)
    city = Column(String(80), nullable=True)
    hourly_rate = Column(Float, nullable=True)
    # строка с перечислением типов: "matura,egzamin,szkoła podstawowa"
    types = Column(String(200), nullable=True)

    user = relationship("User", back_populates="preferences")


class Subject(Base):
    __tablename__ = "subjects"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(120), unique=True, index=True, nullable=False)

    users = relationship(
        "User",
        secondary=user_subject,
        back_populates="subjects",
    )
    listings = relationship(
        "Listing",
        back_populates="subject",
        cascade="all, delete-orphan",
    )


class Listing(Base):
    """
    Ogłoszenie korepetytora (в будущем можно и для ucznia).

    Используется как источник данных для swipe-ленты (feed).
    """

    __tablename__ = "listings"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    subject_id = Column(
        Integer,
        ForeignKey("subjects.id", ondelete="RESTRICT"),
        nullable=True,
        index=True,
    )

    title = Column(String(200), nullable=False)
    description = Column(String(2000), nullable=False)
    level = Column(String(80), nullable=True)

    city = Column(String(120), nullable=True)
    is_online = Column(Boolean, default=True)
    is_offline = Column(Boolean, default=False)

    hourly_rate = Column(Float, nullable=True)

    is_published = Column(Boolean, default=True, index=True)
    photo_url = Column(String(500), nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)

    owner = relationship("User", back_populates="listings")
    subject = relationship("Subject", back_populates="listings")


class Swipe(Base):
    """
    Оценка другого пользователя (лайк / дизлайк).
    Матчи считаем по пользователям, а не по конкретным объявлениям.
    """

    __tablename__ = "swipes"

    id = Column(Integer, primary_key=True, index=True)
    from_user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    to_user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    like = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint("from_user_id", "to_user_id", name="uq_swipe_from_to"),
    )

    from_user = relationship(
        "User",
        foreign_keys=[from_user_id],
        back_populates="sent_swipes",
    )
    to_user = relationship(
        "User",
        foreign_keys=[to_user_id],
        back_populates="received_swipes",
    )


class Match(Base):

    __tablename__ = "matches"

    id = Column(Integer, primary_key=True, index=True)
    user1_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    user2_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True, nullable=False)

    __table_args__ = (
        UniqueConstraint("user1_id", "user2_id", name="uq_match_pair"),
    )

    user1 = relationship(
        "User",
        foreign_keys=[user1_id],
        back_populates="matches_as_user1",
    )
    user2 = relationship(
        "User",
        foreign_keys=[user2_id],
        back_populates="matches_as_user2",
    )

    messages = relationship(
        "Message",
        back_populates="match",
        cascade="all, delete-orphan",
        order_by="Message.created_at",
    )

class Message(Base):

    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)
    match_id = Column(
        Integer,
        ForeignKey("matches.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    sender_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    body = Column(String(2000), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    match = relationship("Match", back_populates="messages")
    sender = relationship("User")
