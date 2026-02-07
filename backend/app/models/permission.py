from sqlalchemy import Column, Integer, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class StudentPermission(Base):
    __tablename__ = "student_permissions"

    student_id = Column(String, ForeignKey("students.id"), primary_key=True, index=True)
    
    # Flags
    has_taken_diagnostic = Column(Boolean, default=False)
    
    # Store JSON list of chapters where "Common Test" is completed
    # e.g. ["Force", "Motion"]
    completed_chapters = Column(String, default="[]")
    
    # Future extensibility:
    # can_access_advanced = Column(Boolean, default=False)
    # is_banned = Column(Boolean, default=False)

    # Relationships
    student = relationship("Student", back_populates="permissions")
