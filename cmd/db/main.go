package main

import (
	"flag"
	"fmt"
	"lyanna/utils"
	"os"
)

func main() {
	// 定义命令行参数
	var (
		host     = flag.String("host", "127.0.0.1", "MySQL host")
		port     = flag.String("port", "3306", "MySQL port")
		user     = flag.String("user", "root", "MySQL user")
		password = flag.String("password", "", "MySQL password")
		database = flag.String("database", "lyanna", "Database name")

		// 操作类型
		test     = flag.Bool("test", false, "Test database connection")
		init     = flag.Bool("init", false, "Initialize database")
		backup   = flag.Bool("backup", false, "Backup database")
		restore  = flag.String("restore", "", "Restore database from backup file")
		health   = flag.Bool("health", false, "Check database health")
		optimize = flag.Bool("optimize", false, "Optimize database tables")
		clean    = flag.Int("clean", 0, "Clean old backup files (keep N days)")

		// 备份相关
		backupPath    = flag.String("backup-path", "", "Backup file path")
		withTimestamp = flag.Bool("timestamp", false, "Create backup with timestamp")
	)

	flag.Parse()

	// 创建数据库管理器
	dm := &utils.DatabaseManager{
		Host:     *host,
		Port:     *port,
		User:     *user,
		Password: *password,
		Database: *database,
	}

	// 执行操作
	switch {
	case *test:
		testConnection(dm)
	case *init:
		initializeDatabase(dm)
	case *backup:
		backupDatabase(dm, *backupPath, *withTimestamp)
	case *restore != "":
		restoreDatabase(dm, *restore)
	case *health:
		checkHealth(dm)
	case *optimize:
		optimizeTables(dm)
	case *clean > 0:
		cleanBackups(dm, *clean)
	default:
		showHelp()
	}
}

func testConnection(dm *utils.DatabaseManager) {
	fmt.Println("Testing database connection...")

	err := dm.TestConnection()
	if err != nil {
		fmt.Printf("❌ Connection failed: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("✅ Database connection successful!")
}

func initializeDatabase(dm *utils.DatabaseManager) {
	fmt.Println("Initializing database...")

	// 测试连接
	err := dm.TestConnection()
	if err != nil {
		fmt.Printf("❌ Cannot connect to database: %v\n", err)
		os.Exit(1)
	}

	// 获取表信息
	tableInfo, err := dm.GetTableInfo()
	if err != nil {
		fmt.Printf("❌ Failed to get table info: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("✅ Database initialization completed!")
	fmt.Println("\nTable information:")
	for table, count := range tableInfo {
		fmt.Printf("  %s: %d records\n", table, count)
	}
}

func backupDatabase(dm *utils.DatabaseManager, backupPath string, withTimestamp bool) {
	var path string
	var err error

	if withTimestamp {
		path, err = dm.CreateBackupWithTimestamp()
		if err != nil {
			fmt.Printf("❌ Failed to create backup with timestamp: %v\n", err)
			os.Exit(1)
		}
	} else {
		if backupPath == "" {
			backupPath = fmt.Sprintf("./backups/lyanna_backup.sql")
		}
		err = dm.BackupDatabase(backupPath)
		if err != nil {
			fmt.Printf("❌ Failed to backup database: %v\n", err)
			os.Exit(1)
		}
		path = backupPath
	}

	fmt.Printf("✅ Database backup completed: %s\n", path)
}

func restoreDatabase(dm *utils.DatabaseManager, backupPath string) {
	fmt.Printf("Restoring database from: %s\n", backupPath)

	err := dm.RestoreDatabase(backupPath)
	if err != nil {
		fmt.Printf("❌ Failed to restore database: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("✅ Database restore completed!")
}

func checkHealth(dm *utils.DatabaseManager) {
	fmt.Println("Checking database health...")

	health, err := dm.CheckDatabaseHealth()
	if err != nil {
		fmt.Printf("❌ Failed to check health: %v\n", err)
		os.Exit(1)
	}

	// 输出健康状态
	fmt.Println("Database Health Report:")
	fmt.Println("=======================")

	for component, info := range health {
		infoMap := info.(map[string]interface{})
		status := infoMap["status"].(string)

		if status == "ok" {
			fmt.Printf("✅ %s: %s\n", component, infoMap["message"])

			// 显示详细信息
			if component == "tables" {
				if data, ok := infoMap["data"].(map[string]int64); ok {
					fmt.Println("   Table counts:")
					for table, count := range data {
						fmt.Printf("     %s: %d\n", table, count)
					}
				}
			} else if component == "size" {
				if size, ok := infoMap["size_mb"].(int64); ok {
					fmt.Printf("   Size: %d MB\n", size)
				}
			}
		} else {
			fmt.Printf("❌ %s: %s\n", component, infoMap["message"])
		}
	}
}

func optimizeTables(dm *utils.DatabaseManager) {
	fmt.Println("Optimizing database tables...")

	err := dm.OptimizeTables()
	if err != nil {
		fmt.Printf("❌ Failed to optimize tables: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("✅ Database tables optimized!")
}

func cleanBackups(dm *utils.DatabaseManager, keepDays int) {
	fmt.Printf("Cleaning backup files older than %d days...\n", keepDays)

	err := dm.CleanOldBackups(keepDays)
	if err != nil {
		fmt.Printf("❌ Failed to clean backups: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("✅ Old backup files cleaned!")
}

func showHelp() {
	fmt.Println("Lyanna Database Management Tool")
	fmt.Println("===============================")
	fmt.Println()
	fmt.Println("Usage:")
	fmt.Println("  db [options] [command]")
	fmt.Println()
	fmt.Println("Commands:")
	fmt.Println("  -test              Test database connection")
	fmt.Println("  -init              Initialize database")
	fmt.Println("  -backup            Backup database")
	fmt.Println("  -restore <file>    Restore database from backup")
	fmt.Println("  -health            Check database health")
	fmt.Println("  -optimize          Optimize database tables")
	fmt.Println("  -clean <days>      Clean old backup files")
	fmt.Println()
	fmt.Println("Options:")
	fmt.Println("  -host <host>       MySQL host (default: 127.0.0.1)")
	fmt.Println("  -port <port>       MySQL port (default: 3306)")
	fmt.Println("  -user <user>       MySQL user (default: root)")
	fmt.Println("  -password <pass>   MySQL password")
	fmt.Println("  -database <name>   Database name (default: lyanna)")
	fmt.Println("  -backup-path <path> Backup file path")
	fmt.Println("  -timestamp         Create backup with timestamp")
	fmt.Println()
	fmt.Println("Examples:")
	fmt.Println("  db -test")
	fmt.Println("  db -init")
	fmt.Println("  db -backup -timestamp")
	fmt.Println("  db -restore ./backups/lyanna_backup_2023-01-01_12-00-00.sql")
	fmt.Println("  db -health")
	fmt.Println("  db -clean 7")
	fmt.Println()
}
