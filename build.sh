#! /bin/bash
#set -x
source ./util.sh

TEMP_DIR="./tmp"
TEMP_PREFIX=`date +%j%H%M%S-%N`
MAINTAINER="mhoh <mhoh@cubrid.com>"
PURPOSE="dev"
BASEIMG_FROM=""
BASEIMG_TO=""
BASEIMG_FILE=""
PURIMG_TO=""
PURIMG_ADD_FILES=()
PURIMG_RUN_CMD=()
PURIMG_VOLUME=""
PURIMG_ENTRYPOINT=""
PURIMG_EXPOSE=""

function print_usage()
{
        echo "Usage) build.sh conf-file"
        echo "       make docker images with conf-file"
}

function find_make_bimage()
{
local __DOCKER_FILE="$TEMP_DIR/$TEMP_PREFIX.bimage"

	if [ $(is_exist_image $BASEIMG_TO) -eq 1 ]
	then
		echo "2"
		return
	fi

	printf '%s %s\n' "FROM" $BASEIMG_FROM > $__DOCKER_FILE
	printf '%s %s\n\n'  "MAINTAINER" $MAINTAINER >> $__DOCKER_FILE

	if [ -f $BASEIMG_FILE ]
	then
		cat $BASEIMG_FILE >> $__DOCKER_FILE
	else
		echo "0"
		return
	fi

	if [ $(build_docker $BASEIMG_FROM $__DOCKER_FILE $TEMP_PREFIX) -eq 1 ]
	then
		echo "1"
	else
		echo "0"
	fi

	return
}

function find_make_dimage()
{
local __DOCKER_FILE="$TEMP_DIR/$TEMP_PREFIX.dimage"
local __OUTPUT_FILE="$TEMP_DIR/$TEMP_PREFIX.output"

	if [ $(is_exist_image $PURIMG_TO) -eq 1 ]
	then
		echo "2"
		return
	fi

	printf '%s\n' "FROM $BASEIMG_TO" > $__DOCKER_FILE
	printf '%s\n\n' "MAINTAINER $MAINTAINER" >> $__DOCKER_FILE

	printf "VOLUME [" >> $__DOCKER_FILE
	for (( i=0; i<${#PURIMG_VOLUME[@]}; i++));
	do
		printf '"%s"' "${PURIMG_VOLUME[$i]}" >> $__DOCKER_FILE
		if [ $i -lt $((${#PURIMG_VOLUME[@]}-1)) ]
		then
			printf ',' >> $__DOCKER_FILE
		fi
	done
	printf "]\n\n" >> $__DOCKER_FILE
		
	for (( i=0; i<${#PURIMG_ADD_FILES[@]}; i++))
	do
		if [ -f $(cut_trim "${PURIMG_ADD_FILES[$i]}", 1 ":") ] 
		then
			printf '%s %s %s\n'  "ADD" $(cut_trim "${PURIMG_ADD_FILES[$i]}" 1 ":") $(cut_trim "${PURIMG_ADD_FILES[$i]}" 2 ":") >> $__DOCKER_FILE
		fi
	done
	printf "\n" >> $__DOCKER_FILE

	for (( i=0; i<${#PURIMG_RUN_CMD[@]}; i++));
	do
		printf '%s %s\n'  "RUN" "${PURIMG_RUN_CMD[$i]}" >> $__DOCKER_FILE
	done
	printf "\n" >> $__DOCKER_FILE

	printf '%s ["%s"]\n\n' "ENTRYPOINT" "$PURIMG_ENTRYPOINT" >> $__DOCKER_FILE
	printf '%s %s\n' "EXPOSE" "$PURIMG_EXPOSE" >> $__DOCKER_FILE

	if [ $(build_docker $PURIMG_TO $__DOCKER_FILE $__OUTPUT_FILE) -eq 1 ]
	then
		echo "1"
	else
		echo "0"
	fi
}


function parse_generic()
{
local __LEFT_STR=$1
local __RIGHT_STR=$2

	case $__LEFT_STR in
		maintainer)		MAINTAINER=$__RIGHT_STR ;;
		purpose)		PURPOSE=$__RIGHT_STR ;;
	esac
}

function parse_base_image()
{
local __LEFT_STR=$1
local __RIGHT_STR=$2

	case $__LEFT_STR in
		from)		BASEIMG_FROM=$__RIGHT_STR ;;
		to)			BASEIMG_TO=$__RIGHT_STR ;;
		file)		BASEIMG_FILE=$__RIGHT_STR ;;
	esac
}

function parse_purpose_image()
{
local __LEFT_STR=$1
local __RIGHT_STR=$2

	case $__LEFT_STR in
		to)				PURIMG_TO=$__RIGHT_STR ;;
		add-files)		PURIMG_ADD_FILES+=("$__RIGHT_STR") ;;
		run-command)	PURIMG_RUN_CMD+=("$__RIGHT_STR") ;;
		volume)			PURIMG_VOLUME=($__RIGHT_STR) ;;
		entrypoint)		PURIMG_ENTRYPOINT=$__RIGHT_STR ;;
		expose)			PURIMG_EXPOSE=$__RIGHT_STR ;;
	esac
}
#
# main routine
#

if [ $# -ne 1 ]
then
	print_usage
	exit
else
	CONF_FILE=$1
fi

SECTION=""

if [ -f "$CONF_FILE" ]
then
	while read line
	do
		line=$(trim "$line")

		FIRST_CHAR=`echo ${line:0:1}`

		if [ -z "$FIRST_CHAR" ]; then continue; fi

		if [ $FIRST_CHAR == "#" ]; then continue;
		elif [ $FIRST_CHAR == "[" ]
		then
			SECTION=$(cut_trim "${line:1}" 1 "]")
		elif [ $FIRST_CHAR == "}" ]
		then
			KEEP_PARAMETER=""
		else
			LEFT_STR=$(cut_trim "$line" 1 "=")
			RIGHT_STR=$(cut_trim "$line" 2 "=")

			if [ -n "$LEFT_STR" -a -n "$RIGHT_STR" -a "$RIGHT_STR" == "{" ]
			then
				KEEP_PARAMETER=$LEFT_STR
			else
				if [ -n "$KEEP_PARAMETER" ]
				then
					LEFT_STR=$KEEP_PARAMETER
					RIGHT_STR=$line
				fi			

				if [ -n "$LEFT_STR" -a -n "$RIGHT_STR" ]
				then
					case $SECTION in
						generic)		parse_generic $LEFT_STR "$RIGHT_STR" ;;
						base-image)		parse_base_image $LEFT_STR "$RIGHT_STR" ;;
						purpose-image)	parse_purpose_image $LEFT_STR "$RIGHT_STR" ;
					esac
				fi
			fi
		fi
	done < $CONF_FILE
else
	echo "[ERROR] Can't find $CONF_FILE !!"
	exit
fi

OS_MAJOR_VER=$(cut_trim $(cut_trim $BASEIMG_FROM 2 ":") 1 ".")
if [ $PURPOSE == "man" -a $OS_MAJOR_VER -lt 7 ]
then
	echo "[ERROR] It can't be made the base image for manual with $BASEIMG_FROM."
	exit
fi

if [ ! -d $TEMP_DIR ]
then
	mkdir $TEMP_DIR
fi

ret=$(find_make_bimage)
if [ $ret == 0 ]
then
	echo "[ERROR] It can't be made the base image. please check $TEMP_PREFIX.bimage."
	exit
fi

ret=$(find_make_dimage)
case $ret in
	0) echo "[ERROR] It can't be made $PURIMG_TO with $BASEIMG_TO. please check files ($TEMP_DIR/$TEMP_PREFIX.*)" ;;
	1) echo "[SUCCESS] $PURIMG_TO" ;;
	2) echo "[ERROR] Alredy, exist $PURIMG_TO" ;;
esac
