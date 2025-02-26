alias updateall="sudo apt-get update ; sudo apt-get upgrade -y ; sudo apt-get dist-upgrade -y ; sudo apt-get autoremove -y"
alias superlocate='bash -xc '\''ag -g $0 --hidden'\''  2>/dev/null'
alias grabVideo='yt-dlp --output "%(title)s.%(ext)s" --restrict-filenames --write-sub --sub-lang en --convert-subs srt --write-auto-sub'
alias grabAudio='yt-dlp --extract-audio --audio-format mp3 --output "%(title)s.%(ext)s" --restrict-filenames'
alias grabAlbum='yt-dlp --extract-audio --audio-format mp3 --output "%(title)s.%(ext)s" --restrict-filenames --split-chapters'
