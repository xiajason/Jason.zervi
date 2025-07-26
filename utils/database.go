package utils

import (
	"database/sql"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

// DatabaseManager 数据库管理器
type DatabaseManager struct {
	Host     string
	Port     string
	User     string
	Password string
	Database string
}

// NewDatabaseManager 创建数据库管理器
func NewDatabaseManager() *DatabaseManager {
	return &DatabaseManager{
		Host:     "127.0.0.1",
		Port:     "3306",
		User:     "root",
		Password: "",
		Database: "lyanna",
	}
}

// TestConnection 测试数据库连接
func (dm *DatabaseManager) TestConnection() error {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		dm.User, dm.Password, dm.Host, dm.Port, dm.Database)

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		return fmt.Errorf("failed to open database: %v", err)
	}
	defer db.Close()

	// 测试连接
	err = db.Ping()
	if err != nil {
		return fmt.Errorf("failed to ping database: %v", err)
	}

	return nil
}

// GetTableInfo 获取表信息
func (dm *DatabaseManager) GetTableInfo() (map[string]int64, error) {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		dm.User, dm.Password, dm.Host, dm.Port, dm.Database)

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %v", err)
	}
	defer db.Close()

	tables := []string{"users", "github_users", "tags", "posts", "post_tags", "comments", "react_items"}
	tableInfo := make(map[string]int64)

	for _, table := range tables {
		var count int64
		query := fmt.Sprintf("SELECT COUNT(*) FROM %s", table)
		err := db.QueryRow(query).Scan(&count)
		if err != nil {
			return nil, fmt.Errorf("failed to get count for table %s: %v", table, err)
		}
		tableInfo[table] = count
	}

	return tableInfo, nil
}

// BackupDatabase 备份数据库
func (dm *DatabaseManager) BackupDatabase(backupPath string) error {
	// 确保备份目录存在
	backupDir := filepath.Dir(backupPath)
	if err := os.MkdirAll(backupDir, 0755); err != nil {
		return fmt.Errorf("failed to create backup directory: %v", err)
	}

	// 构建mysqldump命令
	cmd := exec.Command("mysqldump",
		"-h", dm.Host,
		"-P", dm.Port,
		"-u", dm.User,
		"--single-transaction",
		"--routines",
		"--triggers",
		dm.Database)

	if dm.Password != "" {
		cmd.Args = append(cmd.Args, "-p"+dm.Password)
	}

	// 创建输出文件
	outputFile, err := os.Create(backupPath)
	if err != nil {
		return fmt.Errorf("failed to create backup file: %v", err)
	}
	defer outputFile.Close()

	cmd.Stdout = outputFile

	// 执行备份
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to backup database: %v", err)
	}

	return nil
}

// RestoreDatabase 恢复数据库
func (dm *DatabaseManager) RestoreDatabase(backupPath string) error {
	// 检查备份文件是否存在
	if _, err := os.Stat(backupPath); os.IsNotExist(err) {
		return fmt.Errorf("backup file does not exist: %s", backupPath)
	}

	// 构建mysql命令
	cmd := exec.Command("mysql",
		"-h", dm.Host,
		"-P", dm.Port,
		"-u", dm.User,
		dm.Database)

	if dm.Password != "" {
		cmd.Args = append(cmd.Args, "-p"+dm.Password)
	}

	// 打开备份文件
	backupFile, err := os.Open(backupPath)
	if err != nil {
		return fmt.Errorf("failed to open backup file: %v", err)
	}
	defer backupFile.Close()

	cmd.Stdin = backupFile

	// 执行恢复
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to restore database: %v", err)
	}

	return nil
}

// CreateBackupWithTimestamp 创建带时间戳的备份
func (dm *DatabaseManager) CreateBackupWithTimestamp() (string, error) {
	timestamp := time.Now().Format("2006-01-02_15-04-05")
	backupPath := fmt.Sprintf("./backups/lyanna_backup_%s.sql", timestamp)

	err := dm.BackupDatabase(backupPath)
	if err != nil {
		return "", err
	}

	return backupPath, nil
}

// CleanOldBackups 清理旧备份文件
func (dm *DatabaseManager) CleanOldBackups(keepDays int) error {
	backupDir := "./backups"

	// 检查备份目录是否存在
	if _, err := os.Stat(backupDir); os.IsNotExist(err) {
		return nil // 目录不存在，无需清理
	}

	// 获取所有备份文件
	files, err := filepath.Glob(filepath.Join(backupDir, "lyanna_backup_*.sql"))
	if err != nil {
		return fmt.Errorf("failed to list backup files: %v", err)
	}

	cutoffTime := time.Now().AddDate(0, 0, -keepDays)

	for _, file := range files {
		fileInfo, err := os.Stat(file)
		if err != nil {
			continue
		}

		if fileInfo.ModTime().Before(cutoffTime) {
			if err := os.Remove(file); err != nil {
				return fmt.Errorf("failed to remove old backup file %s: %v", file, err)
			}
		}
	}

	return nil
}

// GetDatabaseSize 获取数据库大小
func (dm *DatabaseManager) GetDatabaseSize() (int64, error) {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		dm.User, dm.Password, dm.Host, dm.Port, dm.Database)

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		return 0, fmt.Errorf("failed to open database: %v", err)
	}
	defer db.Close()

	var size int64
	query := `
		SELECT 
			ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'DB Size in MB'
		FROM information_schema.tables 
		WHERE table_schema = ?
	`

	err = db.QueryRow(query, dm.Database).Scan(&size)
	if err != nil {
		return 0, fmt.Errorf("failed to get database size: %v", err)
	}

	return size, nil
}

// OptimizeTables 优化数据库表
func (dm *DatabaseManager) OptimizeTables() error {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		dm.User, dm.Password, dm.Host, dm.Port, dm.Database)

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		return fmt.Errorf("failed to open database: %v", err)
	}
	defer db.Close()

	tables := []string{"users", "github_users", "tags", "posts", "post_tags", "comments", "react_items"}

	for _, table := range tables {
		query := fmt.Sprintf("OPTIMIZE TABLE %s", table)
		_, err := db.Exec(query)
		if err != nil {
			return fmt.Errorf("failed to optimize table %s: %v", table, err)
		}
	}

	return nil
}

// CheckDatabaseHealth 检查数据库健康状态
func (dm *DatabaseManager) CheckDatabaseHealth() (map[string]interface{}, error) {
	health := make(map[string]interface{})

	// 测试连接
	if err := dm.TestConnection(); err != nil {
		health["connection"] = map[string]interface{}{
			"status":  "error",
			"message": err.Error(),
		}
		return health, nil
	}

	health["connection"] = map[string]interface{}{
		"status":  "ok",
		"message": "Database connection successful",
	}

	// 获取表信息
	tableInfo, err := dm.GetTableInfo()
	if err != nil {
		health["tables"] = map[string]interface{}{
			"status":  "error",
			"message": err.Error(),
		}
	} else {
		health["tables"] = map[string]interface{}{
			"status": "ok",
			"data":   tableInfo,
		}
	}

	// 获取数据库大小
	size, err := dm.GetDatabaseSize()
	if err != nil {
		health["size"] = map[string]interface{}{
			"status":  "error",
			"message": err.Error(),
		}
	} else {
		health["size"] = map[string]interface{}{
			"status":  "ok",
			"size_mb": size,
		}
	}

	return health, nil
}
