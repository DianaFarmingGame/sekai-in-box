#!/bin/sh

for file in "$@"
do
    convert $file -crop 96x96+0+0 temp_part1.png
    convert $file -crop 96x96+98+0 temp_part2.png
    convert $file -crop 96x96+196+0 temp_part3.png
    convert $file -crop 96x96+294+0 temp_part4.png
    convert $file -crop 96x96+392+0 temp_part5.png
    convert $file -crop 96x96+490+0 temp_part6.png
    convert $file -crop 96x96+588+0 temp_part7.png
    convert $file -crop 96x96+686+0 temp_part8.png

    mkdir -p result
    convert temp_part1.png temp_part2.png temp_part3.png temp_part4.png temp_part5.png temp_part6.png temp_part7.png temp_part8.png +append result/$file
done

rm temp_part*.png
