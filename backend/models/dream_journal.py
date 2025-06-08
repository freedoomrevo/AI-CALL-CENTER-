"""
Dream journal models
The Scribe's Autonomous Insights
"""

from sqlalchemy import Column, Integer, String, DateTime, Text, JSON
from sqlalchemy.sql import func
from database.connection import Base

class ScribeDreamJournal(Base):
    __tablename__ = "scribe_dream_journal"
    
    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, default=func.now())
    insight_category = Column(String(50), nullable=False)  # workflow_friction, potential_feature, etc.
    insight_summary = Column(Text, nullable=False)
    related_invocations = Column(JSON)  # Array of relevant Invocation types (stored as JSON for SQLite compatibility)
    anonymized_example_snippet = Column(Text)
    severity_level = Column(String(10), default="low")  # low, medium, high
    entry_metadata = Column(JSON)  # Additional structured insights