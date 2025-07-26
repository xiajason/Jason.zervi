# Lyanna Blog System Makefile

# 变量定义
APP_NAME = lyanna
MAIN_FILE = main.go
BUILD_DIR = build
BACKUP_DIR = backups
LOG_DIR = logs

# 数据库配置
DB_HOST = 127.0.0.1
DB_PORT = 3306
DB_USER = root
DB_PASSWORD = 
DB_NAME = lyanna

# Go 构建参数
LDFLAGS = -ldflags "-X main.Version=$(shell git describe --tags --always --dirty) -X main.BuildTime=$(shell date -u '+%Y-%m-%d_%H:%M:%S')"

# 默认目标
.PHONY: help
help: ## 显示帮助信息
	@echo "Lyanna Blog System - 可用命令:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# 开发相关命令
.PHONY: dev
dev: ## 启动开发模式
	@echo "启动开发模式..."
	@go run $(MAIN_FILE)

.PHONY: build
build: ## 构建应用
	@echo "构建应用..."
	@mkdir -p $(BUILD_DIR)
	@go build $(LDFLAGS) -o $(BUILD_DIR)/$(APP_NAME) $(MAIN_FILE)
	@echo "构建完成: $(BUILD_DIR)/$(APP_NAME)"

.PHONY: clean
clean: ## 清理构建文件
	@echo "清理构建文件..."
	@rm -rf $(BUILD_DIR)
	@go clean

.PHONY: test
test: ## 运行测试
	@echo "运行测试..."
	@go test -v ./...

.PHONY: test-coverage
test-coverage: ## 运行测试并生成覆盖率报告
	@echo "运行测试并生成覆盖率报告..."
	@go test -v -coverprofile=coverage.out ./...
	@go tool cover -html=coverage.out -o coverage.html
	@echo "覆盖率报告已生成: coverage.html"

# 数据库相关命令
.PHONY: db-init
db-init: ## 初始化数据库
	@echo "初始化数据库..."
	@chmod +x scripts/init_database.sh
	@DB_HOST=$(DB_HOST) DB_PORT=$(DB_PORT) DB_USER=$(DB_USER) DB_PASSWORD=$(DB_PASSWORD) DB_NAME=$(DB_NAME) ./scripts/init_database.sh

.PHONY: db-test
db-test: ## 测试数据库连接
	@echo "测试数据库连接..."
	@go run cmd/db/main.go -host=$(DB_HOST) -port=$(DB_PORT) -user=$(DB_USER) -password=$(DB_PASSWORD) -database=$(DB_NAME) -test

.PHONY: db-health
db-health: ## 检查数据库健康状态
	@echo "检查数据库健康状态..."
	@go run cmd/db/main.go -host=$(DB_HOST) -port=$(DB_PORT) -user=$(DB_USER) -password=$(DB_PASSWORD) -database=$(DB_NAME) -health

.PHONY: db-backup
db-backup: ## 备份数据库
	@echo "备份数据库..."
	@mkdir -p $(BACKUP_DIR)
	@go run cmd/db/main.go -host=$(DB_HOST) -port=$(DB_PORT) -user=$(DB_USER) -password=$(DB_PASSWORD) -database=$(DB_NAME) -backup -timestamp

.PHONY: db-restore
db-restore: ## 恢复数据库 (使用: make db-restore BACKUP_FILE=path/to/backup.sql)
	@echo "恢复数据库..."
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "错误: 请指定备份文件路径"; \
		echo "用法: make db-restore BACKUP_FILE=path/to/backup.sql"; \
		exit 1; \
	fi
	@go run cmd/db/main.go -host=$(DB_HOST) -port=$(DB_PORT) -user=$(DB_USER) -password=$(DB_PASSWORD) -database=$(DB_NAME) -restore=$(BACKUP_FILE)

.PHONY: db-optimize
db-optimize: ## 优化数据库表
	@echo "优化数据库表..."
	@go run cmd/db/main.go -host=$(DB_HOST) -port=$(DB_PORT) -user=$(DB_USER) -password=$(DB_PASSWORD) -database=$(DB_NAME) -optimize

.PHONY: db-clean-backups
db-clean-backups: ## 清理旧备份文件 (使用: make db-clean-backups DAYS=7)
	@echo "清理旧备份文件..."
	@DAYS=$${DAYS:-7}; \
	go run cmd/db/main.go -host=$(DB_HOST) -port=$(DB_PORT) -user=$(DB_USER) -password=$(DB_PASSWORD) -database=$(DB_NAME) -clean=$$DAYS

# 前端相关命令
.PHONY: frontend-install
frontend-install: ## 安装前端依赖
	@echo "安装前端依赖..."
	@npm install

.PHONY: frontend-dev
frontend-dev: ## 启动前端开发模式
	@echo "启动前端开发模式..."
	@npm run start

.PHONY: frontend-build
frontend-build: ## 构建前端资源
	@echo "构建前端资源..."
	@npm run build

# 部署相关命令
.PHONY: deploy-prepare
deploy-prepare: ## 准备部署
	@echo "准备部署..."
	@make clean
	@make build
	@make frontend-build
	@make db-backup

.PHONY: deploy
deploy: deploy-prepare ## 部署应用
	@echo "部署应用..."
	@echo "请将 $(BUILD_DIR)/$(APP_NAME) 复制到目标服务器"
	@echo "并确保配置文件 config/config.yaml 已正确设置"

# 日志相关命令
.PHONY: logs
logs: ## 查看应用日志
	@echo "查看应用日志..."
	@tail -f $(LOG_DIR)/lyanna.log

.PHONY: logs-clear
logs-clear: ## 清理日志文件
	@echo "清理日志文件..."
	@rm -f $(LOG_DIR)/*.log

# 系统相关命令
.PHONY: install-deps
install-deps: ## 安装系统依赖
	@echo "安装系统依赖..."
	@echo "请确保已安装以下软件:"
	@echo "  - Go 1.12+"
	@echo "  - MySQL 5.7+"
	@echo "  - Redis 3.0+"
	@echo "  - Node.js 12+"
	@echo "  - npm"

.PHONY: setup
setup: install-deps frontend-install ## 完整设置
	@echo "完整设置..."
	@make db-init
	@echo "设置完成！"
	@echo "运行 'make dev' 启动应用"

.PHONY: docker-build
docker-build: ## 构建 Docker 镜像
	@echo "构建 Docker 镜像..."
	@docker build -t $(APP_NAME):latest .

.PHONY: docker-run
docker-run: ## 运行 Docker 容器
	@echo "运行 Docker 容器..."
	@docker run -p 9080:9080 --name $(APP_NAME) $(APP_NAME):latest

.PHONY: docker-stop
docker-stop: ## 停止 Docker 容器
	@echo "停止 Docker 容器..."
	@docker stop $(APP_NAME) || true
	@docker rm $(APP_NAME) || true

# 开发工具命令
.PHONY: fmt
fmt: ## 格式化代码
	@echo "格式化代码..."
	@go fmt ./...

.PHONY: vet
vet: ## 代码静态分析
	@echo "代码静态分析..."
	@go vet ./...

.PHONY: lint
lint: ## 代码检查
	@echo "代码检查..."
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run; \
	else \
		echo "golangci-lint 未安装，跳过代码检查"; \
	fi

.PHONY: generate
generate: ## 生成代码
	@echo "生成代码..."
	@go generate ./...

# 监控和调试命令
.PHONY: profile
profile: ## 性能分析
	@echo "性能分析..."
	@go tool pprof http://localhost:9080/debug/pprof/profile

.PHONY: trace
trace: ## 性能追踪
	@echo "性能追踪..."
	@go tool trace trace.out

# 文档相关命令
.PHONY: docs
docs: ## 生成文档
	@echo "生成文档..."
	@if command -v godoc >/dev/null 2>&1; then \
		godoc -http=:6060; \
	else \
		echo "godoc 未安装，无法生成文档"; \
	fi

.PHONY: swagger
swagger: ## 生成 Swagger 文档
	@echo "生成 Swagger 文档..."
	@if command -v swag >/dev/null 2>&1; then \
		swag init; \
	else \
		echo "swag 未安装，无法生成 Swagger 文档"; \
	fi

# 清理所有
.PHONY: clean-all
clean-all: clean logs-clear ## 清理所有文件
	@echo "清理所有文件..."
	@rm -rf $(BACKUP_DIR)
	@rm -f coverage.out coverage.html
	@rm -f trace.out

# 显示版本信息
.PHONY: version
version: ## 显示版本信息
	@echo "Lyanna Blog System"
	@echo "版本: $(shell git describe --tags --always --dirty 2>/dev/null || echo 'unknown')"
	@echo "构建时间: $(shell date -u '+%Y-%m-%d %H:%M:%S UTC')"
	@echo "Go 版本: $(shell go version)" 