#!/bin/bash

function loop() {
    while :; do "$1" || break; done
}

function wdb() {
	adb connect 192.168.1.193:$1
}

function fcd () {
  [ -f "$1" ] \
  && cd "$(dirname "$1")" \
  || cd "$1"
}

function wpy() {
  [ "$#" -eq 0 ] \
    && { pattern="*.py"; command="python main.py"
  } || { pattern="$1"  ; command="$2"; }
  
  # $command
  watchmedo shell-command --pattern "$pattern" \
      --command="$command"
}

function parc-init() {
  local def_name="parcel-project"
  local dir="${1:-"."}"
  local repo
  local fwrk

  [ ! -d "$dir" ] && {
    echo "$dir doesn't exist, creating it"
    mkdir "$dir"
  } || {
    [ "$(ls -A "$dir")" ] && {
      echo "Directory not empty, falling back to dir=$def_name"
      dir=$def_name; mkdir "$dir" || return 1
    }
  }

  case $2 in
  node|bun) fwrk=$2;;
  *) fwrk="node"   ;;
  esac

  [ "$3" = "-l" ] && {
    repo="file:////home/misc/work/ana/js-starters/$fwrk-starter/.git" 
  } || repo="git@github.com:janw4ld/$fwrk-starter.git"
  
  git clone --depth 1 -b main "$repo" "$dir"
  
  rm -rf "$dir/.git" 
  (cd "$dir" && git init)
}

function phsync() {
  [ "$#" -eq 0 ] \
  && exit 1

  [ "$#" -lt 3 ] \
  && x="."       \
  || x="$3"

  case $1 in
  -r | --reverse)
    adb shell ls "$2" >/dev/null 2>&1 \
    && adb-sync --reverse "$2" "$x"
    ;;
  -d | --duplex)
    adb shell ls "$2" >/dev/null 2>&1 && {
      adb-sync --reverse "$2" "$x"
      adb-sync "$x" "$2"
    };;
  *)
    adb shell ls "$1" >/dev/null 2>&1 \
    && adb-sync "$x" "$1"
    ;;
  esac
}

function aoc() {
  [ "$#" -lt 2 ] \
    && { l="py"; d="$1"
  } || { l="$1"; d="$2"; }

  target_dir=/home/misc/work/active-projects/advent-of-code/2022/"$l"/day-"$d"/
  [ -d "$target_dir" ] \
  || cp -r /home/misc/work/active-projects/advent-of-code/2022/"$l"/template/*  \
      "$target_dir"
  code /home/misc/work/active-projects/advent-of-code/2022/"$l"/
}

function matex() {
  [ -f "$1" ] \
  && matlab -nosplash -nodesktop -s d \
      "$(realpath "$(dirname ./"$1")")" -r "run('./$(basename "$1")');"
}

concat_subdirs() {
  for i in *; do
    (cd "$i" &&
      ffconcat "conc$i.mp4" ./*.mp4)
  done
  for i in *; do
    (cd "$i" && 
      mv "conc$i.mp4" ../) 
  done
}