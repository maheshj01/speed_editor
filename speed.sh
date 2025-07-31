#!/bin/bash

# === Inputs ===
input="/Users/mahesh/Downloads/chatgpt.mp4"
output_dir="output"
start="00:00:04"
end="00:00:32"
extension="mp4"
speed=3.0  # Change this to 0.5, 1.5, 2.0, etc.

# === Output Directory ===
if [ -d "$output_dir" ]; then
    rm -rf "$output_dir"/*
else
    mkdir -p "$output_dir"
fi
cd "$output_dir"

# === 1. Extract part before `start` ===
ffmpeg -y -i "$input" -t "$start" -c copy part1.$extension

# === 2. Extract part between `start` and `end` ===
ffmpeg -y -i "$input" -ss "$start" -to "$end" -c copy part2.$extension

# Save path of the middle segment to a variable
middle_segment="$(pwd)/part2.$extension"

# === 3. Extract part after `end` ===
ffmpeg -y -i "$input" -ss "$end" -c copy part3.$extension

# === 4. Apply speed change to middle segment ===
sped_up_middle="part2_spedup.$extension"

# Calculate the video setpts value (inverse of speed)
video_setpts=$(echo "scale=3; 1/$speed" | bc -l)

# Check if the video has audio streams
audio_streams=$(ffprobe -v quiet -select_streams a -show_entries stream=index -of csv=p=0 "$middle_segment" 2>/dev/null | wc -l)

echo "🎬 Detected $audio_streams audio stream(s) in the video"

if [ "$audio_streams" -gt 0 ]; then
    # Video has audio - apply speed change to both video and audio

    # Handle atempo filter (max 2.0 per filter, chain if needed)
    atempo_filters=""
    remaining_speed=$speed

    # Build atempo filter chain for speeds > 2.0 or < 0.5
    while (( $(echo "$remaining_speed > 2.0" | bc -l) )); do
        atempo_filters="${atempo_filters}atempo=2.0,"
        remaining_speed=$(echo "scale=3; $remaining_speed/2.0" | bc -l)
    done

    while (( $(echo "$remaining_speed < 0.5" | bc -l) )); do
        atempo_filters="${atempo_filters}atempo=0.5,"
        remaining_speed=$(echo "scale=3; $remaining_speed*2.0" | bc -l)
    done

    # Add the final atempo value
    atempo_filters="${atempo_filters}atempo=$remaining_speed"

    echo "🎵 Applying speed change: ${speed}x (video setpts=$video_setpts, audio filters=$atempo_filters)"

    # Apply speed change with audio
    ffmpeg -y -i "$middle_segment" \
        -filter_complex "[0:v]setpts=${video_setpts}*PTS[v];[0:a]${atempo_filters}[a]" \
        -map "[v]" -map "[a]" \
        -c:v libx264 -preset fast -crf 23 \
        -c:a aac -b:a 128k \
        "$sped_up_middle"
else
    # Video-only (no audio) - apply speed change to video only
    echo "🎵 Applying speed change: ${speed}x (video-only, setpts=$video_setpts)"

    # Apply speed change without audio
    ffmpeg -y -i "$middle_segment" \
        -filter_complex "[0:v]setpts=${video_setpts}*PTS[v]" \
        -map "[v]" \
        -c:v libx264 -preset fast -crf 23 \
        "$sped_up_middle"
fi

# Check if the command was successful
if [ $? -eq 0 ]; then
    echo "✅ Successfully applied ${speed}x speed on middle segment: $sped_up_middle"

    # Verify the output file exists and has content
    if [ -f "$sped_up_middle" ] && [ -s "$sped_up_middle" ]; then
        echo "📁 Output file size: $(du -h "$sped_up_middle" | cut -f1)"
    else
        echo "❌ Output file is empty or missing!"
        exit 1
    fi
else
    echo "❌ Failed to apply speed change!"
    exit 1
fi
