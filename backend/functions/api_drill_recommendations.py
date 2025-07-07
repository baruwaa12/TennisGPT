import json
import os
from services.openai_service import TennisCoach

def handler(request, context):
    """Handle drill recommendations requests"""
    if request.method != 'POST':
        return json.dumps({'error': 'Method not allowed'}), 405, {'Content-Type': 'application/json'}
    
    try:
        # Parse request body
        body = request.json()
        focus_area = body.get('focus_area', 'groundstrokes')
        player_level = body.get('player_level', 'intermediate')
        available_time = body.get('available_time', 30)
        court_access = body.get('court_access', 'full_court')
        
        # Initialize tennis coach
        coach = TennisCoach()
        
        # Get drill recommendations
        drills = coach.drill_recommendations(focus_area, player_level, available_time, court_access)
        
        return json.dumps({
            'drills': drills,
            'focus_area': focus_area,
            'player_level': player_level,
            'available_time': available_time
        }), 200, {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        }
        
    except Exception as e:
        return json.dumps({'error': str(e)}), 500, {'Content-Type': 'application/json'} 