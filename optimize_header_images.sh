# !/usr/bin/bash

# This script wont work without imagemagick
imagemagick_path=$(command -v magick)
if [ ${#imagemagick_path} -eq 0 ]
then
	echo "You need imagemagick's convert command to use this script"
	exit 1
fi
imagemagick_command=""

script_dir=$(dirname $0)
image_dir="${script_dir}/public/static/img"
user_has_mozjpeg=0

sizes_array=("1200" "920" "768" "480")
aspect_ratio_array=(1 3)

# Check to see if the user has mozjpeg availability
mozjpeg_path=$(command -v mozjpeg)

if [ ${#mozjpeg_path} -gt 0 ]
then
	user_has_mozjpeg=1
fi

for image in ${image_dir}/header-img/*
do
	file_base=$(basename ${image})
	file_extension="${file_base##*.}"
	file_name="${file_base%.*}"
	file_original_dimensions_string=$(identify -ping -format '%w %h' "${image}")
	file_original_dimensions_array=(${file_original_dimensions_string})
	file_original_width="${file_original_dimensions_array[0]}"
	file_original_height="${file_original_dimensions_array[1]}"

	# Check and see if the current width is the aspect ratio set.
	file_original_aspect_ratio_height=$(expr ${file_original_width} / ${aspect_ratio_array[1]})

	if [ ${file_original_aspect_ratio_height} -ne ${file_original_width} ]
	then
		# If not, make a crop of the image at the correct size and use that image
		# to base all image scale reductions on.
		total_height_takeaway=$(expr ${file_original_height} - ${file_original_aspect_ratio_height})
		height_offset=$(expr ${total_height_takeaway} / 2)
		new_image_name="${file_name}_optimized.${file_extension}"
		new_image="${image_dir}/optimized-images/${new_image_name}"
		convert "${image}" -crop "${file_original_width}x${file_original_aspect_ratio_height}+0+${height_offset}" "${new_image}"
		image="${new_image}"
	fi

	# echo "${file_original_aspect_ratio_height}"
	# echo "${file_original_width}"

	# imagemagick_command="convert ${image}"
	if [ ${user_has_mozjpeg} -gt 0 ] && [ "${file_extension}" = "jpg" ]
	then
		# identify -ping -format '%w %h' "${image}"
		identify "${image}"
		echo ""
	fi

	for i in "${sizes_array[@]}"
	do
		opti_image_name="${image_dir}/optimized-images/${file_name}_optimized_${i}.${file_extension}"
		opti_image_file_height=$(expr ${i} / ${aspect_ratio_array[1]})
		if [ ${user_has_mozjpeg} -gt 0 ]
		then
			convert "${image}" -resize "${i}x${opti_image_file_height}" PNM:- | mozcjpeg -quality 70 > "${opti_image_name}"
		else
			echo convert
		fi
	done
	# echo ${file_base}
	# echo ${file_extension}
	# echo ${file_name}
done