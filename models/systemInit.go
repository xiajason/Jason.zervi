package models

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"time"

	"github.com/garyburd/redigo/redis"
	_ "github.com/go-sql-driver/mysql"
	"github.com/jinzhu/gorm"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"gopkg.in/natefinch/lumberjack.v2"
	"gopkg.in/yaml.v2"
)

const (
	SESSION_KEY          = "UserID"
	CONTEXT_USER_KEY     = "User"
	CONTEXT_GIT_USER_KEY = "GitUser"
	SESSION_GITHUB_STATE = "GITHUB_STATE" // github state session key
)

var (
	DB        *gorm.DB
	RedisPool *redis.Pool
	Conf      = new(Config)
	Logger    *zap.Logger
)

type Config struct {
	RunMode string
	General struct {
		Addr          string
		DSN           string
		SessionSecret string
		LogOutEnabled bool
		PerPage       int
	}
	GitHub struct {
		ClientID     string
		ClientSecret string
		AuthUrl      string
		RedirectUrl  string
		TokenUrl     string
	}
	Redis struct {
		Host        string
		Port        int
		Password    string
		DB          int
		MaxIdle     int
		MaxActive   int
		IdleTimeout int
	}
	Log struct {
		LogPath    string
		MaxSize    int
		MaxAge     int
		Compress   bool
		MaxBackups int
	}
}

func checkError(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

func InitDB() (err error) {
	db, err := gorm.Open("mysql", Conf.General.DSN)
	if err != nil {
		Logger.Error("Failed to connect to database", zap.Error(err))
		return err
	}

	Logger.Info("Database connected successfully")
	DB = db

	// 设置连接池
	DB.DB().SetMaxIdleConns(10)
	DB.DB().SetMaxOpenConns(100)
	DB.DB().SetConnMaxLifetime(time.Hour)

	// 启用日志模式（仅在debug模式下）
	if Conf.RunMode == "debug" {
		DB.LogMode(true)
	}

	// 自动迁移数据库表
	err = DB.AutoMigrate(&Comment{}, &Post{}, &PostTag{}, &ReactItem{}, &Tag{}, &User{}, &GitHubUser{}).Error
	if err != nil {
		Logger.Error("Failed to migrate database", zap.Error(err))
		return err
	}

	Logger.Info("Database migration completed successfully")
	return nil
}

func initRedis() error {
	redisAddr := fmt.Sprintf("%s:%d", Conf.Redis.Host, Conf.Redis.Port)

	RedisPool = &redis.Pool{
		MaxIdle:     Conf.Redis.MaxIdle,
		MaxActive:   Conf.Redis.MaxActive,
		IdleTimeout: time.Duration(Conf.Redis.IdleTimeout) * time.Second,
		Dial: func() (redis.Conn, error) {
			conn, err := redis.Dial("tcp", redisAddr)
			if err != nil {
				return nil, err
			}

			// 如果设置了密码，进行认证
			if Conf.Redis.Password != "" {
				if _, err = conn.Do("AUTH", Conf.Redis.Password); err != nil {
					conn.Close()
					return nil, err
				}
			}

			// 选择数据库
			if _, err = conn.Do("SELECT", Conf.Redis.DB); err != nil {
				conn.Close()
				return nil, err
			}

			return conn, err
		},
		TestOnBorrow: func(conn redis.Conn, t time.Time) error {
			if time.Since(t) < time.Minute {
				return nil
			}
			_, err := conn.Do("PING")
			return err
		},
	}

	// 测试Redis连接
	conn := RedisPool.Get()
	defer conn.Close()

	_, err := conn.Do("PING")
	if err != nil {
		Logger.Error("Failed to connect to Redis", zap.Error(err))
		return err
	}

	Logger.Info("Redis connected successfully")
	return nil
}

// 初始化日志配置
func initLog() {
	// 确保日志目录存在
	logDir := "./logs"
	if _, err := os.Stat(logDir); os.IsNotExist(err) {
		os.MkdirAll(logDir, 0755)
	}

	hook := lumberjack.Logger{
		Filename:   Conf.Log.LogPath,    //日志文件路径
		MaxSize:    Conf.Log.MaxSize,    // 每个日志的大小，单位是M
		MaxAge:     Conf.Log.MaxAge,     // 文件被保存的天数
		Compress:   Conf.Log.Compress,   // 是否压缩
		MaxBackups: Conf.Log.MaxBackups, // 保存多少个文件备份
	}
	encoderConfig := zapcore.EncoderConfig{
		TimeKey:        "Time",
		LevelKey:       "Level",
		NameKey:        "Logger",
		CallerKey:      "Caller",
		MessageKey:     "Msg",
		LineEnding:     zapcore.DefaultLineEnding,
		EncodeLevel:    zapcore.LowercaseLevelEncoder,
		EncodeTime:     zapcore.ISO8601TimeEncoder,
		EncodeDuration: zapcore.SecondsDurationEncoder,
		EncodeCaller:   zapcore.ShortCallerEncoder,
	}
	atomicLevel := zap.NewAtomicLevel()
	atomicLevel.SetLevel(zap.InfoLevel)
	core := zapcore.NewCore(
		zapcore.NewJSONEncoder(encoderConfig),
		zapcore.NewMultiWriteSyncer(zapcore.AddSync(os.Stdout), zapcore.AddSync(&hook)),
		atomicLevel,
	)
	caller := zap.AddCaller()
	development := zap.Development()
	filed := zap.Fields(zap.String("service", "blog"))
	Logger = zap.New(core, caller, development, filed)
}

func init() {
	data, err := ioutil.ReadFile("config/config.yaml")
	checkError(err)
	err = yaml.Unmarshal(data, Conf)
	checkError(err)

	initLog()
	Logger.Info("Configuration and logging initialized successfully")

	err = InitDB()
	checkError(err)

	err = initRedis()
	checkError(err)

	Logger.Info("System initialization completed successfully")
}
