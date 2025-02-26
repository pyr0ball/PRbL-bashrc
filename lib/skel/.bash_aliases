alias updateall="sudo apt-get update ; sudo apt-get upgrade -y ; sudo apt-get dist-upgrade -y ; sudo apt-get autoremove -y"
alias nclog="sudo docker run -it --rm --volume nextcloud_aio_nextcloud:/var/www/html:rw alpine sh -c 'less /var/www/html/data/nextcloud.log'"
alias superlocate='bash -xc '\''ag -g $0 --hidden'\''  2>/dev/null'
targetPid() {
    export TARGET_PID="$(pgrep -f "$1")"
}

# Function to wait for a process to finish
afterPid() {
    while kill -0 "$TARGET_PID" 2>/dev/null; do
        sleep 1
    done && "$@"
}