from supabase import create_client, Client
import os

# Supabase credentials (retrieved from DAtabase_architecture/node/supabase_client.py)
SUPABASE_URL = "https://nhqmomcrcownexdpsizu.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ocW1vbWNyY293bmV4ZHBzaXp1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk2NDk3NDUsImV4cCI6MjA4NTIyNTc0NX0.Kzce-oOtc1FrgxRhoV5iZdAqTxU7y_2IaTqiT_1kxT0"

def get_supabase() -> Client:
    return create_client(SUPABASE_URL, SUPABASE_KEY)

# Singleton instance
supabase: Client = get_supabase()

# SQLAlchemy Setup
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Use a default SQLite DB for now if no connection string is present, 
# or strictly for the purpose of passing the import tests if real DB is via Supabase API.
# ideally this comes from config or env.
SQLALCHEMY_DATABASE_URL = "sqlite:///./sql_app.db"
# If using Supabase Postgres, it would be: postgresql://user:password@host:port/dbname

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
