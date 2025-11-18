# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.db import Base, engine
from app.routers import (
    auth,
    onboarding,
    subjects,
    feed,
    swipes,
    matches,
    messages,
)

API_PREFIX = "/api/v1"

app = FastAPI(title="Korfinder API (MVP)")

# CORS — dev: всё открыто, потом можно будет зажать origin
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup() -> None:
    # создаём все таблицы по моделям
    Base.metadata.create_all(bind=engine)


@app.get(f"{API_PREFIX}/health")
def health() -> dict:
    return {"ok": True}


# --- Routers ---------------------------------------------------------------

# auth: /api/v1/auth/register, /api/v1/auth/login, /api/v1/auth/me
app.include_router(auth.router, prefix=f"{API_PREFIX}/auth", tags=["auth"])

# onboarding: /api/v1/onboarding/...
# (внутри роутера, скорее всего prefix="/onboarding")
app.include_router(onboarding.router, prefix=API_PREFIX, tags=["onboarding"])

# subjects: /api/v1/subjects/...
# (внутри subjects.router обычно prefix="/subjects")
app.include_router(subjects.router, prefix=API_PREFIX, tags=["subjects"])

# feed: /api/v1/feed/...
app.include_router(feed.router, prefix=API_PREFIX, tags=["feed"])

# swipes: /api/v1/swipes/...
app.include_router(swipes.router, prefix=API_PREFIX, tags=["swipes"])

# matches: /api/v1/matches/...
app.include_router(matches.router, prefix=API_PREFIX, tags=["matches"])

# messages (chat): /api/v1/messages/...
app.include_router(messages.router, prefix=API_PREFIX, tags=["messages"])
