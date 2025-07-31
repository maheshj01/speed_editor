# 🎬 Speed Editor

A powerful bash script for applying variable speed changes to specific time intervals in video files. Perfect for creating highlight reels, educational content, or any video where you need different parts to play at different speeds.

## ✨ Features

- **Multiple Speed Intervals**: Apply different speeds to multiple time segments
- **Smart Concatenation**: Automatically combines all segments into a single output video
- **Audio Support**: Handles both audio and video-only files intelligently
- **Flexible Configuration**: Easy-to-modify arrays for time intervals and speeds
- **Robust Error Handling**: Comprehensive validation and error checking
- **Clean Output**: Optional intermediate file cleanup

## 🎯 Use Cases

- **Sports Highlights**: Speed up boring parts, keep exciting moments normal
- **Educational Videos**: Fast-forward through setup, normal speed for key concepts
- **Screen Recordings**: Accelerate navigation, normal speed for demonstrations
- **Social Media Content**: Create engaging videos with dynamic pacing

## 📋 Prerequisites

### Required Software

1. **FFmpeg** - For video processing
2. **FFprobe** - For video analysis (usually comes with FFmpeg)
3. **bc** - For mathematical calculations (usually pre-installed on macOS/Linux)

### Installation

#### macOS (using Homebrew)
```bash
# Install Homebrew if you haven't already
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install FFmpeg
brew install ffmpeg

# bc is usually pre-installed, but if needed:
brew install bc
```

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install ffmpeg bc
```

#### Windows (using Chocolatey)
```bash
# Install Chocolatey first, then:
choco install ffmpeg

# bc equivalent for Windows
choco install gnuwin32-coreutils.install
```

#### Windows (Manual)
1. Download FFmpeg from [https://ffmpeg.org/download.html](https://ffmpeg.org/download.html)
2. Extract and add to PATH
3. Install Windows Subsystem for Linux (WSL) for bash support

## 🚀 Quick Start

### 1. Clone/Download the Project
```bash
git clone <your-repo-url>
cd speed_editor
```

### 2. Make the Script Executable
```bash
chmod +x speed.sh
```

### 3. Configure Your Video
Edit the `speed.sh` file and modify these variables:

```bash
# === Inputs ===
input="/path/to/your/video.mp4"
output_dir="output"
extension="mp4"
delete_intermediate=true

# === Multiple Speed Intervals ===
starts=("00:00:04" "00:00:47")  # Start times
ends=("00:00:32" "00:01:25")    # End times  
speeds=(3.0 3.0)                # Speed multipliers
```

### 4. Run the Script
```bash
./speed.sh
```

## ⚙️ Configuration

### Time Format
Use `HH:MM:SS` format for all timestamps:
- `00:00:30` = 30 seconds
- `00:02:15` = 2 minutes 15 seconds
- `01:30:45` = 1 hour 30 minutes 45 seconds

### Speed Values
- `0.5` = Half speed (slow motion)
- `1.0` = Normal speed
- `2.0` = Double speed
- `3.0` = Triple speed
- Any positive decimal value is supported

### Important Rules
1. **Non-overlapping**: Intervals must not overlap
2. **Chronological order**: Arrange intervals from earliest to latest
3. **Within duration**: All timestamps must be within video length
4. **Array matching**: `starts`, `ends`, and `speeds` arrays must have same length

## 📝 Examples

### Example 1: Simple Speed-up
```bash
# Speed up middle section of a 2-minute video
starts=("00:00:15")
ends=("00:01:30") 
speeds=(2.5)
```

**Result Timeline:**
- `00:00:00 - 00:00:15`: Normal speed
- `00:00:15 - 00:01:30`: 2.5x speed
- `00:01:30 - 00:02:00`: Normal speed

### Example 2: Multiple Intervals
```bash
# Complex editing with multiple speed changes
starts=("00:00:10" "00:01:00" "00:02:30")
ends=("00:00:30" "00:01:45" "00:03:00")
speeds=(3.0 0.5 2.0)
```

**Result Timeline:**
- `00:00:00 - 00:00:10`: Normal speed
- `00:00:10 - 00:00:30`: 3x speed (fast)
- `00:00:30 - 00:01:00`: Normal speed
- `00:01:00 - 00:01:45`: 0.5x speed (slow motion)
- `00:01:45 - 00:02:30`: Normal speed
- `00:02:30 - 00:03:00`: 2x speed (medium-fast)
- `00:03:00 - end`: Normal speed

## 🔧 Advanced Configuration

### File Cleanup
```bash
delete_intermediate=true   # Remove temporary files after processing
delete_intermediate=false  # Keep temporary files for debugging
```

### Output Quality Settings
The script uses these FFmpeg settings for optimal quality:
- **Video codec**: libx264
- **Preset**: fast (good balance of speed/quality)
- **CRF**: 23 (high quality)
- **Audio codec**: aac (when present)
- **Audio bitrate**: 128k

## 🐛 Troubleshooting

### Common Issues

#### 1. "Command not found: ffmpeg"
**Solution**: Install FFmpeg following the prerequisites section

#### 2. "Error: Could not get video duration"
**Solution**: 
- Check if the input video file exists
- Verify the file isn't corrupted
- Ensure FFprobe is installed

#### 3. "Failed to extract speed interval"
**Solution**:
- Check that timestamps are within video duration
- Use `ffprobe -i your_video.mp4` to check actual duration
- Ensure time format is correct (HH:MM:SS)

#### 4. "Arrays must have the same length"
**Solution**: Ensure `starts`, `ends`, and `speeds` arrays have equal number of elements

#### 5. "Permission denied"
**Solution**: Make script executable with `chmod +x speed.sh`

### Debug Mode
To see detailed FFmpeg output, you can modify the script to remove `-y` flag and add `-v verbose` to FFmpeg commands.

## 📊 Performance Tips

1. **Use SSD storage** for faster file operations
2. **Close other applications** during processing
3. **Use appropriate presets**:
   - `ultrafast`: Fastest encoding, larger files
   - `fast`: Good balance (default)
   - `slow`: Better compression, slower processing

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [FFmpeg](https://ffmpeg.org/) - The backbone of video processing
- [bc](https://www.gnu.org/software/bc/) - Mathematical calculations

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section
2. Verify your FFmpeg installation
3. Test with a simple, short video first
4. Create an issue with detailed error messages

---

**Happy video editing! 🎬✨** 