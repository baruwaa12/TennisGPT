import json
import os
from services.openai_service import TennisCoach

def handler(request, context):
    """Handle tactical analysis requests"""
    if request.method != 'POST':
        return json.dumps({'error': 'Method not allowed'}), 405, {'Content-Type': 'application/json'}
    
    try:
        # Parse request body
        body = request.json()
        match_description = body.get('match_description', '')
        player_level = body.get('player_level', 'intermediate')
        opponent_style = body.get('opponent_style', '')
        
        # Initialize tennis coach
        coach = TennisCoach()
        
        # Get tactical analysis
        analysis = coach.tactical_analysis(match_description, player_level, opponent_style)
        
        return json.dumps({
            'analysis': analysis,
            'match_description': match_description,
            'player_level': player_level
        }), 200, {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        }
        
    except Exception as e:
        return json.dumps({'error': str(e)}), 500, {'Content-Type': 'application/json'} 