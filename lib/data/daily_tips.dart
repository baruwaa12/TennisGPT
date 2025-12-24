/// Daily tennis tips - rotates based on day of year
class DailyTips {
  static const List<Map<String, String>> tips = [
    // Serve Tips
    {
      'emoji': '🎾',
      'tip': 'Federer takes 3 deep breaths before every serve. Try it today.',
      'category': 'Mental',
    },
    {
      'emoji': '🎯',
      'tip': 'Your toss controls your serve. Practice toss consistency - it should land in the same spot every time.',
      'category': 'Serve',
    },
    {
      'emoji': '💪',
      'tip': 'A relaxed grip on serve generates more racket head speed than a tight one.',
      'category': 'Serve',
    },
    {
      'emoji': '📐',
      'tip': 'Aim for the T on big points. A body serve is your reliable backup.',
      'category': 'Serve',
    },
    
    // Footwork Tips
    {
      'emoji': '🏃',
      'tip': 'Split step on every shot today. It\'s the foundation of good movement.',
      'category': 'Footwork',
    },
    {
      'emoji': '👟',
      'tip': 'Recovery is as important as getting to the ball. Always return to ready position.',
      'category': 'Footwork',
    },
    {
      'emoji': '⚡',
      'tip': 'Small adjustment steps are better than one big step. Stay balanced.',
      'category': 'Footwork',
    },
    
    // Mental Tips
    {
      'emoji': '🧠',
      'tip': 'Visualize winning the next point before you serve. Champions do this.',
      'category': 'Mental',
    },
    {
      'emoji': '💭',
      'tip': 'Focus on the process, not the score. Play one point at a time.',
      'category': 'Mental',
    },
    {
      'emoji': '😤',
      'tip': 'Take a breath between points. Rushed play leads to errors.',
      'category': 'Mental',
    },
    {
      'emoji': '🎯',
      'tip': 'Have a game plan before you step on court. Know your patterns.',
      'category': 'Mental',
    },
    {
      'emoji': '🔄',
      'tip': 'Lost the first set? Reset mentally. Many matches are won in the second set.',
      'category': 'Mental',
    },
    
    // Groundstroke Tips
    {
      'emoji': '💥',
      'tip': 'Hit through the ball, not at it. Follow through toward your target.',
      'category': 'Groundstrokes',
    },
    {
      'emoji': '👀',
      'tip': 'Watch the ball hit your strings. Most errors come from taking your eye off early.',
      'category': 'Groundstrokes',
    },
    {
      'emoji': '🎾',
      'tip': 'Crosscourt is safer than down the line. Use it to build points.',
      'category': 'Groundstrokes',
    },
    {
      'emoji': '📏',
      'tip': 'Depth wins matches. Aim 3 feet inside the baseline, not at it.',
      'category': 'Groundstrokes',
    },
    {
      'emoji': '🔁',
      'tip': 'Consistency beats power. Make one more ball than your opponent.',
      'category': 'Groundstrokes',
    },
    
    // Tactical Tips
    {
      'emoji': '🎯',
      'tip': 'Attack the weaker wing. Most players have a reliable forehand but vulnerable backhand.',
      'category': 'Tactics',
    },
    {
      'emoji': '📊',
      'tip': 'Play to your strengths first. Don\'t try new things in matches.',
      'category': 'Tactics',
    },
    {
      'emoji': '🧩',
      'tip': 'Build points with patterns: serve wide, hit to open court.',
      'category': 'Tactics',
    },
    {
      'emoji': '🎭',
      'tip': 'Against a pusher: take pace off and hit angles. Don\'t try to overpower them.',
      'category': 'Tactics',
    },
    {
      'emoji': '⚔️',
      'tip': 'When ahead, play solid. When behind, take calculated risks.',
      'category': 'Tactics',
    },
    {
      'emoji': '🎪',
      'tip': 'Change it up. Slice, topspin, pace changes - variety keeps opponents guessing.',
      'category': 'Tactics',
    },
    
    // Return Tips
    {
      'emoji': '🛡️',
      'tip': 'On return, prioritize getting the ball back deep. Winners come later in the rally.',
      'category': 'Return',
    },
    {
      'emoji': '📍',
      'tip': 'Stand closer on second serve returns. Put pressure on your opponent.',
      'category': 'Return',
    },
    
    // Net Play Tips
    {
      'emoji': '🏐',
      'tip': 'At the net, punch volleys - don\'t swing. Compact motion wins.',
      'category': 'Net Play',
    },
    {
      'emoji': '🎯',
      'tip': 'Approach shots go down the line. It gives you the best court coverage.',
      'category': 'Net Play',
    },
    
    // Physical Tips
    {
      'emoji': '💧',
      'tip': 'Hydrate before you\'re thirsty. Performance drops 10% when dehydrated.',
      'category': 'Physical',
    },
    {
      'emoji': '🍌',
      'tip': 'Eat a banana before your match. Potassium prevents cramps.',
      'category': 'Physical',
    },
    {
      'emoji': '🧘',
      'tip': 'Stretch after matches, not just before. Recovery is key.',
      'category': 'Physical',
    },
    
    // Match Play Tips
    {
      'emoji': '📈',
      'tip': 'Start matches with higher margin shots. Feel out your opponent first.',
      'category': 'Match Play',
    },
    {
      'emoji': '🔥',
      'tip': 'When you\'re hot, go for more. Momentum is real in tennis.',
      'category': 'Match Play',
    },
    {
      'emoji': '❄️',
      'tip': 'When you\'re cold, simplify. Go back to basics and rebuild.',
      'category': 'Match Play',
    },
  ];

  /// Get today's tip based on day of year
  static Map<String, String> getTodaysTip() {
    final dayOfYear = _getDayOfYear(DateTime.now());
    final index = dayOfYear % tips.length;
    return tips[index];
  }

  /// Get tip for a specific index
  static Map<String, String> getTip(int index) {
    return tips[index % tips.length];
  }

  /// Calculate day of year (1-366)
  static int _getDayOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    return date.difference(firstDayOfYear).inDays + 1;
  }
}
