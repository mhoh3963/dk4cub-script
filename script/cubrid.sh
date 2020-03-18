CUBRID=/cubrid
CUBRID_DATABASES=/data
ld_lib_path=`printenv LD_LIBRARY_PATH`
if [ "$ld_lib_path" = "" ]
then
LD_LIBRARY_PATH=$CUBRID/lib
else
LD_LIBRARY_PATH=$CUBRID/lib:$LD_LIBRARY_PATH
fi
#SHLIB_PATH=$LD_LIBRARY_PATH
#LIBPATH=$LD_LIBRARY_PATH
PATH=$CUBRID/bin:$CUBRID/cubridmanager:$CUBRID/compat:$PATH:.
JAVA_HOME=/usr/lib/jvm/java-openjdk
export CUBRID
export CUBRID_DATABASES
export LD_LIBRARY_PATH
#export SHLIB_PATH
#export LIBPATH
export PATH
export JAVA_HOME

