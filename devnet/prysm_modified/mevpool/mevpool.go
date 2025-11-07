package mevpool

import (
	"bufio"
	"bytes"
	"encoding/binary"
	"encoding/csv"
	"fmt"
	"math"
	"math/rand"
	"os"
	"sort"
	"strconv"
	"strings"
	"syscall"

	"github.com/prysmaticlabs/prysm/v5/logger"
)

const (
	filePath = "/dev/shm/counter.dat"
	size     = 4
)

func ReadCounter() (int32, error) {
	if _, err := os.Stat(filePath); err != nil {
		return 0, fmt.Errorf("file stat error: %w", err)
	}
	f, err := os.OpenFile(filePath, os.O_RDONLY, 0644)
	if err != nil {
		return 0, fmt.Errorf("open file failed: %w", err)
	}
	defer f.Close()

	data, err := syscall.Mmap(int(f.Fd()), 0, size, syscall.PROT_READ, syscall.MAP_SHARED)
	if err != nil {
		return 0, fmt.Errorf("mmap failed: %w", err)
	}
	defer syscall.Munmap(data)

	value := binary.LittleEndian.Uint32(data)
	return int32(value), nil
}


func ReadAndWriteFile(filename string, count int) (int, error) {

	if _, err := os.Stat(filename); os.IsNotExist(err) {

		err := os.WriteFile(filename, []byte(strconv.Itoa(count)), 0644)
		if err != nil {
			return 0, fmt.Errorf("could not create file: %v", err)
		}

		return 0, nil
	}


	data, err := os.ReadFile(filename)
	if err != nil {
		return 0, fmt.Errorf("Unable to read file: %v", err)
	}


	oldCount, err := strconv.Atoi(string(data))
	if err != nil {
		return 0, fmt.Errorf("The file content is not a valid integer: %v", err)
	}


	err = os.WriteFile(filename, []byte(strconv.Itoa(count)), 0644)
	if err != nil {
		return 0, fmt.Errorf("Unable to write file: %v", err)
	}

	return oldCount, nil
}


func GenerateMEV(txCount int, mean float64, sigma float64, probability float64) float64 {
	randSource := rand.New(rand.NewSource(42))

	var totalMEV float64
	for i := 0; i < txCount; i++ {
		normValue := randSource.NormFloat64()
		signalValue := math.Exp(mean + sigma*normValue)
		if randSource.Float64() > probability {
			signalValue = 0
		}
		if signalValue > 1 {
			signalValue = 1 
		}
		totalMEV += signalValue
	}
	return totalMEV
}

func GenerateMEV2(filePath string, slotCount int) (float64, error) {
	randSource := rand.New(rand.NewSource(42))

	data, err := os.ReadFile(filePath)
	if err != nil {
		return 0, fmt.Errorf("fail to read file: %v", err)
	}

	lines := bytes.Split(data, []byte{'\n'})
	if len(lines) < 2 {
		return 0, fmt.Errorf("Insufficient number of file lines")
	}
	dataLines := lines[1:] 

	totalLines := len(dataLines)
	if slotCount > totalLines {
		return 0, fmt.Errorf("Sampling quantity exceeds the number of file lines")
	}

	sampledIndices := make([]int, slotCount)
	for i := 0; i < slotCount; i++ {
		j := randSource.Intn(totalLines - i)
		sampledIndices[i] = j
	}


	var total float64
	for _, idx := range sampledIndices {
		row := bytes.Split(dataLines[idx], []byte{','})
		if len(row) < 4 {
			continue 
		}
		value, err := strconv.ParseFloat(string(row[3]), 64)
		if err != nil {
			continue
		}
		total += value
	}

	return total, nil
}

func CalculateSumOfTopValues(values []float64, topN int) float64 {
	if len(values) == 0 {
		return 0
	}

	sort.Float64s(values)
	count := topN
	if len(values) < count {
		count = len(values)
	}

	sum := 0.0
	for _, value := range values[:count] {
		sum += value
	}
	return sum
}

func ClearFileContent(filename string) error {
	file, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer file.Close()
	return nil
}
