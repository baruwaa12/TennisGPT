import os
from openai import OpenAI
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize OpenAI client
client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))

class TennisCoach:
    def __init__(self):
        self.client = client

    def mental_check_in(self, journal_entry, mood_rating=3):
        """Process mental check-in journal entry and provide empathetic response."""
        prompt = f"""You are a tough but fair tennis mental coach. Your goal is to build mental resilience, not to coddle. Write your response in a conversational, human-like tone, using paragraphs.

The user is checking in with a mood rating of {mood_rating} out of 5.
They wrote this in their journal: '{journal_entry}'.

First, acknowledge their state based on their rating and journal entry. Be direct and validate their feelings without being overly soft.

Next, transition into asking a sharp, insightful, and challenging question that forces them to confront the root cause of their feelings or the reality of their performance. Frame it as a genuine question from a coach who sees their potential.

Finally, provide a concrete, actionable tip they can apply in their next practice or match. Break this down into simple steps if it makes sense. Explain *why* this tip is important for them right now. End on a firm but encouraging note.
"""
        
        response = self.client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
            max_tokens=500
        )
        
        return response.choices[0].message.content

    def tactical_coach(self, issue):
        """Generate tactical advice and drilling plan for specific tennis issues."""
        prompt = f"""As a tennis coach, provide tactical advice and a drilling plan for this specific issue.
        Include both technical and strategic elements.
        
        Issue: {issue}
        
        Response should include:
        1. Technical analysis of the issue
        2. 3 specific drills to address it
        3. Strategic adjustments to consider
        4. Confidence-building reminder
        """
        
        response = self.client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
            max_tokens=500
        )
        
        return response.choices[0].message.content

    def emotional_reset(self, situation):
        """Provide emotional support and reframing for challenging situations."""
        prompt = f"""As a tennis coach, provide immediate emotional support and reframing for this situation.
        Focus on quick recovery and maintaining a positive mindset.
        
        Situation: {situation}
        
        Response should include:
        1. Quick validation of feelings
        2. Positive reframing
        3. Immediate next steps
        4. Encouraging reminder
        """
        
        response = self.client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
            max_tokens=300
        )
        
        return response.choices[0].message.content 