#!/bin/bash

usage_info="This script allows to switch the active CUDA version between all installed versions.
Syntax: ./switch_cuda [options] [cuda-version [options]].

Parameters:
	Positional:
		cuda-version	Version number of wanted CUDA installation,
				e.g. ./switch_cuda 7.0 for CUDA 7.0.
	Optional:
		-c		Directory that contains CuDNN. If left empty,
				CuDNN will not be installed. However, old
				existing versions will not be touched.
				Example: ./switch_cuda 7.0 -c ~/Downloads/cudnn5.1/cuda/
		
		-i 		List your current CUDA/CuDNN setup

		-s		Location for your active CUDA version symlink.
				Only required if different to /usr/local/cuda,
				which probably does not apply to you.
		
		-h		Display this help message."



OPTIND=1
cuda_version="NOT_FOUND"
cuda_symlink=/usr/local/cuda
use_cudnn=0
cudnn_folder="NOT REQUIRED"

function list_current_setup {
	if ! [[ -d $cuda_symlink ]]
		then
			echo "CUDA is not installed (at least in the default location)"
	else
		ls -l $cuda_symlink | egrep -o \\cuda-[0-9]+\.[0-9]+
		if ! [[ -f $cuda_symlink/include/cudnn.h ]]
			then
				echo "No CuDNN"
		else
			echo "CuDNN:"
			cat $cuda_symlink/include/cudnn.h |
			egrep -o "CUDNN_MAJOR *[0-9]+|CUDNN_MINOR *[0-9]+|CUDNN_PATCHLEVEL *[]0-9]+" |
			egrep -o [0-9] |
			tr '\n' '.' && echo " "
		fi
	fi
}

#First argument must be CUDA version
if [ $# -lt 1 ] 
then
	echo "Missing CUDA version."
	echo "$usage_info"
	exit 1
else
	number_regex=\^[0-9]\+\([.][0-9]\+\)\?\$ 
	if ! [[ $1 =~ $number_regex ]] 
		then
			if [[ $1 =~ \-i ]];
				then
				# Display info about current setup
				echo "Currently using:"
				list_current_setup
				echo "---"
				echo "The following CUDA versions are available:"
				ls  $cuda_symlink/.. | grep ^cuda-
				exit 0
				
			fi
			if ! [[ $1 =~ \-h ]];
				then
					echo "Given CUDA version is not a number."
			fi
			echo "$usage_info"
			exit 1
	fi
	cuda_version=$1
fi
shift

#Parse remaining arguments
while getopts "c:hs:?" opt; do
	case "$opt" in
		c)
			use_cudnn=1
			cudnn_folder=$OPTARG
			;;
		h)
			echo usage_info
			exit 0
			;;
		s)
			cuda_symlink=$OPTARG
			;;
		*)
			echo "Unrecognized option $opt."
			echo usage_info
			exit 0
			;;
	esac 
done
shift $((OPTIND-1))

#Check for sudo privileges
if [ "$EUID" -ne 0 ]
  then 
	echo "Switching CUDA version requires root. Abort."
  exit 1
fi

#Check if given CUDA installation exists
cuda_install_folder=$cuda_symlink-$cuda_version 
if [ ! -d $cuda_install_folder ]
then
	echo "$cuda_install_folder does not exist."
	echo "The following CUDA versions are available:"
	ls  $cuda_symlink/.. | grep ^cuda-
	exit 1
fi


delete_cudnn=1
#Delete symlink, don't mess with anything that isn't a symlink
if [ -L $cuda_symlink ]
then
	sudo rm $cuda_symlink
elif [ -e $cuda_symlink ]
then
	echo "$cuda_symlink is not a symlink. I didn't touch anything."
	exit 1
fi

#Create new symlink
sudo ln -s $cuda_install_folder $cuda_symlink



#Optionally install new CuDNN
if [ $use_cudnn -eq 1 ]
	then
		
		#Remove existing CuDNN
		cudnn_header="$cuda_symlink/include/cudnn.h"
		if [ -e $cudnn_header ]
			then
				sudo rm $cudnn_header
		fi

		num_cudnn_libs=$(ls $cuda_symlink/lib64/ | grep ^libcudnn | wc -l)
		if [ $num_cudnn_libs -gt 0 ]
			then
				sudo rm $cuda_symlink/lib64/libcudnn*
		fi
		cudnn_header="$cudnn_folder/include/cudnn.h"
		cudnn_libs="$cudnn_folder/lib64"
		num_cudnn_libs=$(ls $cudnn_folder/lib64 | grep ^libcudnn | wc -l)
		if [ ! -e $cudnn_header ] || [ $num_cudnn_libs -ne 4 ]
			then
				echo "Supplied CuDNN folder does not contain valid CuDNN files. Abort."
				echo $usage_info
				exit 1
		fi
			echo "Enabeling CuDNN..."
			sudo cp -P $cudnn_header $cuda_symlink/include
			sudo cp -P $cudnn_libs/libcudnn* $cuda_symlink/lib64
			sudo chmod a+r $cuda_symlink/lib64/libcudnn*
fi

#make changes known to system
sudo ldconfig $cuda_symlink/lib64
sudo updatedb
echo "Switched to the following setup:"
list_current_setup
exit 0
