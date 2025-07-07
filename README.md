# TennisGPT 🎾

An AI-powered tennis coaching app built with Flutter and FastAPI, featuring mental check-ins, tactical analysis, and match history tracking.

## Features

### 🧠 Mental Check-In
- Journal your thoughts and feelings after matches
- Get tough but fair coaching feedback
- Receive accountability questions and actionable steps
- Track your mental progress over time

### 🎾 Tactical Coach
- Analyze match performance with AI insights
- Get personalized drill recommendations
- Receive tactical tips for specific situations
- Leverage match history for smarter recommendations

### 💥 Emotional Reset
- One-tap emotional support
- Quick reframing of challenging situations
- Immediate action steps for recovery
- Confidence boost when you need it most

### 📊 Match History
- Track all your matches with detailed performance data
- Rate your strengths and weaknesses (1-10 scale)
- Record key moments and tactical notes
- View performance trends and analytics
- Get AI-generated analysis and drill recommendations

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: FastAPI (Python)
- **AI**: OpenAI GPT-4
- **Storage**: Local storage with SharedPreferences
- **State Management**: Provider

## Setup Instructions

### Prerequisites

1. **Flutter SDK** (3.0.0 or higher)
2. **Python** (3.8 or higher)
3. **OpenAI API Key**

### Backend Setup

1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```

2. **Create a virtual environment:**
   ```bash
   python -m venv venv
   ```

3. **Activate the virtual environment:**
   - Windows: `venv\Scripts\activate`
   - macOS/Linux: `source venv/bin/activate`

4. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

5. **Set up environment variables:**
   Create a `.env` file in the backend directory:
   ```
   OPENAI_API_KEY=your_openai_api_key_here
   ```

6. **Run the backend server:**
   ```bash
   python main.py
   ```
   The server will start on `http://localhost:8000`

### Flutter App Setup

1. **Navigate to the Flutter app directory:**
   ```bash
   cd tennisgpt
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure the backend URL:**
   - For Android emulator: `http://10.0.2.2:8000` (already configured)
   - For iOS simulator: `http://localhost:8000`
   - For physical device: Use your computer's IP address

4. **Run the app:**
   ```bash
   flutter run
   ```

## Usage

### Getting Started

1. **Launch the app** and you'll see the main dashboard with four features
2. **Add your first match** using the Match History feature to start tracking your progress
3. **Use the Tactical Coach** to analyze matches and get personalized recommendations
4. **Try the Mental Check-In** after tough matches for accountability and motivation
5. **Use Emotional Reset** when you need immediate support and reframing

### Match History Workflow

1. **Add a Match:**
   - Tap "Match History" → "+" button
   - Fill in opponent, result, surface, weather
   - Rate your performance in different areas (1-10)
   - Add key moments and notes
   - Save to get AI analysis and drill recommendations

2. **View Progress:**
   - See your win rate, favorite surface, and total matches
   - Expand match cards to view detailed analysis
   - Track performance trends over time

### Tactical Coaching

1. **Match Analysis:**
   - Describe your match performance
   - Get tactical analysis based on your history
   - Receive specific drill recommendations

2. **Drill Recommendations:**
   - Get drills based on your match history
   - Target your recurring weaknesses
   - Follow progression from basic to advanced

3. **Quick Tips:**
   - Ask for specific tactical advice
   - Get immediate, actionable tips

## Project Structure

```
TennisGPT/
├── backend/
│   ├── main.py                 # FastAPI server
│   └── requirements.txt        # Python dependencies
├── services/
│   └── openai_service.py       # OpenAI integration
├── tennisgpt/
│   ├── lib/
│   │   ├── models/
│   │   │   ├── match_performance.dart
│   │   │   └── check_in_entry.dart
│   │   ├── services/
│   │   │   ├── openai_service.dart
│   │   │   └── match_history_service.dart
│   │   └── screens/
│   │       ├── home_screen.dart
│   │       ├── mental_check_in_screen.dart
│   │       ├── tactical_coach_screen.dart
│   │       ├── emotional_reset_screen.dart
│   │       ├── match_history_screen.dart
│   │       └── add_match_screen.dart
│   └── pubspec.yaml
└── README.md
```

## API Endpoints

- `POST /mental-check-in` - Process mental check-in journal entries
- `POST /tactical-analysis` - Analyze match performance with history context
- `POST /emotional-reset` - Provide emotional support and reframing
- `POST /quick-tactical-tip` - Get quick tactical advice
- `POST /drill-recommendations` - Generate drills based on match history

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues and questions, please open an issue on GitHub.

---

**TennisGPT** - Your AI Tennis Coach 🎾 