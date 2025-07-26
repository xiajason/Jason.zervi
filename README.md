# Lyanna - 基于 Gin 的现代化博客系统

## 项目简介
Lyanna 是一个功能完整的现代化博客系统，基于 Go 语言的 Gin 框架开发。系统支持 GitHub OAuth2 登录、文章管理、标签分类、评论系统、RSS 订阅等核心功能，提供美观的前端界面和完善的后台管理功能。

## 功能特性

### 核心功能
- **文章管理**：支持文章的创建、编辑、发布、预览和删除
- **标签系统**：为文章添加标签，支持按标签分类浏览和搜索
- **用户系统**：支持本地用户注册和 GitHub OAuth2 第三方登录
- **评论功能**：用户可对文章发表评论，支持 Markdown 格式
- **权限控制**：区分普通用户和管理员，支持细粒度权限管理

### 高级功能
- **RSS 订阅**：自动生成 RSS 订阅源，支持主流 RSS 阅读器
- **搜索功能**：支持文章标题和内容的全文搜索
- **归档系统**：按年份归档文章，方便历史内容浏览
- **静态资源**：提供完整的静态文件服务（CSS、JS、图片等）
- **响应式设计**：支持移动端和桌面端的自适应布局

### 管理功能
- **后台管理**：完整的文章和用户管理界面
- **实时预览**：文章编辑时支持实时预览功能
- **批量操作**：支持文章的批量发布和管理
- **数据统计**：提供基础的数据统计功能

## 技术栈

### 后端技术
- **Web 框架**：Gin v1.4.0
- **ORM 框架**：GORM v1.9.10
- **数据库**：MySQL
- **缓存**：Redis (使用 redigo 客户端)
- **认证**：GitHub OAuth2
- **日志**：Zap + Lumberjack (支持日志轮转)
- **Markdown 渲染**：Blackfriday + Bluemonday (安全渲染)
- **会话管理**：gin-contrib/sessions

### 前端技术
- **UI 框架**：Bootstrap 5
- **构建工具**：Webpack 4
- **样式预处理**：SCSS
- **图标库**：Bootstrap Icons, Boxicons
- **动画效果**：AOS (Animate On Scroll)
- **代码高亮**：Highlight.js
- **编辑器**：CodeMirror (管理后台)

### 开发工具
- **包管理**：Go Modules
- **配置管理**：YAML
- **UUID 生成**：snluu/uuid
- **RSS 生成**：gorilla/feeds

## 快速开始

### 环境要求
- Go 1.12+
- MySQL 5.7+
- Redis 3.0+
- Node.js 12+ (用于前端构建)

### 1. 克隆项目
```bash
git clone https://github.com/your-repo/lyanna.git
cd lyanna
```

### 2. 安装依赖
```bash
# 安装 Go 依赖
go mod download

# 安装前端依赖
npm install
```

### 3. 配置环境
复制配置文件并修改：
```bash
cp config/config.yaml config/config.yaml.example
```

编辑 `config/config.yaml`：
```yaml
runmode: debug
general:
    addr: :9080
    dsn: "username:password@(127.0.0.1:3306)/lyanna?charset=utf8&parseTime=True&loc=Local"
    sessionsecret: "your_session_secret"
    logoutenabled: true
    perpage: 10

github:
    clientid: "your_github_client_id"
    clientsecret: "your_github_client_secret"
    authurl: "https://github.com/login/oauth/authorize?client_id=%s&scope=user:email&state=%s"
    redirecturl: "http://127.0.0.1:9080/oauth2"
    tokenurl: "https://github.com/login/oauth/access_token"

log:
    logpath: "./logs/lyanna.log"
    maxsize: 20
    maxage: 7
    compress: true
    maxbackups: 10
```

### 4. 数据库初始化
```bash
# 创建数据库
mysql -u root -p -e "CREATE DATABASE lyanna CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 运行应用（会自动创建表结构）
go run main.go
```

### 5. 构建前端资源
```bash
# 开发模式（监听文件变化）
npm run start

# 生产模式
npm run build
```

### 6. 启动服务
```bash
go run main.go
```

### 7. 访问应用
- 前台：http://localhost:9080
- 后台：http://localhost:9080/admin
- RSS 订阅：http://localhost:9080/rss

## 项目结构
```
lyanna/
├── config/              # 配置文件
│   └── config.yaml      # 主配置文件
├── controllers/         # 控制器层
│   ├── api.go          # API 接口
│   ├── auth.go         # 认证相关
│   ├── blog.go         # 博客功能
│   ├── comment.go      # 评论功能
│   ├── index.go        # 首页控制器
│   ├── post.go         # 文章管理
│   ├── rss.go          # RSS 生成
│   ├── tag.go          # 标签管理
│   └── user.go         # 用户管理
├── models/             # 数据模型层
│   ├── base.go         # 基础模型
│   ├── comment.go      # 评论模型
│   ├── post.go         # 文章模型
│   ├── postTag.go      # 文章标签关联
│   ├── react.go        # 反应模型
│   ├── redisLogc.go    # Redis 逻辑
│   ├── systemInit.go   # 系统初始化
│   ├── tag.go          # 标签模型
│   └── user.go         # 用户模型
├── static/             # 静态资源
│   ├── css/            # 样式文件
│   ├── js/             # JavaScript 文件
│   └── img/            # 图片资源
├── src/                # 前端源码
│   ├── admin/          # 管理后台 JS
│   ├── blog/           # 博客前端 JS
│   ├── scss/           # SCSS 样式文件
│   └── vendor/         # 第三方库
├── utils/              # 工具函数
│   ├── pagination.go   # 分页工具
│   ├── template.go     # 模板工具
│   └── utils.go        # 通用工具
├── views/              # 模板文件
│   ├── admin/          # 管理后台模板
│   ├── front/          # 前台模板
│   └── errors/         # 错误页面模板
├── logs/               # 日志文件
├── go.mod              # Go 模块定义
├── go.sum              # 依赖校验
├── package.json        # Node.js 依赖
├── webpack.config.js   # Webpack 配置
└── main.go             # 应用入口
```

## 配置说明

### GitHub OAuth2 配置
1. 在 GitHub 创建 OAuth App
2. 设置回调地址为：`http://your-domain:9080/oauth2`
3. 将 Client ID 和 Client Secret 填入配置文件

### 数据库配置
- 支持 MySQL 5.7+
- 字符集：utf8mb4
- 时区：Local

### Redis 配置
- 用于缓存文章内容
- 支持连接池配置
- 可选的密码认证

## 开发指南

### 添加新功能
1. 在 `models/` 中定义数据模型
2. 在 `controllers/` 中实现业务逻辑
3. 在 `views/` 中创建模板文件
4. 在 `main.go` 中注册路由

### 自定义主题
1. 修改 `src/scss/` 中的样式文件
2. 运行 `npm run start` 编译样式
3. 刷新页面查看效果

### 部署说明
1. 构建前端资源：`npm run build`
2. 编译 Go 程序：`go build -o lyanna main.go`
3. 配置反向代理（推荐使用 Nginx）
4. 设置环境变量或配置文件

## 贡献指南
欢迎提交 Issue 或 Pull Request！

### 开发流程
1. Fork 项目
2. 创建功能分支：`git checkout -b feature/your-feature`
3. 提交更改：`git commit -am 'Add some feature'`
4. 推送分支：`git push origin feature/your-feature`
5. 提交 Pull Request

### 代码规范
- 遵循 Go 官方代码规范
- 使用有意义的变量和函数名
- 添加必要的注释
- 确保代码通过测试

## 许可证
MIT License

## 更新日志
- v1.0.0: 初始版本发布
  - 基础博客功能
  - GitHub OAuth2 登录
  - 文章和标签管理
  - 评论系统
  - RSS 订阅
  - 响应式设计

## 联系方式
- 项目主页：https://github.com/your-repo/lyanna
- 问题反馈：https://github.com/your-repo/lyanna/issues
- 邮箱：your-email@example.com