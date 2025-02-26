# ~/.bashrc.d/12-pidqueue.bashrc
# # Function to get the PID of a specific binary by name
targetPid() {
    TARGET_PID="$(pgrep -f "$1")"
    if [ -n "$TARGET_PID" ]; then
        export TARGET_PID
        echo "${lbl}PID for ${grn}'$1'${lbl} set to ${ylw}$TARGET_PID${dfl}"
    else
        echo "${lyl}No process found matching ${ong}'$1'${dfl}"
    fi
}

# Function to wait for a process to finish
afterPid() {
    while kill -0 "$TARGET_PID" 2>/dev/null; do
        sleep 1
    done
    "$@"
}