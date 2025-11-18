# app/routers/subjects.py
from typing import List, Dict, Any

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import Subject

router = APIRouter()


@router.get("/subjects")
def list_subjects(db: Session = Depends(get_db)) -> List[Dict[str, Any]]:
    """
    Простой список предметов для онбординга.
    Возвращаем голые dict'ы {id, name}, чтобы точно совпало с iOS-моделью.
    """
    subjects = db.query(Subject).order_by(Subject.name).all()
    return [{"id": s.id, "name": s.name} for s in subjects]
