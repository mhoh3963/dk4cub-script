#!/bin/bash

SOURCE=/cubridsrc/cubrid
BACKPORT=/cubridsrc/backport/cubrid
RELEASED=/data/cubrid

if [ $# -eq 1 ]
then
	if [ "$1" == "release" -o "$1" == "debug" ]
	then
	        echo "transfer to build_x86_64_$1"
		CUBRID=$SOURCE/build_x86_64_$1/_install/CUBRID
		CUBRID_DATABASES=/data
	else
		if [ -d $RELEASED/CUBRID$1 ]
		then
			echo "transfer to v$1"
			CUBRID=$RELEASED/CUBRID$1
			CUBRID_DATABASES=$CUBRID/data
		else
			echo "Can't find $RELEASED/CUBRID$1 !!"
		fi
	fi
elif [ $# -eq 2 -a "$2" == "backport" ]
then
        if [ "$1" == "release" -o "$1" == "debug" ]
        then
	    echo "transfer to build_x86_64_$1 of backport"
	    CUBRID=$BACKPORT/build_x86_64_$1/_install/CUBRID
	    CUBRID_DATABASES=$CUBRID/data
	    unset LD_LIBRARY_PATH
	    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
        fi
else
	CUBRID=$SOURCE/build_x86_64_debug/_install/CUBRID
	CUBRID_DATABASES=/data
fi

old_ld_lib_path=`printenv OLD_LD_LIBRARY_PATH`
if [ "$old_ld_lib_path" = "" ]
then
	OLD_LD_LIBRARY_PATH=$LD_LIBRARY_PATH:
	export OLD_LD_LIBRARY_PATH
fi
LD_LIBRARY_PATH=$CUBRID/lib:$CUBRID/cci/lib:$OLD_LD_LIBRARY_PATH

old_path=`printenv OLD_PATH`
if [ "$old_path" = "" ]
then
	OLD_PATH=$PATH:
	export OLD_PATH
fi
PATH=$CUBRID/bin:$CUBRID/cubridmanager:$CUBRID/compat:$OLD_PATH:.
PATH=$PATH:/cubridsrc/gprofng_new/bin

old_infopath=`printenv OLD_INFOPATH`
if [ "$old_infopath" = "" ]
then
	OLD_INFOPATH=$INFOPATH:
	export OLD_INFOPATH
fi
INFOPATH=/cubridsrc/gprofng_new/share/info/:$OLD_INFOPATH
JAVA_HOME=/usr/lib/jvm/java-openjdk
CLASSPATH=$JAVA_HOME/lib:.

export CUBRID
export CUBRID_DATABASES
export LD_LIBRARY_PATH
export PATH
export JAVA_HOME
export INFOPATH
export CLASSPATH
export JAVA_TOOL_OPTIONS=-Dfile.encoding=utf8

if [ $# -ne 0 ]
then
	cubrid_rel
fi

alias vs="source /root/.cubrid.sh"
alias indent="indent -l120 -lc120"
alias astyle="astyle --style=gnu --mode=c --indent-namespaces --indent=spaces=2 -xT8 -xt4 --add-brackets --max-code-length=120 --align-pointer=name --indent-classes --pad-header --pad-first-paren-out"
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
alias src="cd /cubridsrc/cubrid/src"
alias data="cd /data"
alias bsrc="cd /cubridsrc/backport/cubrid/src"

#export MALLOC_CONF=stats_print:true
#export JEMALLOC_STATS_PRINT=1

case $- in    
  *i*) ;;
    *) return ;;
esac

#CUBRID_TMP=$CUBRID/var/CUBRID_SOCK
#TMP_DIR=$CUBRID/tmp
#TMPDIR=$CUBRID/tmp
##export CUBRID_TMP
#export TMP_DIR
#export TMPDIR
