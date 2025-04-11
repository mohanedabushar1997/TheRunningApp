# Voice Coaching Audio Files

This directory contains pre-recorded audio files for the voice coaching feature when offline TTS is not available.

## Audio Categories

### Workout Start
- `starting_running_workout.mp3` - "Starting running workout. Let's go!"
- `starting_walking_workout.mp3` - "Starting walking workout. Let's go!"
- `starting_interval_workout.mp3` - "Starting interval workout. Let's go!"

### Workout Complete
- `workout_complete.mp3` - "Workout complete!"
- `great_job.mp3` - "Great job!"

### Interval Change
- `now_running.mp3` - "Now running."
- `now_walking.mp3` - "Now walking."
- `now_resting.mp3` - "Now resting."

### Progress
- `distance_covered.mp3` - "Distance covered:"
- `current_pace.mp3` - "Current pace:"

### Motivation
- `motivation_1.mp3` - "You're doing great! Keep pushing!"
- `motivation_2.mp3` - "Stay strong, you've got this!"
- `motivation_3.mp3` - "Excellent work! Keep up the pace!"
- `motivation_4.mp3` - "You're making great progress!"
- `motivation_5.mp3` - "Keep going! Every step counts!"

### Milestone
- `reached_1km.mp3` - "You've reached 1 kilometer. Keep it up!"
- `reached_2km.mp3` - "You've reached 2 kilometers. Keep it up!"
- `reached_3km.mp3` - "You've reached 3 kilometers. Keep it up!"
- `reached_4km.mp3` - "You've reached 4 kilometers. Keep it up!"
- `reached_5km.mp3` - "You've reached 5 kilometers. Keep it up!"

## Usage

These audio files are used by the `VoiceCoachingService` when the device is offline or TTS is not available. The service will automatically fall back to these pre-recorded files when needed.

## Source

These audio files should be recorded using a clear, neutral voice. For development purposes, you can generate these files using online TTS services and then include them in the app bundle.

## License

All audio files in this directory must be free for commercial use or created specifically for this application.
