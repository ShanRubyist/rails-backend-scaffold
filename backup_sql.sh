#!/bin/bash

# 数据库配置
DB_USER="root"
BACKUP_DIR="/opt/backup"
DAYS_TO_KEEP=7  # 保留备份的天数

# 排除的数据库列表（系统数据库）
EXCLUDE_DBS="template0 template1 postgres"

# 创建备份目录（如果不存在）
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
fi

# 生成时间戳
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 获取所有数据库列表
echo "获取数据库列表..."
DATABASE_LIST=$(psql -U $DB_USER -l -t | cut -d'|' -f1 | sed -e 's/ //g' -e '/^$/d')

# 遍历每个数据库进行备份
for DB_NAME in $DATABASE_LIST; do
    # 跳过被排除的数据库
    if [[ $EXCLUDE_DBS =~ $DB_NAME ]]; then
        echo "跳过系统数据库: $DB_NAME"
        continue
    fi

    echo "开始备份数据库: $DB_NAME"
    BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_backup_$TIMESTAMP.sql"
    
    # 执行数据库备份
    pg_dump -U $DB_USER $DB_NAME > $BACKUP_FILE

    # 检查备份是否成功
    if [ $? -eq 0 ]; then
        echo "数据库 $DB_NAME 备份成功: $BACKUP_FILE"
        # 压缩备份文件
        gzip $BACKUP_FILE
        echo "备份文件已压缩: $BACKUP_FILE.gz"
    else
        echo "数据库 $DB_NAME 备份失败"
        exit 1
    fi
done

# 删除旧的备份文件
echo "清理旧备份文件..."
find $BACKUP_DIR -name "*_backup_*.sql.gz" -mtime +$DAYS_TO_KEEP -delete

echo "所有数据库备份过程完成"
