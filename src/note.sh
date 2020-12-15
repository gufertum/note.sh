#!/usr/bin/env bash
set -euo pipefail

#your editor command (override the default)
CMD_EDITOR=$EDITOR
#your favorite file viewer (i prefer the terminal)
CMD_VIEWER=bat
#your favorite gui editor (or alternative to EDITOR)
CMD_OPENER=code
#your command to open a directory using file explorer, finder etc...
CMD_EXPLODER=open
#the privided clipboard copy command
CMD_COPY=pbcopy
#the default file extension for newly create files

#set command option defaults
ACTION=${1:-}
PARAM=${2:-}
#you can override the file extension on create
EXT="${3:-md}"

#some semi-constants
TODAY=$(date +'%Y-%m-%d')

if [ -z ${NOTE_DIR+x} ]; then
  echo "Error: Please configure and export NOTE_DIR environment variable."
  exit 1
fi

function usage() {
  echo "Usage: note.sh [action]"
  echo
  echo "  actions:"
  echo "    grep [pattern]      > greps a pattern"
  echo "    list                > list all files by last modified date"
  echo "    goto                > open the file in the finder/file exploder ($CMD_EXPLODER)"
  echo "    view [name]         > displays the file using your view tool ($CMD_VIEWER)"
  echo "    edit [name]         > opens the file in your editor ($CMD_EDITOR)"
  echo "    open [name]         > opens the file in your favorite GUI or alternative editor ($CMD_OPENER)"
  echo "    copy [name]         > copyies the file content in the clipboard"
  echo "    create [name] [ext] > creates an extra file with the given name"
  echo "    ... unknown action are treated as filename and opened if they exist"
  if [[ "$1" != "" ]]; then
    echo
    echo "ERROR: $1"
    exit 9
  fi
}

#returns a full path to a possibly not existing file (always having the timestamp from today)
function createFilePath(){
  local name=$1
  if [[ "$name" != "" ]]; then
    echo "$NOTE_DIR/$TODAY-$(echo ${name// /-}).$EXT"
  else
    echo "$NOTE_DIR/$TODAY.$EXT"
  fi
}

#returns a path of a possible existing file, using today if no date specified and a suffix-name
#aborts with error if the file does not exist!
function getFilePath(){
  local name=$1
  if [[ "$name" != "" ]]; then
    if [[ $name == *[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]* ]]; then
      if [ -f "$NOTE_DIR/$name" ]; then
        echo "$NOTE_DIR/$name"
      else
        if [ -f "$NOTE_DIR/$name.$EXT" ]; then
          echo "$NOTE_DIR/$name.$EXT"
        else
          exit 2
        fi
      fi
    else
      if [ -f "$NOTE_DIR/$TODAY-$name" ]; then
        echo "$NOTE_DIR/$TODAY-$name"
      else
        if [ -f "$NOTE_DIR/$TODAY-$name.$EXT" ]; then
          echo "$NOTE_DIR/$TODAY-$name.$EXT"
        else
          exit 3
        fi
      fi
    fi
  else
    if [ -f "$NOTE_DIR/$TODAY.$EXT" ]; then
      echo "$NOTE_DIR/$TODAY.$EXT"
    else
      exit 4
    fi
  fi
}

mkdir -p "$NOTE_DIR"

if [ $# -eq 0 ]; then
    $EDITOR "$NOTE_DIR/$TODAY.$EXT"
else
  case $ACTION in
    grep)
      grep -i -r --color "$PARAM" "$NOTE_DIR"
      ;;
    list)
      ls -ltrahp "$NOTE_DIR" | grep -v /
      ;;
    goto)
      $CMD_EXPLODER "$NOTE_DIR"
      ;;
    view|show)
      f=$(getFilePath "$PARAM") || usage "File not found in $NOTE_DIR"
      $CMD_VIEWER $f
      ;;
    edit)
      f=$(getFilePath "$PARAM") || usage "File not found in $NOTE_DIR"
      $CMD_EDITOR $f
      ;;
    open)
      f=$(getFilePath "$PARAM") || usage "File not found in $NOTE_DIR"
      $CMD_OPENER $f
      ;;
    copy)
      f=$(getFilePath "$PARAM") || usage "File not found in $NOTE_DIR"
      cat "$f" | $CMD_COPY
      echo "File-content from $f copied to clipboard!"
      ;;
    create)
      $CMD_EDITOR $(createFilePath "$PARAM")
      ;;
    *)
      f=$(getFilePath "$ACTION") || usage
      $CMD_EDITOR $f
      ;;
  esac
fi
