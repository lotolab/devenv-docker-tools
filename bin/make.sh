#!/bin/bash
basepath=$(cd `dirname $0`;pwd);
workspace=$(cd `dirname $0`;cd ..;pwd);

# if update EXTERNAL_NETWORK make sure update compose file also.
EXTERNAL_NETWORK=xy-network
ENV_FILE=${workspace}/.env
BASE_VOL=dbdata
EC_CMD=


ARGS=$(getopt -o 'hm:v::' --long 'help,mount:,version::' -n "$0" -- "$@")
eval set -- "${ARGS}"

echo [$@]

function show_help() {
  echo -e "\033[31mCommands Help :\033[0m";
  echo -e '\033[35m$ make: make <options?> command.\033[0m';
  echo -e "\033[35m$ make -h or --help : help docs.\033[0m";
  echo -e "\033[35m$ make -m or --mount : mount data volumes base path.\n\tIf input relative path will set current $workspace/data/{mountPath}\033[0m";
  echo -e "\033[35m$ make -v or --version : build docker image version,not jar version.\033[0m";
  echo -e "\033[34mCommand:\033[0m";
  echo -e "\033[33m\t up or u : up mysql5 & redis.\033[0m";
  echo -e "\033[33m\t down or d : remove mysql5 & cache container.\033[0m";
  echo -e "\033[33m\t check or v : check data dirs and validate network.\033[0m";
}

function source_env(){
  if [ ! -f $ENV_FILE ];then
    echo -e "\033[31mEnv file not find.please configuration.\033[0m"
    exit 1
  fi

  source $ENV_FILE

  if [[ !($MYSQL_EXPOSE_PORT =~ ^(([1-5]?[0-9]{4})|(6[0-4][0-9]{3})|(65[0-4][0-9]{2})|(655[0-2][0-9])|(6553[0-4]))$ ) ]];then
    echo -e "\033[31m enviroment config parameter MYSQL_EXPOSE_PORT invalid [1000~65535].\033[0m"
    exit 1
  fi

  if [[ !($REDIS_EXPOSE_PORT =~ ^(([1-5]?[0-9]{4})|(6[0-4][0-9]{3})|(65[0-4][0-9]{2})|(655[0-2][0-9])|(6553[0-4]))$ ) ]];then
    echo -e "\033[31m enviroment config parameter REDIS_EXPOSE_PORT invalid [1000~65535].\033[0m"
    exit 1
  fi
}

source_env

while true ; do
  # fetch first args,then use shift clear
  case "$1" in
    -h|--help) show_help; shift ;exit 1;;
    # -g|--gateway) IS_GATEWAY=true ;convert_is_gateway; shift ;;
    # env-file
    # -f|--force) FORCE_RMI=true ; shift ;;
    # -e|--env)
    #   case "$2" in
    #     "") shift 2 ;;
    #     *)
    #       echo $2
    #       if [[ "$2" =~ ^(.env)([\.a-zA-Z0-9_]+)?$ ]];then
    #         ENV_FILE=$2 ;
    #       else
    #         echo -e "\033[31mEnv file name illegal.\033[0m";
    #         exit 1;
    #       fi
    #      shift 2 ;;
    #   esac ;;
    -m|--mount)
      case "$2" in
        "") shift 2 ;;
        *)
          if [[ "$2" =~ ^(/|\./)([a-zA-Z0-9_-]+/?)+$ && ! "$2" =~ // && ! "$2" =~ /$ ]];then
            BASE_VOL=$2
            export BASE_VOL=$BASE_VOL
          else
            echo -e "\033[31mMonut base path arg illegal. $2.\033[0m"
            exit 1;
          fi
          shift 2 ;;
      esac ;;
    -v|--version)
        echo -e "version 1.0.0"
        shift;exit 0;;
    --) shift ; break ;;
    *) echo "Internal error."; exit ;;
  esac
done

if [ "$1" != "" ];then
  if [[ "$1" =~ ^(up|u|down|d|check|v)$ ]];then
    EC_CMD=$1
  else
    echo -e "\033[31m请选择操作 up[u],down[d] or check[v].\033[0m"
    exit 0;
  fi
else
  show_help;
  exit 0;
fi

function export_mount_base_vol(){
  if [[ "$BASE_VOL" =~ ^\./([a-zA-Z0-9_-]+/?)+$ ]];then
    MNT_BASE_VOL=${workspace}/data/${BASE_VOL:2}
  elif [[ "$BASE_VOL" =~ ^/([a-zA-Z0-9_-]+/?)+$ ]];then
    MNT_BASE_VOL=$BASE_VOL
  else
    MNT_BASE_VOL=${workspace}/data/${BASE_VOL}
  fi

  echo -e "$MNT_BASE_VOL"
  export MNT_BASE_VOL=$MNT_BASE_VOL
}

function prepare_data_dir(){
  export_mount_base_vol

  if [ ! -d $MNT_BASE_VOL/mysql ];then
    mkdir -p $MNT_BASE_VOL/mysql
    if [ $? -ne 0 ];then
      echo -e "\033[31mPlease check user permission.\033[0m"
      exit 1
    fi
  fi
  if [ ! -d $MNT_BASE_VOL/share ];then
    mkdir -p $MNT_BASE_VOL/share
  fi
    if [ ! -d $MNT_BASE_VOL/redis ];then
    mkdir -p $MNT_BASE_VOL/redis
  fi
}

function pre_check_network() {
  network=$(docker network ls |grep "${EXTERNAL_NETWORK}" | awk '{print $1}')
  if [ -z $network ] || [ "$network" == "" ];then
    docker network create -d bridge $EXTERNAL_NETWORK
  fi
}

function up_container(){
  docker compose --env-file=$ENV_FILE -f ${workspace}/docker-compose.yml up -d
}

function down_container(){
  docker compose --env-file=$ENV_FILE -f ${workspace}/docker-compose.yml down
}

# exec commands
if [[ $EC_CMD =~ ^(up|u) ]];then
  prepare_data_dir
  pre_check_network
  up_container
elif [[ $EC_CMD =~ ^(down|d) ]];then
  prepare_data_dir
  pre_check_network
  down_container
elif [[ $EC_CMD =~ ^(check|v) ]];then
  export_mount_base_vol
  prepare_data_dir
  pre_check_network
else
  show_help
  exit 0
fi
