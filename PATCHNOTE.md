# TimeToLust Changelog

## [1.3.0] - 2025-08-31 - Advanced Volume Control & UI Enhancements

### 🎚️ **Separate Volume Controls**

#### 🎵 **Individual Sound Volume Management**
- **Tank Command Volume**: Independent volume control for tank require sounds (10%-100%)
- **Bloodlust Sound Volume**: Separate volume control for bloodlust detection sounds (10%-100%)
- **Smart Volume System**: Intelligent handling of multiple simultaneous sounds
  - When both sounds play simultaneously, the lower volume setting is used
  - Automatic volume restoration when sounds end
  - Precise duration-based volume management

#### 🔒 **Dynamic Slider Locking**
- **Active Sound Protection**: Sliders automatically lock when their respective sounds are playing
- **Visual Feedback**: Locked sliders become semi-transparent (50% opacity) and non-interactive
- **Automatic Unlocking**: Sliders unlock immediately when sounds end or are manually stopped
- **Comprehensive Coverage**: Works for all sound triggers (keybinds, detection, test buttons)

### 🛠️ **Robust Volume System**

#### 🔧 **Advanced Volume Management**
- **Session-Based Original Volume Storage**: Prevents volume corruption from rapid button clicks
- **Multi-Sound Support**: Handles overlapping sounds with different volume levels intelligently
- **Emergency Recovery**: Built-in cleanup system prevents stuck volume levels
- **Timer Conflict Resolution**: Prevents volume restoration conflicts from multiple simultaneous sounds

#### 🚨 **Volume Recovery Commands**
- **`/timetolust stop`**: Stops all sounds and performs complete volume system cleanup
- **`/timetolust fixvolume`**: Emergency volume system reset and restoration
- **Automatic Cleanup**: Stop buttons now perform comprehensive volume system cleanup

### 🎯 **Enhanced User Experience**

#### 📢 **Smart Chat Notifications**
- **Duplicate Message Prevention**: Volume change notifications only appear when values actually change
- **Clean Chat Experience**: No more spam messages when sliding between same percentage values
- **Precise Feedback**: Shows exact percentage changes (e.g., 90% → 80%)

#### 🎮 **Improved Sound Testing**
- **Separate Test Functions**: Independent test functions for tank and bloodlust sounds
- **Instance Validation Bypass**: Test sounds work everywhere, not just in dungeons/raids
- **Volume-Aware Testing**: Test sounds respect individual volume settings

### 🔄 **System Improvements**

#### 🏗️ **Architecture Enhancements**
- **Sound Type Identification**: Each sound type is properly categorized and tracked
- **Global Slider References**: Efficient slider state management across the addon
- **Improved Debug System**: Enhanced debug output for volume system troubleshooting
- **Configuration Migration**: Seamless upgrade from single volume to dual volume system

#### 🛡️ **Stability & Reliability**
- **Volume Corruption Prevention**: Robust protection against volume system corruption
- **Timer Management**: Improved timer lifecycle management prevents memory leaks
- **Error Recovery**: Comprehensive error handling and automatic recovery systems
- **Session Persistence**: Volume settings and system state properly maintained across sessions

### 🎨 **UI/UX Improvements**

#### 🎛️ **Enhanced Settings Interface**
- **Organized Volume Controls**: Clear separation of tank and bloodlust volume settings
- **Real-Time Visual Feedback**: Immediate visual response to volume changes
- **Intuitive Slider Behavior**: Smooth slider operation with proper value constraints
- **Streamlined Debug Control**: Debug mode now controlled via code only (removed from UI)

---

## [1.2.1] - 2025-08-30 - Improved Bloodlust Detection Organization

### 🔄 **Code Improvements**
- **Reorganized Bloodlust Detection**: Restructured the auraIds table for better readability and maintenance
  - Improved code organization for easier future updates

---

## [1.2.0] - 2025-08-30 - Sound Bug Fixes & Enhancements

### 🐛 **Critical Sound Bug Fixes**

#### 🔇 **Sound Conflict Resolution**
- **Tank Require Muting**: Tank command sounds are now automatically muted when Bloodlust sound is playing
  - Prevents audio overlap and confusion during Bloodlust activation
  - Tank command sounds will not play if Bloodlust is already active
- **Smart Sound Priority**: Bloodlust sounds take priority over tank command sounds
  - Automatically stops tank commands when Bloodlust is detected
  - Clean audio experience without competing sounds

#### 🎯 **Instance-Based Sound Management**
- **Instance Validation**: Sounds only play in valid instances (dungeons, raids, scenarios)
  - Prevents random sounds when outside instances
  - Automatic cleanup when leaving instance areas
- **Zone Change Detection**: Sounds are automatically stopped when changing zones
  - Prevents sounds from continuing after leaving instances
  - Smart detection of instance vs. non-instance areas

#### ⏹️ **Enhanced Sound Cleanup**
- **Complete Sound Cleanup**: New comprehensive cleanup system
  - Stops all sounds and cancels all timers
  - Prevents orphaned sounds and memory leaks
- **Event-Based Cleanup**: Automatic cleanup on various events
  - Player leaving world (logout, disconnect)
  - Group leaving (party/raid disbanding)
  - Zone changes (leaving instances)
- **Manual Stop Command**: New `/ttl stop` command to immediately stop all sounds
  - Emergency stop for any stuck or unwanted sounds
  - Complete cleanup of all sound resources

#### 🔄 **Improved Timer Management**
- **Hard Stop Timers**: Failsafe timers prevent sounds from running indefinitely
  - Maximum duration enforcement for all sounds
  - Automatic cleanup after sound completion
- **Timer Synchronization**: Better coordination between different sound timers
  - Prevents timer conflicts and resource leaks
  - Clean shutdown of all monitoring systems

#### 🎮 **Alt+Tab and Focus Improvements**
- **Focus-Independent Cleanup**: Sounds are properly managed regardless of game focus
  - No more random sounds when tabbing back into the game
  - Proper state management during focus changes
- **Background State Tracking**: Enhanced tracking of sound states
  - Prevents sounds from restarting inappropriately
  - Better handling of interrupted playback

### 🔧 **Technical Improvements**
- **Sound State Management**: New centralized sound state tracking
- **Instance Detection Caching**: Optimized instance checks with smart caching
- **Enhanced Debug Output**: Better logging for troubleshooting sound issues
- **Resource Management**: Improved cleanup of sound handles and timers
- **Fixed Keybinding System**: Corrected Bindings.xml format for proper keybind display
  - Fixed category attribute placement for WoW compatibility
  - Keybindings now appear correctly in game settings

### 🎯 **New Bloodlust Support**
- **Marksman Hunter Support**: Added Harrier's Cry for MM-Hunter
  - Full detection and sound triggering support
  - Completes Marksman Hunter Bloodlust-type ability coverage

### 📋 **New Commands**
- `/ttl stop` or `/ttl stopsounds` - Immediately stop all sounds and cleanup

---

## [1.1.0] - 2025-08-28

### 🚀 **Major Updates**

#### 🎵 **Enhanced Sound System**
- **Alt+Tab Sound Persistence**: Sounds now continue seamlessly after Alt+Tab or loading screens
  - Intelligent sound restart system maintains playback position
  - Works for all sound types: Tank Commands, Bloodlust Detection, and Test Sounds
- **Smart Sound Management**: Sound dropdowns automatically stop test sounds when opened
  - Prevents audio overlap during sound selection
  - Cleaner testing experience for custom sounds
- **Expanded Sound Channel Support**: Full support for Master and Music channels
  - Removed unused channels for simplified selection
  - Improved sound channel compatibility

#### ⏱️ **Timing & Duration System**
- **Fixed Duration Display**: Text now displays for exactly 6 seconds
  - Removed variable duration based on sound length
  - Consistent visual experience regardless of sound file
- **Anti-Spam Protection**: Prevents multiple simultaneous requires
  - 6-second cooldown between tank requests
  - Tank-only feedback for "already required" messages
- **Synchronized Timers**: Text and sound duration perfectly aligned

#### 🎯 **User Experience Improvements**
- **Role-Based Messaging**: Chat messages now only appear for relevant roles
  - Tanks see "Bloodlust already required!" messages
  - DPS/Healers receive clean experience without spam
- **Improved Configuration UI**: Better organized sound testing and selection
- **Universal Alt+Tab Support**: All sound functions now support background continuation

#### 🔧 **Technical Enhancements**
- **Advanced Sound Monitoring**: Real-time sound playback detection
- **Multi-Track Support**: Separate monitoring for Tank and Bloodlust sounds
- **Optimized Timer Management**: Efficient cleanup of sound monitoring timers
- **Enhanced Debug Output**: Detailed logging for troubleshooting

### 🐛 **Bug Fixes**
- Fixed sound channels not working correctly with non-Master selections
- Resolved text duration inconsistencies
- Improved sound file validation and fallback handling
- Enhanced error handling for sound playback failures

---

## [1.0.0] - 2025-08-27

### 🎉 Initial Release

#### ✨ **Core Features**
- **Tank Command System**: Keybind support for tanks to request Bloodlust from group members
- **Role-Based Restrictions**: Only tanks can trigger Bloodlust requests
- **Group Communication**: Addon messaging system for coordinated Bloodlust calls
- **Bloodlust Detection**: Automatic detection when Bloodlust/Heroism is cast in group

#### 🎵 **Audio System**
- **Custom Sound Support**: Add your own `.mp3` or `.ogg` files to `/sound/` folder
- **Sound Channel Selection**: Choose from Master, SFX, Music, Ambience, or Dialog channels
- **Dual Audio Tracks**:
  - Tank Command Sound (customizable via dropdown)
  - Bloodlust Detection Sound (customizable via dropdown)
- **Sound Testing**: Built-in test buttons for all audio features
- **Mute Controls**: Independent mute options for different sound types

#### 🎨 **Visual Features**
- **Screen Text Display**: Large, prominent text appears when tank requests Bloodlust
- **Custom Positioning**: Full-screen positioning with X/Y coordinates (-2000 to +2000)
- **Text Scaling**: Adjustable text scale from 0.5x to 3.0x
- **Visual Effects**: Glowing borders and smooth fade animations
- **Duration Sync**: Text display syncs with custom sound file duration

#### ⚙️ **Configuration System**
- **Organized Settings Panel**: Clean interface with subcategories (General, Sounds, Text)
- **Dropdown Integration**: Easy sound selection from available files
- **Custom Sound Management**:
  - Add custom sounds via input field
  - Reset to default sounds option
  - Clear all custom sounds option
- **Persistent Settings**: All configurations saved between game sessions

#### 🎯 **Targeting & Detection**
- **Multi-Role Support**: Works with Tanks, DPS, and Healers
- **Bloodlust Class Detection**: Supports all classes with Bloodlust-type abilities:
  - Shaman
  - Mage
  - Hunter
  - Evoker
- **Group Type Compatibility**: Works in dungeons, raids, PvP, and world content
- **Cross-Realm Support**: Functions across different servers

#### 🔧 **Technical Features**
- **Native Keybinding**: Full integration with WoW's keybinding system
- **Error Suppression**: Built-in error handling for smooth operation
- **Performance Optimized**: Minimal impact on game performance