# Local Common development enviroment

> Mysql 5 & redis 7

## Env

```bash
BASE_VOL=vm-data
MYSQL_EXPOSE_PORT=3306
REDIS_EXPOSE_PORT=6379
```

## Usage

- 部署环境

```bash
bash bin/make.sh -h
```

## Mysql Standalone container script 

> bin/mysql.sh

- prepare mysql env file : workspace/.env.mysql8 

```bash
# root passwor
MYSQL_ROOT_PASSWORD=root
MYSQL_USER=admin
MYSQL_PASSWORD=xxx
TZ=Asia/Shanghai
```

### Command

```bash
bash bin/mysql.sh -h

```

