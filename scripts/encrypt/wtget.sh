#!/bin/bash

python3 /home/pi/Downloads/yt-dlp --verbose --js-runtimes deno:/home/pi/.deno/bin/deno --remote-components ejs:github --cookies-from-browser chromium $1
