import json
import os
from services.openai_service import TennisCoach

def handler(request, context):
    """Handle mental check-in requests"""
    if request.method != 'POST':
        return json.dumps({'error': 'Method not allowed'}), 405, {'Content-Type': 'application/json'}
    
    try:
        # Parse request body
        body = request.json()
        mood_rating = body.get('mood_rating', 5)
        additional_context = body.get('additional_context', '')
        
        # Initialize tennis coach
        coach = TennisCoach()
        
        # Get mental check-in response
        response = coach.mental_check_in(mood_rating, additional_context)
        
        return json.dumps({
            'response': response,
            'mood_rating': mood_rating
        }), 200, {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        }
        
    except Exception as e:
        return json.dumps({'error': str(e)}), 500, {'Content-Type': 'application/json'} 