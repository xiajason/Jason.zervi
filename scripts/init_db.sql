-- Lyanna Blog System Database Initialization Script
-- 创建数据库
CREATE DATABASE IF NOT EXISTS lyanna CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE lyanna;

-- 删除已存在的表（如果存在）
DROP TABLE IF EXISTS react_items;
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS post_tags;
DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS github_users;
DROP TABLE IF EXISTS users;

-- 创建用户表
CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    intro TEXT,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    github_url VARCHAR(255),
    active BOOLEAN DEFAULT TRUE
);

-- 创建GitHub用户表
CREATE TABLE github_users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    g_id BIGINT NOT NULL UNIQUE,
    email VARCHAR(255),
    user_name VARCHAR(255),
    picture VARCHAR(500),
    nick_name VARCHAR(255),
    url VARCHAR(500)
);

-- 创建标签表
CREATE TABLE tags (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    name VARCHAR(255) NOT NULL UNIQUE
);

-- 创建文章表
CREATE TABLE posts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    title VARCHAR(255) NOT NULL,
    author_id INT NOT NULL,
    slug VARCHAR(255) UNIQUE,
    summary TEXT,
    content LONGTEXT,
    can_comment BOOLEAN DEFAULT TRUE,
    published BOOLEAN DEFAULT FALSE,
    INDEX idx_author_id (author_id),
    INDEX idx_published (published),
    INDEX idx_slug (slug),
    INDEX idx_created_at (created_at)
);

-- 创建文章标签关联表
CREATE TABLE post_tags (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    post_id BIGINT NOT NULL,
    tag_id BIGINT NOT NULL,
    UNIQUE KEY unique_post_tag (post_id, tag_id),
    INDEX idx_post_id (post_id),
    INDEX idx_tag_id (tag_id)
);

-- 创建评论表
CREATE TABLE comments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    github_id BIGINT NOT NULL,
    post_id BIGINT NOT NULL,
    content LONGTEXT,
    ref_id BIGINT DEFAULT 0,
    INDEX idx_post_id (post_id),
    INDEX idx_github_id (github_id)
);

-- 创建反应表
CREATE TABLE react_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    post_id BIGINT NOT NULL,
    reaction_type BIGINT NOT NULL,
    INDEX idx_post_id (post_id)
);

-- 插入初始数据

-- 插入默认管理员用户
INSERT INTO users (name, email, password, intro, active) VALUES 
('admin', 'admin@lyanna.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '系统管理员', TRUE);

-- 插入示例标签
INSERT INTO tags (name) VALUES 
('技术'),
('生活'),
('随笔'),
('Go语言'),
('Web开发'),
('数据库'),
('前端'),
('后端');

-- 插入示例文章
INSERT INTO posts (title, author_id, slug, summary, content, can_comment, published) VALUES 
('欢迎使用 Lyanna 博客系统', 1, 'welcome-to-lyanna', '这是一个基于 Go 语言和 Gin 框架开发的现代化博客系统', 
'# 欢迎使用 Lyanna 博客系统

Lyanna 是一个功能完整的现代化博客系统，基于 Go 语言的 Gin 框架开发。

## 主要特性

- **文章管理**：支持文章的创建、编辑、发布、预览和删除
- **标签系统**：为文章添加标签，支持按标签分类浏览和搜索
- **用户系统**：支持本地用户注册和 GitHub OAuth2 第三方登录
- **评论功能**：用户可对文章发表评论，支持 Markdown 格式
- **RSS 订阅**：自动生成 RSS 订阅源，支持主流 RSS 阅读器

## 技术栈

### 后端技术
- **Web 框架**：Gin v1.4.0
- **ORM 框架**：GORM v1.9.10
- **数据库**：MySQL
- **缓存**：Redis
- **认证**：GitHub OAuth2

### 前端技术
- **UI 框架**：Bootstrap 5
- **构建工具**：Webpack 4
- **样式预处理**：SCSS

希望您喜欢这个博客系统！', TRUE, TRUE),

('Go 语言开发最佳实践', 1, 'go-development-best-practices', '分享一些 Go 语言开发中的最佳实践和常见陷阱', 
'# Go 语言开发最佳实践

Go 语言以其简洁、高效和并发特性而闻名。本文将分享一些 Go 开发中的最佳实践。

## 1. 错误处理

Go 语言中的错误处理是其设计哲学的重要组成部分：

```go
if err != nil {
    return fmt.Errorf("failed to process data: %w", err)
}
```

## 2. 接口设计

接口应该小而专注：

```go
type Reader interface {
    Read(p []byte) (n int, err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}
```

## 3. 并发编程

使用 goroutines 和 channels 进行并发编程：

```go
func worker(id int, jobs <-chan int, results chan<- int) {
    for j := range jobs {
        fmt.Printf("worker %d processing job %d\n", id, j)
        time.Sleep(time.Second)
        results <- j * 2
    }
}
```

## 4. 性能优化

- 使用 `sync.Pool` 减少内存分配
- 避免不必要的内存拷贝
- 合理使用指针和值类型

这些实践将帮助您编写更好的 Go 代码。', TRUE, TRUE),

('Web 开发中的数据库设计', 1, 'database-design-in-web-development', '探讨 Web 开发中数据库设计的重要性和最佳实践', 
'# Web 开发中的数据库设计

数据库设计是 Web 应用开发中的关键环节，良好的设计可以显著提升应用性能和可维护性。

## 1. 规范化设计

数据库规范化是减少数据冗余和确保数据一致性的重要手段：

### 第一范式 (1NF)
- 每个字段都是原子性的
- 没有重复的列

### 第二范式 (2NF)
- 满足 1NF
- 非主键字段完全依赖于主键

### 第三范式 (3NF)
- 满足 2NF
- 非主键字段不依赖于其他非主键字段

## 2. 索引策略

合理的索引设计可以显著提升查询性能：

```sql
-- 为经常查询的字段创建索引
CREATE INDEX idx_user_email ON users(email);
CREATE INDEX idx_post_published ON posts(published);

-- 复合索引
CREATE INDEX idx_post_author_published ON posts(author_id, published);
```

## 3. 连接优化

- 使用 INNER JOIN 而不是多个查询
- 避免 SELECT *
- 合理使用子查询

## 4. 缓存策略

- 使用 Redis 缓存热点数据
- 实现缓存失效策略
- 考虑缓存穿透和雪崩问题

良好的数据库设计是高性能 Web 应用的基础。', TRUE, TRUE);

-- 为文章添加标签
INSERT INTO post_tags (post_id, tag_id) VALUES 
(1, 1), (1, 4), (1, 5),  -- 欢迎文章：技术、Go语言、Web开发
(2, 1), (2, 4),          -- Go实践文章：技术、Go语言
(3, 1), (3, 5), (3, 6);  -- 数据库文章：技术、Web开发、数据库

-- 显示创建结果
SELECT "Database initialization completed successfully!" as message;
SELECT COUNT(*) as user_count FROM users;
SELECT COUNT(*) as tag_count FROM tags;
SELECT COUNT(*) as post_count FROM posts; 