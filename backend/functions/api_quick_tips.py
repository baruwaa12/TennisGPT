import json
import os
from services.openai_service import TennisCoach

def handler(request, context):
    """Handle quick tactical tips requests"""
    if request.method != 'POST':
        return json.dumps({'error': 'Method not allowed'}), 405, {'Content-Type': 'application/json'}
    
    try:
        # Parse request body
        body = request.json()
        current_situation = body.get('current_situation', '')
        player_level = body.get('player_level', 'intermediate')
        
        # Initialize tennis coach
        coach = TennisCoach()
        
        # Get quick tactical tips
        tips = coach.quick_tactical_tips(current_situation, player_level)
        
        return json.dumps({
            'tips': tips,
            'current_situation': current_situation,
            'player_level': player_level
        }), 200, {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        }
        
    except Exception as e:
        return json.dumps({'error': str(e)}), 500, {'Content-Type': 'application/json'} 