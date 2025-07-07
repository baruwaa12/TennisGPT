import json
import os
from services.openai_service import TennisCoach

def handler(request, context):
    """Handle emotional reset requests"""
    if request.method != 'POST':
        return json.dumps({'error': 'Method not allowed'}), 405, {'Content-Type': 'application/json'}
    
    try:
        # Parse request body
        body = request.json()
        current_emotion = body.get('current_emotion', 'frustrated')
        situation = body.get('situation', '')
        
        # Initialize tennis coach
        coach = TennisCoach()
        
        # Get emotional reset guidance
        reset_guidance = coach.emotional_reset(current_emotion, situation)
        
        return json.dumps({
            'reset_guidance': reset_guidance,
            'current_emotion': current_emotion
        }), 200, {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        }
        
    except Exception as e:
        return json.dumps({'error': str(e)}), 500, {'Content-Type': 'application/json'} 