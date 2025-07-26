# 数据库配置和初始化指南

## 概述

Lyanna 博客系统使用 MySQL 作为主数据库，Redis 作为缓存数据库。本文档将指导您完成数据库的配置和初始化。

## 系统要求

### MySQL
- **版本**: 5.7 或更高版本
- **字符集**: utf8mb4
- **排序规则**: utf8mb4_unicode_ci
- **存储引擎**: InnoDB

### Redis
- **版本**: 3.0 或更高版本
- **功能**: 缓存、会话存储

## 数据库结构

### 主要数据表

1. **users** - 用户表
   - 存储本地用户信息
   - 支持用户名、邮箱、密码等字段

2. **github_users** - GitHub 用户表
   - 存储通过 GitHub OAuth2 登录的用户信息
   - 包含 GitHub ID、用户名、头像等

3. **posts** - 文章表
   - 存储博客文章内容
   - 支持标题、内容、摘要、发布状态等

4. **tags** - 标签表
   - 存储文章标签
   - 支持标签名称和统计信息

5. **post_tags** - 文章标签关联表
   - 多对多关系表
   - 关联文章和标签

6. **comments** - 评论表
   - 存储文章评论
   - 支持 GitHub 用户评论

7. **react_items** - 反应表
   - 存储用户对文章的反应
   - 支持点赞等操作

## 快速开始

### 1. 安装数据库服务

#### MySQL 安装

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install mysql-server
sudo mysql_secure_installation
```

**CentOS/RHEL:**
```bash
sudo yum install mysql-server
sudo systemctl start mysqld
sudo mysql_secure_installation
```

**macOS:**
```bash
brew install mysql
brew services start mysql
```

#### Redis 安装

**Ubuntu/Debian:**
```bash
sudo apt install redis-server
sudo systemctl start redis-server
```

**CentOS/RHEL:**
```bash
sudo yum install redis
sudo systemctl start redis
```

**macOS:**
```bash
brew install redis
brew services start redis
```

### 2. 创建数据库

```sql
CREATE DATABASE lyanna CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 3. 配置应用

1. 复制配置文件：
```bash
cp config/config.example.yaml config/config.yaml
```

2. 编辑配置文件：
```yaml
general:
    dsn: "username:password@(127.0.0.1:3306)/lyanna?charset=utf8mb4&parseTime=True&loc=Local"

redis:
    host: "127.0.0.1"
    port: 6379
    password: ""
```

### 4. 初始化数据库

#### 方法一：使用 Makefile（推荐）

```bash
# 测试数据库连接
make db-test

# 初始化数据库
make db-init

# 检查数据库健康状态
make db-health
```

#### 方法二：使用脚本

```bash
# 给脚本执行权限
chmod +x scripts/init_database.sh

# 运行初始化脚本
./scripts/init_database.sh
```

#### 方法三：使用命令行工具

```bash
# 测试连接
go run cmd/db/main.go -test

# 初始化数据库
go run cmd/db/main.go -init

# 检查健康状态
go run cmd/db/main.go -health
```

## 数据库管理

### 备份和恢复

#### 创建备份
```bash
# 使用 Makefile
make db-backup

# 使用命令行工具
go run cmd/db/main.go -backup -timestamp
```

#### 恢复备份
```bash
# 使用 Makefile
make db-restore BACKUP_FILE=./backups/lyanna_backup_2023-01-01_12-00-00.sql

# 使用命令行工具
go run cmd/db/main.go -restore ./backups/lyanna_backup_2023-01-01_12-00-00.sql
```

### 数据库优化

```bash
# 优化表
make db-optimize

# 清理旧备份
make db-clean-backups DAYS=7
```

### 监控和维护

```bash
# 检查数据库健康状态
make db-health

# 查看应用日志
make logs
```

## 生产环境配置

### 1. 数据库安全

- 创建专用数据库用户
- 设置强密码
- 限制数据库访问权限
- 启用 SSL 连接

```sql
-- 创建专用用户
CREATE USER 'lyanna'@'localhost' IDENTIFIED BY 'strong_password';
GRANT ALL PRIVILEGES ON lyanna.* TO 'lyanna'@'localhost';
FLUSH PRIVILEGES;
```

### 2. 性能优化

- 配置适当的连接池参数
- 设置合适的缓存策略
- 定期优化表结构
- 监控慢查询日志

### 3. 备份策略

- 设置自动备份计划
- 定期测试备份恢复
- 异地备份存储
- 监控备份状态

```bash
# 设置定时备份（每天凌晨2点）
0 2 * * * cd /path/to/lyanna && make db-backup
```

## 故障排除

### 常见问题

1. **连接被拒绝**
   - 检查 MySQL 服务是否启动
   - 验证主机地址和端口
   - 确认用户权限

2. **字符集错误**
   - 确保数据库使用 utf8mb4 字符集
   - 检查连接字符串中的字符集设置

3. **权限不足**
   - 确认数据库用户有足够权限
   - 检查数据库名称是否正确

4. **Redis 连接失败**
   - 检查 Redis 服务状态
   - 验证连接参数
   - 确认防火墙设置

### 调试命令

```bash
# 测试 MySQL 连接
mysql -u username -p -h hostname -P port

# 测试 Redis 连接
redis-cli ping

# 查看 MySQL 状态
mysql -u root -p -e "SHOW STATUS;"

# 查看 Redis 信息
redis-cli info
```

## 数据迁移

### 从其他系统迁移

1. 导出现有数据
2. 转换数据格式
3. 导入到 Lyanna 数据库
4. 验证数据完整性

### 版本升级

1. 备份当前数据库
2. 运行数据库迁移脚本
3. 验证数据完整性
4. 更新应用配置

## 监控和日志

### 数据库监控

- 连接数监控
- 查询性能监控
- 磁盘空间监控
- 慢查询分析

### 日志配置

```yaml
log:
    logpath: "./logs/lyanna.log"
    maxsize: 20
    maxage: 7
    compress: true
    maxbackups: 10
```

## 最佳实践

1. **定期备份**: 设置自动备份计划
2. **监控性能**: 定期检查数据库性能指标
3. **安全更新**: 及时更新数据库版本和安全补丁
4. **容量规划**: 根据数据增长趋势规划存储容量
5. **测试恢复**: 定期测试备份恢复流程

## 支持

如果遇到数据库相关问题，请：

1. 查看应用日志文件
2. 检查数据库错误日志
3. 参考本文档的故障排除部分
4. 提交 Issue 到项目仓库 