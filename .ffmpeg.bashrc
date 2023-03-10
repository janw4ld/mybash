#!/bin/bash

export ffLEC="-vf mpdecimate -vsync vfr       \
            -c:v libx264 -preset slow -crf 27 \
            -movflags faststart"

alias ffcodec='ffprobe -loglevel error -select_streams v:0 -show_entries stream=codec_name -of default=nk=1:nw=1'
alias ffacodec='ffprobe -loglevel error -select_streams a:0 -show_entries stream=codec_name -of default=nk=1:nw=1'

alias ffduration='ffprobe -loglevel error -select_streams v:0 -show_entries format=duration -of default=nk=1:nw=1'

alias fffps='ffprobe -v 0 -select_streams v -of default=nk=1:nw=1 -show_entries stream=avg_frame_rate'

function ffsize () {
  ffmpeg -nostdin -i "$1" -f null -c copy -map 0:v:0 - |& awk -F'[:|kB]' '/video:/ {print $2}'
}

function ffbitrate () {
  bc -l <<<"$(ffsize "$1")"/"$(ffduration "$1")"*8.192
}

function fffps () {
  ffprobe -v 0 -select_streams v -of default=nk=1:nw=1 -show_entries stream=avg_frame_rate "$1" | bc -l
}


function ffdecode () {
  video="$1"
  codec="$(ffcodec "$video")"
  ffmpeg -nostdin -i "$video" -c:v copy -bsf:v "$codec"_mp4toannexb -c:a copy "$video".ts
}

function ffrotate () {
  video=$1
  ffmpeg -nostdin -i "$video" -metadata:s:v:0 rotate=-90 -c copy "r$video"
}

function ffspeed () {
  video=$1
  factor=$2
  ffdecode "$video"
  ffmpeg -nostdin -fflags +genpts -r "$factor*$(fffps "$1")"  \
    -i "$video".ts -i "$video" -c:v copy           \
    -af atempo="$factor" "ffsped_$video"
  rm "$video".ts
}

function ffdecimate () {
  trap 'echo "Aborting ffdecimate..."; exit 1' SIGINT
  video=$1
  output=$2
  ffmpeg -nostdin -i "$video" $3 -vf mpdecimate=hi=64*40:lo=64*6:frac=0.15 -vsync vfr \
    -c:v libx264 -preset slow -tune zerolatency -crf 27          \
    -pix_fmt yuv444p -c:a libopus -b:a 16k -compression_level 10 \
    -vbr on  -movflags faststart "$output"
}

function decimate_recurse () {
  local pattern ext prefix clean_up dry
  [ "$#" -lt 1 ] \
  && echo -e "Error: pattern is required."             \
      "\nUsage: $0 pattern [-e extension] [-p prefix]" \
  && return 1
  pattern="$1"
  while [[ $# -gt 1 ]]; do
    case "$2" in
    -e|--ext)
      ext="$3" && shift 2 ;;
    -p|--prefix)
      prefix="$3" && shift 2 ;;
    -r|--clean-up)
      clean_up=y && shift 1 ;;
    -d|--dry-run)
      dry=y && shift 1 ;;
    -f|--fps)
      fps="$3" && shift 2 ;;
    *)
      echo "Unknown option $2" && return 1 ;;
    esac
  done
  pattern=${pattern:-"*.mp4"}
  ext=${ext:-"mp4"}
  prefix=${prefix:-"dc"}
  fps=${fps:-"7"}
  if [ "$dry" = y ]; then
    find . -type f -name "$pattern" -exec \
      bash -i -c 'dir=$(dirname "$1") ; base=$(basename "$1") ; (cd "$dir" && echo ffdecimate "$base" "$3${base/".$2"/.mp4}" "-r $4")'\
      shell {} "$ext" "$prefix" "$fps" \;
    return 0
  else
    find . -type f -name "$pattern" -exec \
      bash -i -c 'dir=$(dirname "$1") ; base=$(basename "$1") ; (cd "$dir" && ffdecimate "$base" "$3${base/".$2"/.mp4}" "-r $4")'\
      shell {} "$ext" "$prefix" "$fps" \;
    [ "$clean_up" = y ] \
    && bash -i -c 'dir=$(dirname "$1") ; base=$(basename "$1") ; (cd "$dir" && rm "$base")' shell {} "$ext" "$prefix"\;
  fi
}


function ffconcat () {
  trap 'echo "Aborting ffconcat..."; exit 1' SIGINT
  
  output_file="$1"
  shift 1

  if [ -f "$output_file" ]; then
    echo -n "Error: Output file already exists: $output_file"\
            "Do you want to overwrite it? [y/N] "
    read -r overwrite
    case "$overwrite" in
    y|Y) ;;
    *) return 1 ;;
    esac
  fi

  # Validate the input files
  for file in "$@"; do
    if [ ! -f "$file" ]; then
      echo "Error: File not found: $file"
      return 1
    fi
  done

  # Create a temporary file to store the list of input files
  > .ffmpeg_concat.temp && temp_file=".ffmpeg_concat.temp"
  trap 'rm -f $temp_file' EXIT

  # Add the input files to the temporary file
  for file in "$@"; do
    if [ "${file}" = "$temp_file" ]; then
      continue
    fi
    ffdecode "$file"
    echo "file '${file}.ts'" >>"$temp_file"
  done
  
  IFS=$SAVEIFS
  
  echo "Concatenating files:"
  cat "$temp_file"

  # No re-encode concatenation of the input files
  case "$overwrite" in
    y|Y) ffmpeg -nostdin -y -f concat -safe 0 -i "$temp_file" -c copy "$output_file" ;;
    *) ffmpeg -nostdin -f concat -safe 0 -i "$temp_file" -c copy "$output_file" ;;
  esac

  Remove the temporary file
  rm -f "$temp_file"

  Remove the .ts files generated by ffdecode
  for file in "$@"; do
      rm "$file.ts"
  done
}

function proccess_video () {
  [ -z "$1" ] \
  && echo "Usage: proccess_video <video> [factor]" \
  && return 1
  video=$1

  factor=$2
  [ -z "$factor" ] \
  && factor=0.85

  mkdir -p "$video.d" || return 1
  # this isn't real copy, it happens immediately
  cp --reflink=always "$video" "$video.d/" || return 1
  ( cd "$video.d" && ffspeed "$video" "$factor"             \
    && ffmpeg -nostdin -i "ffsped_$video"                   \
        -vf mpdecimate=frac=0.18:hi=64*40:lo=64*7           \
        -fps_mode vfr -c:v libx265 -crf 27 -preset slow     \
        -c:a libopus -b:a 16k -vbr on -compression_level 10 \
        -movflags faststart "hevc$video"                    \
    && ffrotate "hevc$video" && rm "$video" )
}

function ffrecord () {
  ffmpeg -nostdin -s 1920x1080 -f x11grab -i :1.0+0,0       \
    -an -pix_fmt yuv444p -vf mpdecimate -fps_mode vfr       \
    -c:v libx264 -tune stillimage -preset slow -crf 26 "$1"
}