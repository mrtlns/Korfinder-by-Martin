from app.db import SessionLocal, engine, Base
from app.models import Subject

# гарантируем, что таблицы есть
Base.metadata.create_all(bind=engine)

names = ["Matematyka","Fizyka","Chemia","Język polski","Angielski","Informatyka","Biologia"]

with SessionLocal() as db:
    if db.query(Subject).count() == 0:
        db.add_all([Subject(name=n) for n in names])
        db.commit()
        print(f"Seeded {len(names)} subjects")
    else:
        print("Subjects already present — skip")
