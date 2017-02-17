#!/usr/bin/env bash

function changes {
  local passphrase=""
  local sha1=""
  local sha2=""

  OPTIND=1

  while getopts 'hd:p:a:b:' opt; do
    case "$opt" in
      h) _show_manual_for 'changes';;

      p) passphrase=$OPTARG;;

      d) homedir=$OPTARG;;

      a) sha1=$OPTARG;;

      b) sha2=$OPTARG;;
    esac
  done

  shift $((OPTIND-1))
  [ "$1" = '--' ] && shift

  local filenames="$1"
  if [[ -z "$filenames" ]]; then
    # Checking if no filenames are passed, show diff for all files.
    filenames=$(git secret list)
  fi

  IFS='
  '

  if [[ -z "$sha1" ]]; then
    compare "$filenames" "$passphrase"
  else
    actual_sha=$(git rev-parse HEAD)
    git checkout "$sha1"

    if [[ -z "$sha2" ]]; then
      compare "$filenames" "$passphrase"

    else
      reveal -d "$homedir" -p "$passphrase"
      git checkout "$sha2"
      compare "$filenames" "$passphrase"
    fi
    #restore
    git checkout "$actual_sha"
    reveal -d "$homedir" -p "$passphrase"
  fi
}

function compare {

  local filenames=$1
  local passphrase=$2

  for filename in $filenames; do
    local decrypted
    local content
    local diff_result

    # Now we have all the data required:
    decrypted=$(_decrypt "$filename" "0" "0" "$homedir" "$passphrase")
    content=$(cat "$filename")

    # Let's diff the result:
    diff_result=$(diff <(echo "$decrypted") <(echo "$content")) || true
    # There was a bug in the previous version, since `diff` returns
    # exit code `1` when the files are different.
    echo "changes in ${filename}: ${diff_result}"
  done
}
