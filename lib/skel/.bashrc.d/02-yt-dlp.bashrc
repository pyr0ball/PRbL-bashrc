alias grabVideo='yt-dlp --output "%(title)s.%(ext)s" --restrict-filenames --write-sub --sub-lang en --convert-subs srt --write-auto-sub'
alias grabAudio='yt-dlp --extract-audio --audio-format mp3 --output "%(title)s.%(ext)s" --restrict-filenames'
alias grabAlbum='yt-dlp --extract-audio --audio-format mp3 --output "%(title)s.%(ext)s" --restrict-filenames --split-chapters'
