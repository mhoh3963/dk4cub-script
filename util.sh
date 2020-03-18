#! /bin/bash
#set -x

function trim()
{
local __STR=$1

	if [ -n "$STR" ]
	then
		__STR=`echo $__STR | sed -e 's/^ *//g' -e 's/ *$//g'`
	fi

	echo $__STR
}

function cut_trim()
{
local __STR=$1
local __SEL=$2
local __DEL=$3

	if [ -n "$__STR" -a -n "$__SEL" ]
	then	
		if [ -z "$__DEL" ]
		then
			__STR=`echo $__STR | cut -f $__SEL`
		else
			__STR=`echo $__STR | cut -f $__SEL -d $__DEL`
		fi
	fi
	echo $(trim "$__STR")
}

function is_exist_image()
{
local __NAME=$(cut_trim $1 1 ":")
local __TAG=$(cut_trim $1 2 ":")
local __VALUE=`docker images | grep $__NAME | xargs | cut -d" " -f 2`

	if [ "$__VALUE" == "$__TAG" ]
	then
		echo "1"
	else
		echo "0"
	fi
}

function is_exist_container()
{
local __HOSTNAME=$1
local __VALUE=`docker ps -a | grep $__HOSTNAME | rev | xargs | cut -d" " -f 1 | rev`

    if [ "$__VALUE" == "$__HOSTNAME" ]
    then
        echo "1"
    else
        echo "0"
    fi
}

function build_docker()
{
local __IMAGE=$1
local __DOCKER_FILE=$2
local __TEMP_FILE=$3

	docker build --force-rm=true --no-cache=true -t $__IMAGE -f $__DOCKER_FILE . > $__TEMP_FILE

	if [ $(is_exist_image $__IMAGE) -eq 1 ]
	then
		echo "1"
	else
		echo "0"
	fi
}
