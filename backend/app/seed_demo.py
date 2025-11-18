# app/seed_demo.py
"""
Seed demo data for Korfinder.

Заполняет базу:
- предметами (Subject)
- несколькими репетиторами (User role=tutor) с ogłoszeniami (Listing)
- несколькими учениками (User role=student) с preferencjami (UserPreference)

Скрипт старается быть идемпотентным:
- если пользователь c данным email уже есть — не создаёт дубликат,
- если предмет с таким именем есть — переиспользует его.
"""

from datetime import datetime

from app.db import Base, engine, SessionLocal
from app.models import (
    User,
    UserRole,
    Subject,
    UserPreference,
    Listing,
)
from app.security import hash_password  # если у тебя другой модуль — поправь импорт


def get_or_create_subject(db, name: str) -> Subject:
    subj = db.query(Subject).filter(Subject.name == name).first()
    if subj:
        return subj
    subj = Subject(name=name)
    db.add(subj)
    db.flush()  # чтобы subj.id уже был
    return subj


def get_or_create_user(
    db,
    *,
    email: str,
    first_name: str,
    last_name: str,
    role: UserRole,
    password: str = "test1234",
) -> User:
    user = db.query(User).filter(User.email == email).first()
    if user:
        return user

    user = User(
        first_name=first_name,
        last_name=last_name,
        email=email,
        hashed_password=hash_password(password),
        role=role,
        onboarding_done=True,
        created_at=datetime.utcnow(),
    )
    db.add(user)
    db.flush()
    return user


def ensure_preferences(
    db,
    *,
    user: User,
    online: bool = True,
    offline: bool = False,
    group_classes: bool = False,
    city: str | None = None,
    hourly_rate: float | None = None,
    types: list[str] | None = None,
    subjects: list[Subject] | None = None,
) -> None:
    pref = user.preferences
    if not pref:
        pref = UserPreference(
            user_id=user.id,
            online=online,
            offline=offline,
            group_classes=group_classes,
            city=city,
            hourly_rate=hourly_rate,
            types=",".join(types) if types else None,
        )
        db.add(pref)
    else:
        pref.online = online
        pref.offline = offline
        pref.group_classes = group_classes
        pref.city = city
        pref.hourly_rate = hourly_rate
        pref.types = ",".join(types) if types else None

    if subjects is not None:
        # many-to-many: заменим текущий набор предметов
        user.subjects = subjects


def create_listing_if_missing(
    db,
    *,
    owner: User,
    subject: Subject,
    title: str,
    description: str,
    city: str | None,
    is_online: bool,
    is_offline: bool,
    hourly_rate: float | None,
    level: str | None = None,
) -> Listing:
    # простая проверка: есть ли у пользователя объявление по этому предмету с таким же title
    listing = (
        db.query(Listing)
        .filter(
            Listing.owner_id == owner.id,
            Listing.subject_id == subject.id,
            Listing.title == title,
        )
        .first()
    )
    if listing:
        return listing

    listing = Listing(
        owner_id=owner.id,
        subject_id=subject.id,
        title=title,
        description=description,
        city=city,
        is_online=is_online,
        is_offline=is_offline,
        hourly_rate=hourly_rate,
        level=level,
        is_published=True,
    )
    db.add(listing)
    db.flush()
    return listing


def seed():
    print(">>> Creating tables (if not exist)...")
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    try:
        print(">>> Seeding subjects...")
        subj_math = get_or_create_subject(db, "Matematyka")
        subj_english = get_or_create_subject(db, "Język angielski")
        subj_physics = get_or_create_subject(db, "Fizyka")
        subj_it = get_or_create_subject(db, "Informatyka")
        subjects_all = [subj_math, subj_english, subj_physics, subj_it]

        print(">>> Seeding tutors...")
        tutor_anna = get_or_create_user(
            db,
            email="anna.tutor@example.com",
            first_name="Anna",
            last_name="Kowalska",
            role=UserRole.tutor,
            password="tutor123",
        )
        tutor_piotr = get_or_create_user(
            db,
            email="piotr.math@example.com",
            first_name="Piotr",
            last_name="Nowak",
            role=UserRole.tutor,
            password="tutor123",
        )

        ensure_preferences(
            db,
            user=tutor_anna,
            online=True,
            offline=True,
            city="Koszalin",
            hourly_rate=80.0,
            types=["matura", "szkoła średnia"],
            subjects=[subj_english, subj_it],
        )

        ensure_preferences(
            db,
            user=tutor_piotr,
            online=True,
            offline=False,
            city=None,
            hourly_rate=70.0,
            types=["egzamin ósmoklasisty", "szkoła podstawowa"],
            subjects=[subj_math, subj_physics],
        )

        print(">>> Seeding tutor listings...")
        create_listing_if_missing(
            db,
            owner=tutor_anna,
            subject=subj_english,
            title="Korepetycje z angielskiego (online/offline)",
            description=(
                "Pomagam w przygotowaniu do matury i egzaminów językowych. "
                "Dużo konwersacji, materiały dopasowane do ucznia."
            ),
            city="Koszalin",
            is_online=True,
            is_offline=True,
            hourly_rate=80.0,
            level="matura",
        )

        create_listing_if_missing(
            db,
            owner=tutor_anna,
            subject=subj_it,
            title="Programowanie dla początkujących",
            description=(
                "Wprowadzenie do programowania (Python / web). "
                "Idealne dla licealistów i studentów pierwszych lat."
            ),
            city="Koszalin",
            is_online=True,
            is_offline=False,
            hourly_rate=90.0,
            level="liceum / studia I rok",
        )

        create_listing_if_missing(
            db,
            owner=tutor_piotr,
            subject=subj_math,
            title="Matematyka – szkoła podstawowa i średnia",
            description=(
                "Na spokojnie tłumaczę materiał krok po kroku. "
                "Przygotowanie do kartkówek, sprawdzianów i egzaminów."
            ),
            city=None,
            is_online=True,
            is_offline=False,
            hourly_rate=70.0,
            level="podstawówka / liceum",
        )

        print(">>> Seeding students...")
        student_kasia = get_or_create_user(
            db,
            email="kasia.student@example.com",
            first_name="Kasia",
            last_name="Wiśniewska",
            role=UserRole.student,
            password="student123",
        )
        student_michal = get_or_create_user(
            db,
            email="michal.student@example.com",
            first_name="Michał",
            last_name="Lewandowski",
            role=UserRole.student,
            password="student123",
        )

        ensure_preferences(
            db,
            user=student_kasia,
            online=True,
            offline=True,
            city="Koszalin",
            hourly_rate=85.0,
            types=["matura"],
            subjects=[subj_english, subj_math],
        )

        ensure_preferences(
            db,
            user=student_michal,
            online=True,
            offline=False,
            city=None,
            hourly_rate=75.0,
            types=["egzamin ósmoklasisty"],
            subjects=[subj_math],
        )

        db.commit()
        print(">>> Seed completed successfully.")
        print("Created/updated users:")
        for u in db.query(User).all():
            print(f" - {u.id}: {u.email} ({u.role.value})")

    except Exception as e:
        db.rollback()
        print("!!! Seed failed:", e)
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed()
