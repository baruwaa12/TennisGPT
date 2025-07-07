from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import sys
import os
import json

# Add the services directory to the path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'services'))

from openai_service import TennisCoach

app = FastAPI(title="TennisGPT API", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize the tennis coach
tennis_coach = TennisCoach()

# Pydantic models for request/response
class MentalCheckInRequest(BaseModel):
    journal_entry: str
    mood_rating: int

class TacticalCoachRequest(BaseModel):
    match_description: str
    recent_matches: Optional[List[Dict[str, Any]]] = None

class EmotionalResetRequest(BaseModel):
    situation: str

class QuickTipRequest(BaseModel):
    situation: str

class DrillRecommendationRequest(BaseModel):
    matches: List[Dict[str, Any]]

# Health check endpoint
@app.get("/")
async def root():
    return {"message": "TennisGPT API is running!", "status": "healthy"}

# Example API endpoint
@app.get("/api/health")
async def health_check():
    return {"status": "healthy", "service": "TennisGPT Backend"}

# Example POST endpoint
@app.post("/api/chat")
async def chat_endpoint(request: Request):
    try:
        body = await request.json()
        message = body.get("message", "")
        
        # Add your TennisGPT logic here
        response = {
            "message": f"Received: {message}",
            "response": "This is a placeholder response from TennisGPT"
        }
        
        return JSONResponse(content=response)
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={"error": str(e)}
        )

@app.post("/mental-check-in")
async def mental_check_in(request: MentalCheckInRequest):
    """Process mental check-in and provide tough but fair coaching."""
    try:
        response = tennis_coach.mental_check_in(request.journal_entry, request.mood_rating)
        return {"response": response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/tactical-analysis")
async def tactical_analysis(request: TacticalCoachRequest):
    """Analyze match performance and provide tactical advice with drill recommendations."""
    try:
        # Build context from recent matches if available
        context = ""
        if request.recent_matches:
            context = "\n\nRecent Match History:\n"
            for match in request.recent_matches[:3]:  # Limit to last 3 matches
                context += f"- {match.get('date', 'Unknown')}: {match.get('result', 'Unknown')} vs {match.get('opponent', 'Unknown')} on {match.get('surface', 'Unknown')}\n"
                if 'strengths' in match:
                    strengths_str = ", ".join([f"{k}({v}/10)" for k, v in match['strengths'].items()])
                    context += f"  Strengths: {strengths_str}\n"
                if 'weaknesses' in match:
                    weaknesses_str = ", ".join([f"{k}({v}/10)" for k, v in match['weaknesses'].items()])
                    context += f"  Weaknesses: {weaknesses_str}\n"
        
        # Create enhanced prompt with match history context
        enhanced_description = request.match_description + context
        
        response = tennis_coach.tactical_coach(enhanced_description)
        return {"response": response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/emotional-reset")
async def emotional_reset(request: EmotionalResetRequest):
    """Provide emotional support and immediate action steps."""
    try:
        response = tennis_coach.emotional_reset(request.situation)
        return {"response": response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/quick-tactical-tip")
async def quick_tactical_tip(request: QuickTipRequest):
    """Provide a quick tactical tip for a specific situation."""
    try:
        prompt = f"""You are a tennis coach giving a quick tactical tip. 
        Situation: {request.situation}
        
        Provide:
        1. One specific tactical adjustment
        2. Why it works
        3. How to implement it immediately
        
        Keep it short and actionable."""
        
        response = tennis_coach.client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
            max_tokens=200
        )
        
        return {"response": response.choices[0].message.content}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/drill-recommendations")
async def drill_recommendations(request: DrillRecommendationRequest):
    """Generate drill recommendations based on match history."""
    try:
        if not request.matches:
            # No match history - provide foundational drills
            prompt = """You are a tennis coach. Since there's no match history yet, 
            provide 5 foundational drills that will help build a strong tennis foundation. 
            Include serve, groundstrokes, volleys, and footwork drills."""
        else:
            # Analyze common weaknesses from match history
            weakness_counts = {}
            for match in request.matches:
                if 'weaknesses' in match:
                    for skill, rating in match['weaknesses'].items():
                        if rating <= 5:  # Consider ratings 5 and below as weaknesses
                            weakness_counts[skill] = weakness_counts.get(skill, 0) + 1
            
            common_weaknesses = ", ".join([
                f"{skill} (appeared in {count} matches)" 
                for skill, count in sorted(weakness_counts.items(), key=lambda x: x[1], reverse=True)[:3]
            ])
            
            prompt = f"""You are a tennis coach analyzing match history to create targeted drills. 
            Based on these common weaknesses: {common_weaknesses}
            
            Provide:
            1. 5 specific drills targeting these weaknesses
            2. Progression from basic to advanced
            3. Expected improvement timeline
            4. How to measure progress
            
            Be specific and actionable."""
        
        response = tennis_coach.client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
            max_tokens=500
        )
        
        return {"response": response.choices[0].message.content}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Cloudflare Workers entry point
def handle_request(request: Request) -> Response:
    """Entry point for Cloudflare Workers"""
    # This function will be called by Cloudflare Workers
    # The FastAPI app will handle the routing
    return app(request)

# For local development
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 