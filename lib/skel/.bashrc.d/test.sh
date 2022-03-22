#!/bin/bash
scriptname=${0##*/}
rundir=${0%/*}
runuser=$(whoami)

source ${rundir}/functions

# Example for above select_option
echo "Select one option using up/down keys and enter to confirm:"
echo

options=("one" "two" "three")

select_option "${options[@]}"
choice=$?

echo "Choosen index = $choice"
echo "        value = ${options[$choice]}"

# Examples for above select_opt
case `select_opt "Yes" "No" "Cancel"` in
  0) echo "selected Yes";;
  1) echo "selected No";;
  2) echo "selected Cancel";;
esac

#options=("Yes" "No" "${array[@]}") # join arrays to add some variable array
case `select_opt "${options[@]}"` in
  0) echo "selected Yes";;
  1) echo "selected No";;
  *) echo "selected ${options[$?]}";;
esac