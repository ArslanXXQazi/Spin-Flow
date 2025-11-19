=====================================================
SOUND FILES - OPTIONAL (Currently Disabled)
=====================================================

App is working WITHOUT sounds right now!
When you want to add sounds, download these files:

📁 Location: assets/sounds/

📄 Required Files:
==================

1. tick.mp3
   ⏱️ Duration: 0.1 to 0.3 seconds
   🔊 Type: Short click/tick sound
   📝 Description: Plays every time wheel crosses a segment

2. spin.mp3
   ⏱️ Duration: 3 to 5 seconds
   🔊 Type: Wheel spinning/background sound
   📝 Description: Plays when wheel starts spinning

3. win.mp3
   ⏱️ Duration: 2 to 3 seconds
   🔊 Type: Celebration/success sound
   📝 Description: Plays when result is shown

=====================================================
WHERE TO DOWNLOAD FREE SOUNDS (No Copyright):
=====================================================

🌐 Recommended Websites:

1. PIXABAY (Best Option)
   Link: https://pixabay.com/sound-effects/
   
   Search Keywords:
   - "tick" or "click" (for tick.mp3)
   - "wheel spin" or "roulette" (for spin.mp3)
   - "win" or "success" or "celebration" (for win.mp3)

2. FREESOUND
   Link: https://freesound.org/
   
   Search Keywords:
   - "button click"
   - "spinning wheel"
   - "game win"

3. MIXKIT
   Link: https://mixkit.co/free-sound-effects/
   
   Browse: Game > UI Sounds

=====================================================
HOW TO DOWNLOAD:
=====================================================

1. Go to any website above
2. Search for the sound type
3. Preview the sound
4. Download (usually "Download" button)
5. Rename the file to exact name:
   - tick.mp3
   - spin.mp3
   - win.mp3
6. Copy all 3 files to this folder
7. Run: flutter pub get
8. Run your app!

=====================================================
TIPS:
=====================================================

✅ Make sure file names are EXACTLY: tick.mp3, spin.mp3, win.mp3
✅ Use MP3 format for best compatibility
✅ Keep tick sound very short (0.1-0.3 sec)
✅ If sounds don't work, app will still run (no error)

=====================================================
HOW TO ENABLE SOUNDS AFTER ADDING FILES:
=====================================================

1. Add the 3 sound files (tick.mp3, spin.mp3, win.mp3) to this folder
2. Open lib/main.dart
3. Search for "TODO: Uncomment when" (3 places)
4. Uncomment the code in those 3 methods:
   - _playTickSound()
   - _playSpinSound()
   - _playWinSound()
5. Save and run the app!

Currently sounds are DISABLED - App works perfectly without them!

=====================================================

