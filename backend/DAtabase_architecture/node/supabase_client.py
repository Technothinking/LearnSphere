"""
Supabase Client for fetching books from the 'textbook' bucket
"""
from supabase import create_client
import os

# Supabase credentials
SUPABASE_URL = "https://nhqmomcrcownexdpsizu.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ocW1vbWNyY293bmV4ZHBzaXp1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk2NDk3NDUsImV4cCI6MjA4NTIyNTc0NX0.Kzce-oOtc1FrgxRhoV5iZdAqTxU7y_2IaTqiT_1kxT0"

# Initialize Supabase client
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

BUCKET_NAME = "Textbook"


def list_books(path: str = ""):
    """List all books in the textbook bucket"""
    try:
        response = supabase.storage.from_(BUCKET_NAME).list(path)
        books = []
        for file in response:
            name = file.get('name', '')
            # Check if it's a folder
            if file.get('id') is None:
                # It's a folder, recursively list
                subfolder = f"{path}/{name}" if path else name
                books.extend(list_books(subfolder))
            elif name.lower().endswith('.pdf'):
                full_path = f"{path}/{name}" if path else name
                books.append(full_path)
        return books
    except Exception as e:
        print(f"Error listing books: {e}")
        return []


def download_book(filename: str) -> bytes:
    """Download a PDF book from the textbook bucket"""
    try:
        response = supabase.storage.from_(BUCKET_NAME).download(filename)
        return response
    except Exception as e:
        print(f"Error downloading book '{filename}': {e}")
        return None


def get_book_url(filename: str) -> str:
    """Get public URL for a book"""
    try:
        response = supabase.storage.from_(BUCKET_NAME).get_public_url(filename)
        return response
    except Exception as e:
        print(f"Error getting URL: {e}")
        return None


if __name__ == "__main__":
    # Test the connection
    print("Available books:", list_books())
