#! /bin/bash
#set -x

source ./util.sh

PURPOSE="dev"
OS="76"
HOSTNAME="cub-`date +%Y%m%d`"
IMAGE=""
IP=""
RUN_TYPE="daemon"
PRIVILEGED="true"
CAP_OPTION="ALL"
BIN=""
SRC=""
DATA=""
P22=""
P80=""
P1523=""
P8001=""
P8002=""
P30000=""
P33000=""
P59901=""

function print_usage()
{
        echo "Usage) run.sh conf-file"
        echo "       run container with conf-file"
}

function parse_generic()
{
local __LEFT_STR=$1
local __RIGHT_STR=$2

	case $__LEFT_STR in
		purpose)	PURPOSE=$__RIGHT_STR ;;
		os)			OS=$__RIGHT_STR ;;
		hostname)	HOSTNAME=$__RIGHT_STR ;;
	esac
}

function parse_docker()
{
local __LEFT_STR=$1
local __RIGHT_STR=$2

	case $__LEFT_STR in
		image)		IMAGE=$__RIGHT_STR ;;
		ip)			IP=$__RIGHT_STR ;;
		run_type)	RUN_TYPE=$__RIGHT_STR ;;
		privleged)	PRIVLEGED=$__RIGHT_STR ;;
		cap_option) CAP_OPTION=$__RIGHT_STR ;;
	esac
}

function parse_directory()
{
local __LEFT_STR=$1
local __RIGHT_STR=$2

	case $__LEFT_STR in
		bin)		BIN=$__RIGHT_STR ;;
		src)		SRC=$__RIGHT_STR ;;
		data)		DATA=$__RIGHT_STR ;;
	esac
}

function parse_port()
{
local __LEFT_STR=$1
local __RIGHT_STR=$2

	case $__LEFT_STR in
		p22)		P22=$__RIGHT_STR ;;
		p80)		P80=$__RIGHT_STR ;;
		p1523)		P1523=$__RIGHT_STR ;;
		p8001)		P8001=$__RIGHT_STR ;;
		p8002)		P8002=$__RIGHT_STR ;;
		p30000)		P30000=$__RIGHT_STR ;;
		p33000)		P33000=$__RIGHT_STR ;;
		p59901)		P59901=$__RIGHT_STR ;;
	esac
}

function get_options()
{
OPTIONS=""

	if [ $RUN_TYPE == "console" ]
	then
		OPTIONS="$OPTIONS -it"
	else
		OPTIONS="$OPTIONS -d"
	fi

	OPTIONS="$OPTIONS --name $HOSTNAME --hostname $HOSTNAME"

#	if [ -n "$IP" ]
#	then
#		OPTIONS="$OPTIONS --ip $IP"
#	fi

	if [ $OS == "76" -a $RUN_TYPE == "daemon" ]
	then
		OPTIONS="$OPTIONS -e container=docker"
	fi

	if [ $PURPOSE == "man" -a -n "$SRC" ]
	then
		OPTIONS="$OPTIONS -v $SRC:/manual"
	elif [ $PURPOSE == "test" -a -n "$BIN" -a -n "$DATA" ]
	then
		OPTIONS="$OPTIONS -v $BIN:/cubrid -v $DATA:/data"
	elif [ $PURPOSE == "dev" -a -n "$BIN" -a -n "$SRC" -a -n "$DATA" ]
	then
		OPTIONS="$OPTIONS -v $BIN:/cubrid -v $SRC:/cubridsrc -v $DATA:/data"
	else
		echo ""
		return
	fi

	if [ $PRIVILEGED == "true" ]
	then
		OPTIONS="$OPTIONS --privileged=true"
		for cap in $CAP_OPTION
		do
			OPTIONS="$OPTIONS --cap-add=$cap"
		done
	fi

	if [ $RUN_TYPE == "daemon" -a -z "$P22" ]
	then
		echo ""
		return
	elif [ -n "$P22" ]
	then
		OPTIONS="$OPTIONS -p $P22:22"
	fi

	if [ $PURPOSE == "man" -o $PURPOSE == "test" ]
	then
		if [ -n "$P80" ]
		then
			OPTIONS="$OPTIONS -p $P80:80"
		fi
	else
		if [ -n "$P1523" ]
		then
			OPTIONS="$OPTIONS -p $P1523:1523"
		fi

		if [ -n "$P8001" ]
		then
			OPTIONS="$OPTIONS -p $P8001:8001"
		fi

		if [ -n "$P8002" ]
		then
			OPTIONS="$OPTIONS -p $P8002:8002"
		fi

		if [ -n "$P30000" ]
		then
			OPTIONS="$OPTIONS -p $P30000:30000"
		fi

		if [ -n "$P33000" ]
		then
			OPTIONS="$OPTIONS -p $P33000:33000"
		fi

		if [ -n "$P59901" ]
		then
			OPTIONS="$OPTIONS -p $P59901:59901"
		fi
	fi

	OPTIONS="$OPTIONS cubrid-${PURPOSE}${OS}:1.0" 

	if [ $RUN_TYPE == "console" ]
	then
		OPTIONS="$OPTIONS /bin/bash"
	elif [ $OS == "76" ]
	then
		OPTIONS="$OPTIONS /sbin/init"
	fi

	echo $OPTIONS

	return
}

function run_container()
{
local __OPTIONS=$1
local __CONTAINER=""

	if [ $(is_exist_container $HOSTNAME) -eq 1 ]
	then 
		echo "2"
		return
	fi

	__CONTAINER=`docker run $__OPTIONS`

	if [ $(is_exist_container $HOSTNAME) -eq 1 ]
	then 
		echo "1"
		return
	fi

	echo "0"
	return
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
		line=`echo $line | tr -d ' '`

		FIRST_CHAR=`echo ${line:0:1}`

		if [ -z $FIRST_CHAR ]; then continue; fi

		if [ $FIRST_CHAR == "[" ]
		then
			SECTION=`echo ${line:1} | cut -d"]" -f 1`
		elif [ $FIRST_CHAR != "#" -a -n "$FIRST_CHAR" ]
		then
			LEFT_STR=`echo $line | cut -d"=" -f 1`
			RIGHT_STR=`echo $line | cut -d"=" -f 2`
			if [ $LEFT_STR != "" -a -n "$RIGHT_STR" ]
			then
				case $SECTION in
					generic) parse_generic $LEFT_STR $RIGHT_STR ;;
					docker) parse_docker $LEFT_STR $RIGHT_STR ;;
					directory) parse_directory $LEFT_STR $RIGHT_STR ;;
					port) parse_port $LEFT_STR $RIGHT_STR ;;
				esac
			fi
		fi
	done < $CONF_FILE
else
	echo "[ERROR] Can't find $CONF_FILE !!"
	exit
fi

OPTIONS=$(get_options)

if [ -z "$OPTIONS" ]
then
	echo "[ERROR] Can't make options for container !!"
	exit
fi

#echo $OPTIONS

if [ $(is_exist_image $IMAGE) -eq 0 ]
then
	echo "[ERROR] Can't find the image ($IMGAE))."
	echo "        You need to run \"build.sh\", before execute run.sh"
	exit
fi

return_value=$(run_container "$OPTIONS")
case $return_value in
	0) echo "[ERROR] Can't make a container with the name ($HOSTNAME)." ;;
	1) echo "[SUCCESS] Make a container with the name ($HOSTNAME)." ;;
	2) echo "[ERROR] Already exists a container with same name ($HOSTNAME)." ;;
	*) echo "$return_value"
esac

exit
