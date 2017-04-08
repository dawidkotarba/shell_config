# HYBRIS
### conts ###
HYBRIS_LOG=y.log

### generic ###
__on_hybris_platform(){
 rm -f $HYBRIS_LOG_PATH
 (cd $HYBRIS_HOME/bin/platform && $@ >> $HYBRIS_LOG_PATH &)
 sleep 1
 yy-log $@
}

__on_hybris_process(){
 local result=`ps -aux | grep hybris`
 echo "Operating on Hybris processes: $result"
 echo $result | awk {'print $2'} | xargs $@
}

# Checks the hybris suffix which is used to resolve the hybris path:
# i.e. hybris_sfx where sfx is a suffix.
__check_hybris_suffix(){
  [[ ! $HYBRIS_FOLDER_SUFFIX ]] && __echo_err "HYBRIS SUFFIX NOT SET!"
}

__get_hybris_process(){
  jcmd | grep tanukisoftware | awk {'print $1'}
}

__hybris-start(){
 __check_and_start_hybris_mysql
 __on_hybris_platform sh hybrisserver.sh debug $@
}

__check_hybris_mysql_running(){
  local is_mysql_running=$(yy-dockermysqlip)
    if [[ $is_mysql_running ]]
    then
      __echo_ok "hybris MYSQL is running"
      export HYBRIS_MYSQL_RUNNING=true
    else
      __echo_err "hybris MYSQL is NOT running"
      export HYBRIS_MYSQL_RUNNING=false
    fi
}

__check_and_start_hybris_mysql(){
  if [[ ! $HYBRIS_MYSQL_RUNNING ]]
   then
    yy-dockermysqlstart
    __check_hybris_mysql_running
  fi
}

### yy namespace ###
alias yy-start="__hybris-start"

# sets up the
yy-setsuffix(){
 export HYBRIS_FOLDER_SUFFIX=$1
 export HYBRIS_HOME=$REPOSITORY_PATH/hybris_$HYBRIS_FOLDER_SUFFIX/hybris
 export HYBRIS_LOG_PATH=$HYBRIS_HOME/$HYBRIS_LOG
}

yy-ps(){
 local hybris_process=`__get_hybris_process`
 if [[ ! $hybris_process ]]
  then __echo_err "HYBRIS IS NOT RUNNING"
  else __echo_ok "HYBRIS IS RUNNING: $hybris_process"
 fi
}

yy-navigate(){
 __check_hybris_suffix
 cd $HYBRIS_HOME
}

yy-navigatecustom(){
 __check_hybris_suffix
 cd $HYBRIS_HOME/bin/custom
}

yy-navigateconfig(){
 __check_hybris_suffix
 cd $HYBRIS_HOME/config
}

yy-navigateplatform(){
 __check_hybris_suffix
 cd $HYBRIS_HOME/bin/platform
}

# follow log
yy-log(){
 [[ $@ != *'-nolog'* ]] && tail -f $HYBRIS_LOG_PATH
}

# grep log by arguments
yy-grep(){
  for var in "$@"
 do
  grep $var $HYBRIS_LOG_PATH
 done
}

# show errors and warnings from log
yy-logerrorgrep(){
 grep -E 'ERROR|WARN' $HYBRIS_LOG_PATH
}

# follow only error and warnings in log
yy-logerrortail(){
  tail -f $HYBRIS_LOG_PATH | grep -E 'ERROR|WARN'
}

# show log with less
yy-logshow(){
 less $HYBRIS_LOG_PATH
}

# follow tomcat log
yy-logtomcat(){
 (yy-navigate && cd log/tomcat && ls -lt | grep console | tail -1 | awk '{print $9}' | xargs tail -f)
}

yy-setenv(){
 (yy-navigate-platform && sh setantenv.sh)
}

__yy-processes-to-kill(){
 ps aux | grep hybris | grep -v $HYBRIS_LOG | grep -v atom | awk '{print $2}' | xargs kill
}

yy-kill(){
 for i in {1..2}
 do
 __yy-processes-to-kill
 done

 sleep 1
 yy-ps
}

yy-restart(){
 yy-kill
 yy-start
}

yy-visualvm(){
 jvisualvm --openpid `__get_hybris_process` &
}

yy-jcmd(){
 jcmd `__get_hybris_process` help
}

yy-configlocalproperties(){
 __check_hybris_suffix
 atom $HYBRIS_HOME/config/local.properties
}

yy-configlocalextensions(){
 __check_hybris_suffix
 atom $HYBRIS_HOME/config/localextensions.xml
}

yy-restart(){
  yy-kill
  yy-start
}

# create a new folder for hybris project
yy-createproject(){
  local hybris_folder_suffix=$1
  yy-setsuffix $hybris_folder_suffix
  echo yy-setsuffix $hybris_folder_suffix >> $BASH_AUTOSTART_PATH
  mkdir $REPOSITORY_PATH/hybris_$hybris_folder_suffix
}

### HYBRIS ANT ###
yy-req(){
 local rev_back=$1
 local changes_count=`git diff --name-only HEAD..HEAD~$rev_back | egrep '.impex|items.xml' | wc -l`
 if [[ $changes_count > 0 ]]
  then echo "ant initialize"
  else echo "ant clean all"
fi
}

yy-jrebel(){
 local ext_path=$1
 if [[ $ext_path ]]
  then (cd $ext_path && ant build)
  else ant build
 fi
}

yy-grunt(){
   local ext_path=$1
    (cd $ext_path && grunt)
}

yy-antshow(){
  __on_hybris_platform ant -p
}

yy-antall(){
  __on_hybris_platform ant all $@
}

yy-antclean(){
 __on_hybris_platform ant clean
}

yy-antcleanall(){
 __on_hybris_platform ant clean all $@
}

yy-antbuild(){
 __on_hybris_platform ant build $@
}

yy-antupdatesystem(){
 __on_hybris_platform ant updatesystem $@
}

yy-antjunit(){
 __on_hybris_platform ant yunitinit
}

yy-antextgen(){
 __check_hybris_suffix
 cd $HYBRIS_HOME/bin/platform
 ant extgen
}

yy-antmodulegen(){
 __check_hybris_suffix
 cd $HYBRIS_HOME/bin/platform
 ant modulegen
}

yy-antinitialize(){
  __check_and_start_hybris_mysql
  __on_hybris_platform ant initialize $@
}

yy-anttest(){
  __on_hybris_platform ant clean all yunitinit alltests
}

yy-antserver(){
 __on_hybris_platform ant server
}

# Copies required mysql driver to dbdriver folder
yy-copydbdriver(){
 __check_hybris_suffix
 cp ~/APPS/Hybris/mysql/mysql-connector-java-5.1.35-bin.jar $HYBRIS_HOME/bin/platform/lib/dbdriver
}

__yy-get_mysql_container_name(){
  echo mysql_$HYBRIS_FOLDER_SUFFIX
}

# Starts docker mysql container
yy-dockermysqlstart(){
  __check_hybris_suffix
  kk-dockerstart $(__yy-get_mysql_container_name)
}

# Shows mysql docker IP
yy-dockermysqlip(){
  __check_hybris_suffix
  kk-dockerip $(__yy-get_mysql_container_name)
}

# Creates mysql docker container
# Usage: yy-dockermysqlcreate 5.6.31
yy-dockermysqlcreate(){
  __check_hybris_suffix
  local mysql_version=""
  [[ $1 ]] && mysql_version=:$1

  sudo docker run --name $(__yy-get_mysql_container_name) -e MYSQL_ROOT_PASSWORD=root -d mysql/mysql-server$mysql_version --innodb_flush_log_at_trx_commit=0
}

# Creates a db and adds all privileges to the db to user.
# Usage: yy-dockermysqlcreatedbuser dbName username userpassword
yy-dockermysqlcreatedbuser(){
  local db_name=$1
  local user_name=$2
  local user_pwd=$3
  local root_pwd=root
  sudo docker exec -i $(__yy-get_mysql_container_name) mysql -uroot -p$root_pwd <<< "CREATE DATABASE $db_name"
  sudo docker exec -i $(__yy-get_mysql_container_name) mysql -uroot -p$root_pwd <<< "CREATE USER $user_name IDENTIFIED BY '$user_pwd'"
  sudo docker exec -i $(__yy-get_mysql_container_name) mysql -uroot -p$root_pwd <<< "GRANT ALL PRIVILEGES ON $db_name.* TO $user_name"
}
