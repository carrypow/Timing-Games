package logger

import (
	"fmt"
	"os"
	"runtime"
	"time"

	"github.com/sirupsen/logrus"
)

var Logger *logrus.Logger
var Logger2 *logrus.Logger
var Logger3 *logrus.Logger

// var Logger2 *logrus.Logger
var logFile *os.File
var logFile2 *os.File
var timerfile *os.File

var start_time time.Time

func Init() {
	// 创建或打开日志文件
	var errs error
	logFile, errs = os.OpenFile("Log/test1.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if errs != nil {
		panic("Failed to open log file: " + errs.Error())
	}

	Logger = logrus.New()
	Logger.Out = logFile
	Logger.SetLevel(logrus.DebugLevel) // 设置 Logger 的级别（debug, info, warning, error, fatal, panic）

	// 创建或打开日志文件2
	var errs2 error
	logFile2, errs2 = os.OpenFile("Log/test2.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if errs2 != nil {
		panic("Failed to open log file: " + errs2.Error())
	}

	Logger2 = logrus.New()
	Logger2.Out = logFile2
	Logger2.SetLevel(logrus.DebugLevel) // 设置 Logger 的级别（debug, info, warning, error, fatal, panic）	// 创建或打开日志文件2

	var errs3 error
	timerfile, errs3 = os.OpenFile("Log/test3.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if errs3 != nil {
		panic("Failed to open log file: " + errs3.Error())
	}

	Logger3 = logrus.New()
	Logger3.Out = timerfile
	Logger3.SetLevel(logrus.DebugLevel) // 设置 Logger 的级别（debug, info, warning, error, fatal, panic）

}

func Close() {
	if logFile != nil {
		logFile.Close()
	}
}

// PrintStack prints the current stack trace
func PrintStack1() {
	buf := make([]byte, 1024)
	for {
		n := runtime.Stack(buf, false)
		if n < len(buf) {
			buf = buf[:n]
			break
		}
		buf = make([]byte, len(buf)*2)
	}
	// Logger.Info(string(buf))
	// 使用 os.WriteFile 将字符串写入文件
	err := os.WriteFile("function_stack_UpdateHead.txt", []byte(string(buf)), 0644)
	if err != nil {
		fmt.Println("Failed to write to file:", err)
		return
	}
}

// PrintStack prints the current stack trace
func PrintStack2() {
	buf := make([]byte, 1024)
	for {
		n := runtime.Stack(buf, false)
		if n < len(buf) {
			buf = buf[:n]
			break
		}
		buf = make([]byte, len(buf)*2)
	}
	// Logger.Info(string(buf))
	// 使用 os.WriteFile 将字符串写入文件
	err := os.WriteFile("function_stack2_getParentState.txt", []byte(string(buf)), 0644)
	if err != nil {
		fmt.Println("Failed to write to file:", err)
		return
	}
}

func StartTimer() {
	start_time = time.Now()
}

func EndTimer(function string, info string) {
	duration := time.Since(start_time)

	Logger3.Info("[", function, "] ", info, "; ", "duration: ", duration)
}
