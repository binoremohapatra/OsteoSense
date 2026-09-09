"""
database.py
------------
SQLite persistence layer. SQLite is enough for a hackathon demo (single
file, zero setup) — swap the DATABASE_URL for Postgres later without
touching the rest of the backend, since SQLAlchemy abstracts that away.
"""

from datetime import datetime
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, ForeignKey, JSON
from sqlalchemy.orm import declarative_base, relationship, sessionmaker

DATABASE_URL = "sqlite:///./oa_app.db"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


class Device(Base):
    """One wearable unit / user. device_id comes from the ESP32 (e.g. its MAC or a paired user id)."""
    __tablename__ = "devices"

    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String, unique=True, index=True, nullable=False)
    nickname = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    sessions = relationship("SensorSession", back_populates="device", cascade="all, delete-orphan")


class SensorSession(Base):
    """One recording window (e.g. 6s of gait + joint-sound capture) and its resulting risk score."""
    __tablename__ = "sensor_sessions"

    id = Column(Integer, primary_key=True, index=True)
    device_fk = Column(Integer, ForeignKey("devices.id"), nullable=False)
    recorded_at = Column(DateTime, default=datetime.utcnow)

    risk_score = Column(Float, nullable=False)
    risk_label = Column(String, nullable=False)
    model_used = Column(String, nullable=False)

    features = Column(JSON, nullable=True)          # full feature vector, for later analysis
    top_features = Column(JSON, nullable=True)       # top contributing features for this session

    device = relationship("Device", back_populates="sessions")


def init_db():
    Base.metadata.create_all(bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
