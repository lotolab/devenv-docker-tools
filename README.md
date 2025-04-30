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

flush privileges;
create database if not exists `loto-db`;

CREATE USER 'lotolab'@'%' IDENTIFIED BY 'loto123';

GRANT select,insert,update,delete,create,index on `loto-db`.* to `lotolab`;

flush privileges;
```

### Test Table

```sql
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for QRTZ_BLOB_TRIGGERS
-- ----------------------------
DROP TABLE IF EXISTS `QRTZ_BLOB_TRIGGERS`;
CREATE TABLE `QRTZ_BLOB_TRIGGERS`  (
  `sched_name` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '调度名称',
  `trigger_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'qrtz_triggers表trigger_name的外键',
  `trigger_group` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'qrtz_triggers表trigger_group的外键',
  `blob_data` blob NULL COMMENT '存放持久化Trigger对象',
  PRIMARY KEY (`sched_name`, `trigger_name`, `trigger_group`) USING BTREE,
  CONSTRAINT `qrtz_blob_triggers_ibfk_1` FOREIGN KEY (`sched_name`, `trigger_name`, `trigger_group`) REFERENCES `QRTZ_TRIGGERS` (`sched_name`, `trigger_name`, `trigger_group`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = 'Blob类型的触发器表' ROW_FORMAT = Dynamic;
```

