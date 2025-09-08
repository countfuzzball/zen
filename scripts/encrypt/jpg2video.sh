#!/bin/sh

j=0
# convert options
pic="-resize 320x180 -background black -gravity center -extent 320x180"

# loop over the images
for i in *jpg; do
#for i in `ls *jpg | sort -R`; do
 echo "Convert $i"
 convert $pic "$i" "jpgcfcon-$j.jpg"
 j=`expr $j + 1`
done

# now generate the movie
mp3="file.mp3"
echo "make movie"
#-r is FPS.  -framerate is framerate-percentage
ffmpeg -framerate 2.0 -i jpgcfcon-%d.jpg -c:v libx264 -r 12 -pix_fmt yuv420p -s 320x180 -shortest out.mp4
#ffmpeg -framerate 3 -i jpgcfcon-%d.jpg -i $mp3 -acodec copy -c:v libx264 -r 30 -pix_fmt yuv420p -s 1920x1080 -shortest out.mp4
rm jpgcfcon*


#Name (if applicable)	Resolution (Width x Height)
#Wide VGA (WVGA)	854 × 480
#FWQVGA	432 × 240
#WQVGA	400 × 240
#HVGA (Wide)	480 × 272
#Quarter VGA (QVGA)	320 × 180
#Sub-QVGA	256 × 144
