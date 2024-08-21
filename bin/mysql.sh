#!/bin/bash
basepath=$(cd `dirname $0`;pwd);
workspace=$(cd `dirname $0`;cd ..;pwd);

MYSQL_VERSION=8.0.39
ENV_FILE=$workspace/.env
MYSQL_CONF_ENV_FILE=$workspace/.env.mysql8
MYSQL8_EXPOSE_PORT=3336
MYSQL8_BASE_DIR=mysql8
MYSQL_CONTAINER_NAME=mysql8
MYSQL8_NETWORK=xy-mysql8

EC_CMD=

ARGS=$(getopt -o 'hm:p:v::' --long 'help,mount:,expose-port:,version::' -n "$0" -- "$@")
eval set -- "${ARGS}"

function show_help(){
  echo -e "\033[31mCommands Help :\033[0m";
  echo -e '\033[35m$ mysql: mysql <options?> command.\033[0m';
  echo -e "\033[35m$ -h or --help : help docs.\033[0m";
  echo -e "\033[35m$ -m or --mount : mount data volumes base path.\n\tIf input relative path will set current $workspace/data/{mountPath}\033[0m";
  echo -e "\033[35m$ -p or --expose-port : set container expose port,default 3336.\033[0m";
  echo -e "\033[35m$ -v or --version : build docker image version,not jar version.\033[0m";
  echo -e "\033[34mCommand:\033[0m";
  echo -e "\033[33m\t run or r : run an mysql container by image version.\033[0m";
  echo -e "\033[33m\t stop : stop ${MYSQL_CONTAINER_NAME} container.\033[0m";
  echo -e "\033[33m\t start : remove mysql5 & cache container.\033[0m";
  echo -e "\033[33m\t status : check ${MYSQL_CONTAINER_NAME} running.\033[0m";
  echo -e "\033[33m\t restart :restart ${MYSQL_CONTAINER_NAME} container.\033[0m";
  echo -e "\033[33m\t remove : remove ${MYSQL_CONTAINER_NAME}.\033[0m";
}

function source_env(){
  if [ ! -f $MYSQL_CONF_ENV_FILE ];then
    echo -e "\033[31mMysql install config file [${MYSQL_CONF_ENV_FILE}] not found.\n\t@See READMD.md\033[0m"
    exit 1
  else
    source $MYSQL_CONF_ENV_FILE
  fi

  if [[ -z "$MYSQL_ROOT_PASSWORD" || -z "$MYSQL_USER" || -z "$MYSQL_PASSWORD" ]];then
    echo -e "\033[31mMysql install config variables invalid. [MYSQL_ROOT_PASSWORD,MYSQL_USER,MYSQL_PASSWORD] \033[0m"
    exit 1
  fi
}

source_env

while true ; do
  # fetch first args,then use shift clear
  case "$1" in
    -h|--help) show_help; shift ;exit 1;;
    # -f|--force) FORCE_RMI=true ; shift ;;
    -m|--mount)
      case "$2" in
        "") shift 2 ;;
        *)
          if [[ "$2" =~ ^(/|\./)([a-zA-Z0-9_-]+/?)+$ && ! "$2" =~ // && ! "$2" =~ /$ ]];then
            MYSQL8_BASE_DIR=$2
            export MYSQL8_BASE_DIR=$MYSQL8_BASE_DIR
          else
            echo -e "\033[31mMonut base path arg illegal. $2.\033[0m"
            exit 1;
          fi
          shift 2 ;;
      esac ;;
    -p|--expose-port)
      case "$2" in
        "") shift 2 ;;
        *)
          echo $2
          if [[ "$2" =~ ^(([1-5]?[0-9]{4})|(6[0-4][0-9]{3})|(65[0-4][0-9]{2})|(655[0-2][0-9])|(6553[0-4]))$ ]];then
            MYSQL8_EXPOSE_PORT=$2 ;
          else
            echo -e "\033[31mExpose port illegal.requirement [1000~65534]. \033[0m";
            exit 1;
          fi
         shift 2 ;;
      esac ;;
    -v|--version)
      case "$2" in
        "") shift 2 ;;
        *)
          if [[ "$2" =~ ^([0-9]+(\.[0-9]+)?\.[0-9]{1,3})$ || "$2" == latest ]];then
            MYSQL_VERSION=$2
          else
            echo -e "\033[31mVersion arg illegal. $2 shuld x.x.x \n\033[0m"
            exit 1
          fi
          shift 2;;
      esac ;;
    --) shift ; break ;;
    *) echo "Internal error."; exit ;;
  esac
done

if [ "$1" != "" ];then
  if [[ "$1" =~ ^(run|r|start|stop|status|restart|remove)$ ]];then
    EC_CMD=$1
  else
    echo -e "\033[31m请选择操作 run[r],start,status,stop,restart or remove.\033[0m"
    exit 0;
  fi
else
  show_help;
  exit 0;
fi

function prepare_mysql_dirs(){
  if [[ "$MYSQL_BASE_DIR" =~ ^\./([a-zA-Z0-9_-]+/?)+$ ]];then
    MNT_BASE_VOL=${workspace}/data/${MYSQL_BASE_DIR:2}
  elif [[ "$MYSQL_BASE_DIR" =~ ^/([a-zA-Z0-9_-]+/?)+$ ]];then
    MNT_BASE_VOL=$MYSQL_BASE_DIR
  else
    MNT_BASE_VOL=${workspace}/data/${MYSQL_BASE_DIR}
  fi
  export MNT_BASE_VOL=$MNT_BASE_VOL

  if [ ! -d ${MNT_BASE_VOL}/data ];then
    mkdir -p ${MNT_BASE_VOL}/data
  fi

  if [ ! -d ${MNT_BASE_VOL}/log ];then
    mkdir -p ${MNT_BASE_VOL}/log
  fi

  if [ ! -d ${MNT_BASE_VOL}/conf ];then
    mkdir -p ${MNT_BASE_VOL}/conf
  fi

  if [ ! -f ${MNT_BASE_VOL}/conf/my.cnf ];then
    cp -f ${basepath}/resources/mysql8.cnf ${MNT_BASE_VOL}/conf/my.cnf
  fi
}

function check_networks(){
  network=$(docker network ls |grep "${MYSQL8_NETWORK}" | awk '{print $1}')
  if [ -z $network ] || [ "$network" == "" ];then
    docker network create -d bridge $MYSQL8_NETWORK
  fi
}

function run_mysql(){
  echo -e "\033[31m✨✨✨Start install ${MYSQL_CONTAINER_NAME}... \033[0m"
  docker run -td -p ${MYSQL8_EXPOSE_PORT}:3306 \
    --env-file=${MYSQL_CONF_ENV_FILE} --net=${MYSQL8_NETWORK} \
    -v ${MNT_BASE_VOL}/data:/var/lib/mysql \
    -v ${MNT_BASE_VOL}/log:/var/log/mysql \
    -v ${MNT_BASE_VOL}/conf:/etc/mysql/conf.d \
    --restart=always --name ${MYSQL_CONTAINER_NAME} \
    mysql:${MYSQL_VERSION}

  echo -e "\033[31mInstall ${MYSQL_CONTAINER_NAME} success.🚀🚀🚀🚀 \033[0m"
}


# exec commands
if [[ $EC_CMD =~ ^(run|r) ]];then
  prepare_mysql_dirs
  check_networks
  run_mysql
elif [[ $EC_CMD =~ ^(start) ]];then
  show_help
elif [[ $EC_CMD =~ ^(stop) ]];then
  show_help
elif [[ $EC_CMD =~ ^(status) ]];then
  show_help
elif [[ $EC_CMD =~ ^(restart) ]];then
  show_help
elif [[ $EC_CMD =~ ^(remove) ]];then
  show_help
else
  show_help
  exit 0
fi
