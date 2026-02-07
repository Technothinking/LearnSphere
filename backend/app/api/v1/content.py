from fastapi import APIRouter, BackgroundTasks, HTTPException
from app.schemas.quiz_schema import ContentGenerateRequest
from app.services.content_service import ContentGenerationService

router = APIRouter()

@router.post("/generate")
async def generate_content(request: ContentGenerateRequest, background_tasks: BackgroundTasks):
    """
    Trigger AI content generation from a textbook PDF.
    Runs in background because LLM generation is slow.
    """
    # Verify file existence or just queue it 
    # For this implementation, we'll queue it immediately
    background_tasks.add_task(
        ContentGenerationService.process_textbook_pdf,
        bucket_name=request.bucket_name,
        filename=request.filename,
        subject=request.subject,
        chapter_name=request.chapter
    )
    
    return {
        "status": "queued",
        "message": f"Generation started for {request.filename}. New questions will appear in learning modules soon."
    }

@router.post("/generate-bulk")
async def generate_bulk_content(bucket_name: str = "Textbook", subject: str = "Physics", background_tasks: BackgroundTasks = None):
    """
    Trigger AI content generation for ALL PDFs in a bucket.
    """
    if background_tasks:
        background_tasks.add_task(
            ContentGenerationService.process_all_in_bucket,
            bucket_name=bucket_name,
            subject=subject
        )
            
    return {
        "status": "queued",
        "message": f"Bulk generation started for bucket '{bucket_name}'. This may take a while."
    }
