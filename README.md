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

### Mysql DB

```sql
/** DB */
GRANT ALL privileges on *.* to 'admin'@'%';


create database if not exists `loto-db`;

CREATE USER 'lotolab'@'%' IDENTIFIED BY 'loto123';

GRANT select,insert,update,delete,create,index on `loto-db`.* to `lotolab`;

flush privileges;
```


