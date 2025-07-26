#!/bin/bash

# Lyanna Blog System Database Initialization Script
# 数据库初始化脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Lyanna Database Initialization${NC}"
    echo -e "${BLUE}================================${NC}"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed. Please install it first."
        exit 1
    fi
}

# 检查MySQL连接
check_mysql_connection() {
    print_message "Checking MySQL connection..."
    
    if ! mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -P"$DB_PORT" -e "SELECT 1;" &> /dev/null; then
        print_error "Cannot connect to MySQL. Please check your database configuration."
        exit 1
    fi
    
    print_message "MySQL connection successful!"
}

# 创建数据库
create_database() {
    print_message "Creating database '$DB_NAME'..."
    
    mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -P"$DB_PORT" -e "
        CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` 
        CHARACTER SET utf8mb4 
        COLLATE utf8mb4_unicode_ci;
    "
    
    print_message "Database '$DB_NAME' created successfully!"
}

# 运行初始化SQL
run_init_sql() {
    print_message "Running initialization SQL..."
    
    if [ -f "scripts/init_db.sql" ]; then
        mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -P"$DB_PORT" "$DB_NAME" < scripts/init_db.sql
        print_message "Database initialization completed!"
    else
        print_error "init_db.sql file not found!"
        exit 1
    fi
}

# 验证初始化结果
verify_initialization() {
    print_message "Verifying initialization results..."
    
    local user_count=$(mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -P"$DB_PORT" "$DB_NAME" -s -N -e "SELECT COUNT(*) FROM users;")
    local tag_count=$(mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -P"$DB_PORT" "$DB_NAME" -s -N -e "SELECT COUNT(*) FROM tags;")
    local post_count=$(mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -P"$DB_PORT" "$DB_NAME" -s -N -e "SELECT COUNT(*) FROM posts;")
    
    echo -e "${GREEN}✓ Users: $user_count${NC}"
    echo -e "${GREEN}✓ Tags: $tag_count${NC}"
    echo -e "${GREEN}✓ Posts: $post_count${NC}"
    
    print_message "Database initialization verification completed!"
}

# 显示配置信息
show_config() {
    print_message "Database Configuration:"
    echo "  Host: $DB_HOST"
    echo "  Port: $DB_PORT"
    echo "  Database: $DB_NAME"
    echo "  User: $DB_USER"
    echo ""
}

# 主函数
main() {
    print_header
    
    # 检查必要的命令
    check_command mysql
    
    # 设置默认值
    DB_HOST=${DB_HOST:-"127.0.0.1"}
    DB_PORT=${DB_PORT:-"3306"}
    DB_NAME=${DB_NAME:-"lyanna"}
    DB_USER=${DB_USER:-"root"}
    DB_PASSWORD=${DB_PASSWORD:-""}
    
    # 显示配置
    show_config
    
    # 检查连接
    check_mysql_connection
    
    # 创建数据库
    create_database
    
    # 运行初始化SQL
    run_init_sql
    
    # 验证结果
    verify_initialization
    
    print_message "Database initialization completed successfully!"
    echo ""
    print_message "Next steps:"
    echo "  1. Update config/config.yaml with your database credentials"
    echo "  2. Run 'go run main.go' to start the application"
    echo "  3. Access the application at http://localhost:9080"
    echo ""
}

# 显示帮助信息
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --host HOST       MySQL host (default: 127.0.0.1)"
    echo "  -P, --port PORT       MySQL port (default: 3306)"
    echo "  -d, --database NAME   Database name (default: lyanna)"
    echo "  -u, --user USER       MySQL user (default: root)"
    echo "  -p, --password PASS   MySQL password"
    echo "  --help                Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD"
    echo ""
    echo "Examples:"
    echo "  $0 -u root -p mypassword"
    echo "  DB_PASSWORD=mypassword $0"
    echo ""
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--host)
            DB_HOST="$2"
            shift 2
            ;;
        -P|--port)
            DB_PORT="$2"
            shift 2
            ;;
        -d|--database)
            DB_NAME="$2"
            shift 2
            ;;
        -u|--user)
            DB_USER="$2"
            shift 2
            ;;
        -p|--password)
            DB_PASSWORD="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# 运行主函数
main 