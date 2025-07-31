#!/bin/bash

# === Inputs ===
input="/Users/mahesh/Downloads/chatgpt.mp4"
output_dir="output"
extension="mp4"
delete_intermediate=true

# === Multiple Speed Intervals ===
# Define arrays for start times, end times, and speeds
# All intervals should be non-overlapping and in chronological order
starts=("00:00:04" "00:00:47")
ends=("00:00:32" "00:01:25")
speeds=(3.0 3.0)

# Validate that arrays have the same length
if [ ${#starts[@]} -ne ${#ends[@]} ] || [ ${#starts[@]} -ne ${#speeds[@]} ]; then
    echo "❌ Error: starts, ends, and speeds arrays must have the same length!"
    exit 1
fi

echo "🎬 Processing ${#starts[@]} speed interval(s):"
for i in "${!starts[@]}"; do
    echo "   ${starts[i]} - ${ends[i]} at ${speeds[i]}x speed"
done

# === Output Directory ===
if [ -d "$output_dir" ]; then
    rm -rf "$output_dir"/*
else
    mkdir -p "$output_dir"
fi
cd "$output_dir"

# === Get video duration ===
duration=$(ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input" 2>/dev/null)
if [ -z "$duration" ]; then
    echo "❌ Error: Could not get video duration!"
    exit 1
fi

# Convert duration to HH:MM:SS format
duration_formatted=$(date -u -d @"$duration" +%H:%M:%S 2>/dev/null || date -u -r "$duration" +%H:%M:%S 2>/dev/null)
echo "📹 Video duration: $duration_formatted"

# === Extract and process segments ===
segments=()
segment_count=0

# Function to apply speed change to a segment
apply_speed_change() {
    local input_file="$1"
    local output_file="$2"
    local speed="$3"
    
    if [ "$speed" == "1.0" ]; then
        # No speed change needed, just copy
        cp "$input_file" "$output_file"
        return $?
    fi
    
    # Calculate the video setpts value (inverse of speed)
    video_setpts=$(echo "scale=3; 1/$speed" | bc -l)
    
    # Check if the video has audio streams
    audio_streams=$(ffprobe -v quiet -select_streams a -show_entries stream=index -of csv=p=0 "$input_file" 2>/dev/null | wc -l)
    
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
        
        echo "🎵 Applying ${speed}x speed (video setpts=$video_setpts, audio filters=$atempo_filters)"
        
        # Apply speed change with audio
        ffmpeg -y -i "$input_file" \
            -filter_complex "[0:v]setpts=${video_setpts}*PTS[v];[0:a]${atempo_filters}[a]" \
            -map "[v]" -map "[a]" \
            -c:v libx264 -preset fast -crf 23 \
            -c:a aac -b:a 128k \
            "$output_file"
    else
        # Video-only (no audio) - apply speed change to video only
        echo "🎵 Applying ${speed}x speed (video-only, setpts=$video_setpts)"
        
        # Apply speed change without audio
        ffmpeg -y -i "$input_file" \
            -filter_complex "[0:v]setpts=${video_setpts}*PTS[v]" \
            -map "[v]" \
            -c:v libx264 -preset fast -crf 23 \
            "$output_file"
    fi
}

# Process segments in chronological order
current_time="00:00:00"

for i in "${!starts[@]}"; do
    start_time="${starts[i]}"
    end_time="${ends[i]}"
    speed="${speeds[i]}"
    
    # Extract segment before this interval (if any)
    if [ "$current_time" != "$start_time" ]; then
        segment_count=$((segment_count + 1))
        before_segment="segment${segment_count}.${extension}"
        echo "📹 Extracting segment ${segment_count}: $current_time - $start_time (1.0x speed)"
        ffmpeg -y -i "$input" -ss "$current_time" -to "$start_time" -c copy "$before_segment"
        
        if [ $? -eq 0 ]; then
            segments+=("$before_segment")
        else
            echo "❌ Failed to extract segment $segment_count"
            exit 1
        fi
    fi
    
    # Extract and process the speed interval
    segment_count=$((segment_count + 1))
    interval_segment="segment${segment_count}_raw.${extension}"
    processed_segment="segment${segment_count}.${extension}"
    
    echo "📹 Extracting speed interval ${i+1}: $start_time - $end_time (${speed}x speed)"
    ffmpeg -y -i "$input" -ss "$start_time" -to "$end_time" -c copy "$interval_segment"
    
    if [ $? -eq 0 ]; then
        # Apply speed change
        apply_speed_change "$interval_segment" "$processed_segment" "$speed"
        if [ $? -eq 0 ]; then
            segments+=("$processed_segment")
            rm -f "$interval_segment"  # Remove raw segment
        else
            echo "❌ Failed to apply speed change to segment $segment_count"
            exit 1
        fi
    else
        echo "❌ Failed to extract speed interval $((i+1))"
        exit 1
    fi
    
    current_time="$end_time"
done

# Extract final segment after last interval (if any)
if [ "$current_time" != "$duration_formatted" ]; then
    segment_count=$((segment_count + 1))
    final_segment="segment${segment_count}.${extension}"
    echo "📹 Extracting final segment: $current_time - end (1.0x speed)"
    ffmpeg -y -i "$input" -ss "$current_time" -c copy "$final_segment"
    
    if [ $? -eq 0 ]; then
        segments+=("$final_segment")
    else
        echo "❌ Failed to extract final segment"
        exit 1
    fi
fi

echo "✅ Successfully processed ${#segments[@]} segment(s)"

# === Concatenate all segments ===
if [ ${#segments[@]} -eq 0 ]; then
    echo "❌ No segments to concatenate!"
    exit 1
fi

echo "🔗 Combining all segments into final output..."

# Check if segments have audio streams
first_segment="${segments[0]}"
audio_streams=$(ffprobe -v quiet -select_streams a -show_entries stream=index -of csv=p=0 "$first_segment" 2>/dev/null | wc -l)

# Build concat filter command
if [ ${#segments[@]} -eq 1 ]; then
    # Only one segment, just copy it
    cp "${segments[0]}" "output.$extension"
    concat_result=$?
else
    # Multiple segments, concatenate them
    inputs=""
    filter_complex=""
    
    for segment in "${segments[@]}"; do
        inputs="$inputs -i \"$segment\""
    done
    
    if [ "$audio_streams" -gt 0 ]; then
        echo "🎵 Concatenating with audio streams..."
        # Build filter for video and audio
        for i in $(seq 0 $((${#segments[@]} - 1))); do
            filter_complex="${filter_complex}[$i:v][$i:a]"
        done
        filter_complex="${filter_complex}concat=n=${#segments[@]}:v=1:a=1[outv][outa]"
        
        eval "ffmpeg -y $inputs -filter_complex \"$filter_complex\" -map \"[outv]\" -map \"[outa]\" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k \"output.$extension\""
    else
        echo "🎬 Concatenating video-only (no audio streams)..."
        # Build filter for video only
        for i in $(seq 0 $((${#segments[@]} - 1))); do
            filter_complex="${filter_complex}[$i:v]"
        done
        filter_complex="${filter_complex}concat=n=${#segments[@]}:v=1[outv]"
        
        eval "ffmpeg -y $inputs -filter_complex \"$filter_complex\" -map \"[outv]\" -c:v libx264 -preset fast -crf 23 \"output.$extension\""
    fi
    concat_result=$?
fi

# Check if concatenation was successful
if [ $concat_result -eq 0 ] && [ -f "output.$extension" ] && [ -s "output.$extension" ]; then
    echo "✅ Successfully created final output: output.$extension"
    echo "📁 Final output size: $(du -h "output.$extension" | cut -f1)"
    
    # Clean up intermediate files (optional)
    if [ "$delete_intermediate" = true ]; then
        echo "🧹 Cleaning up intermediate files..."
        for segment in "${segments[@]}"; do
            rm -f "$segment"
        done
    fi
    echo "✨ All done! Your final video is: output.$extension"
else
    echo "❌ Failed to concatenate videos!"
    exit 1
fi
