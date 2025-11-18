# seed_subjects.py
from app.db import SessionLocal
from app.models import Subject

SUBJECTS = [
    "Matematyka",
    "Fizyka",
    "Chemia",
    "Język angielski",
    "Język polski",
]

db = SessionLocal()
for name in SUBJECTS:
    if not db.query(Subject).filter_by(name=name).first():
        db.add(Subject(name=name))
db.commit()
db.close()
print("OK, subjects seeded")
