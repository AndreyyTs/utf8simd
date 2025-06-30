# UTF8SIMD

High-performance library for UTF-8 string validation using SIMD instructions for ARM64.

Based on the paper [Validating UTF-8 In Less Than One Instruction Per
Byte](https://arxiv.org/pdf/2010.03090)

## Description

`utf8simd` provides an optimized UTF-8 validation implementation that runs **~10x faster** than Go's standard library by utilizing SIMD (Single Instruction, Multiple Data) vector instructions.

### Key Features

- 🚀 **High Performance**: up to 10x speedup compared to `unicode/utf8`
- 🎯 **SIMD Optimizations**: uses NEON for ARM64
- 🔄 **Fallback Support**: automatically uses standard library on unsupported architectures
- ✅ **100% Compatibility**: fully compatible with `unicode/utf8.Valid()`
- 🧪 **Thoroughly Tested**: includes fuzz testing and edge cases

## Installation

```bash
go get github.com/AndreyyTs/utf8simd
```

## Usage

```go
package main

import (
    "fmt"
    "github.com/AndreyyTs/utf8simd"
)

func main() {
    // UTF-8 bytes validation
    data := []byte("Hello, world! 🌍")
    isValid := utf8simd.Valid(data)
    fmt.Printf("String is valid: %v\n", isValid)
    
    // Works with any data
    invalidData := []byte{0xFF, 0xFE, 0xFD}
    isValid = utf8simd.Valid(invalidData)
    fmt.Printf("Invalid data: %v\n", isValid)
}
```

## Performance

### Benchmarks on various data sizes

#### Small strings (10 bytes)
```
ASCII data:
Stdlib:    3.795 ns/op    2635.38 MB/s
charcoal:  4.056 ns/op    2465.23 MB/s  
SIMD:      5.658 ns/op    1767.41 MB/s

Japanese text (UTF-8):
Stdlib:    27.78 ns/op    1079.80 MB/s
charcoal:  14.73 ns/op    2036.79 MB/s
SIMD:      5.922 ns/op    5065.75 MB/s    (4.7x faster than stdlib)
```

#### Medium files (1 KB)
```
Mixed content:
Stdlib:    893.5 ns/op    1146.01 MB/s
charcoal:  421.7 ns/op    2428.44 MB/s
SIMD:      106.2 ns/op    9641.60 MB/s    (8.4x faster than stdlib)
```

#### Large files (1 MB)
```
Mixed content:
Stdlib:    916612 ns/op   1143.97 MB/s
charcoal:  416901 ns/op   2515.17 MB/s
SIMD:      102415 ns/op   10238.46 MB/s   (9.0x faster than stdlib)
```

### Performance comparison by size

| Data Size | Stdlib (MB/s) | charcoal (MB/s) | SIMD (MB/s) | Speedup |
|-----------|---------------|-----------------|-------------|---------|
| 4 KB      | 1,280         | 1,645           | **10,030**  | **7.8x** |
| 32 KB     | 1,284         | 1,659           | **10,239**  | **8.0x** |
| 64 KB     | 1,283         | 1,660           | **10,260**  | **8.0x** |
| 256 KB    | 1,253         | 1,647           | **10,269**  | **8.2x** |
| 4 MB      | 1,219         | 1,610           | **10,263**  | **8.4x** |
| 32 MB     | 1,249         | 1,648           | **10,233**  | **8.2x** |

## Supported Architectures

- **ARM64**: Uses NEON SIMD instructions
- **Other architectures**: Automatic fallback to `unicode/utf8`

## Algorithm

[The library uses an optimized UTF-8 validation algorithm:](https://arxiv.org/pdf/2010.03090)

1. **Fast ASCII check**: Vector check for pure ASCII characters
2. **Mula (Lemire) algorithm**: Efficient UTF-8 validation using lookup tables
3. **Boundary handling**: Special logic for processing data smaller than 16 bytes
4. **Vector operations**: Parallel processing of 16 bytes at a time

## Testing

The library includes extensive testing:

```bash
# Run all tests
go test .

# Run benchmarks
go test -bench=BenchmarkValid

# Fuzz testing
go test -fuzz=FuzzValid
```

### Test Types

- **Unit tests**: Correctness verification on various input data
- **Boundary tests**: Testing at memory block boundaries
- **Fuzz testing**: Automatic test case generation
- **Benchmarks**: Performance measurement

## API

### `func Valid(data []byte) bool`

Checks whether a byte slice is a valid UTF-8 sequence.

**Parameters:**
- `data []byte` - byte slice to check

**Returns:**
- `bool` - `true` if data is valid UTF-8, `false` otherwise

**Example:**
```go
data := []byte("Hello, 世界!")
isValid := utf8simd.Valid(data) // true

invalidData := []byte{0xFF, 0xFE}
isValid = utf8simd.Valid(invalidData) // false
```

## Project Usage

The library is ideal for:

- **Web servers**: Fast validation of incoming data
- **Parsers**: Checking text formats (JSON, XML, etc.)
- **File processing**: Validation of large text files
- **API services**: Checking UTF-8 correctness in requests

## Limitations

- Requires Go 1.18+ for generics support in tests
- SIMD optimizations are only available on ARM64
- On other architectures, performance matches the standard library

## Acknowledgments

Algorithm based on the work of:
- Daniel Lemire and John Keiser
---------------
# UTF8SIMD

Высокопроизводительная библиотека для валидации UTF-8 строк с использованием SIMD инструкций для ARM64.

Основанная на статье [Validating UTF-8 In Less Than One Instruction Per
Byte](https://arxiv.org/pdf/2010.03090)

## Описание

`utf8simd` предоставляет оптимизированную реализацию валидации UTF-8, которая работает **в ~10 раз быстрее** стандартной библиотеки Go благодаря использованию векторных инструкций SIMD (Single Instruction, Multiple Data)

### Ключевые особенности

- 🚀 **Высокая производительность**: до 10x ускорение по сравнению с `unicode/utf8`
- 🎯 **SIMD оптимизации**: использует NEON для ARM64
- 🔄 **Fallback поддержка**: автоматически использует стандартную библиотеку на неподдерживаемых архитектурах
- ✅ **100% совместимость**: полностью совместима с `unicode/utf8.Valid()`
- 🧪 **Тщательно протестирована**: включает fuzz-тестирование и граничные случаи

## Установка

```bash
go get github.com/AndreyyTs/utf8simd
```

## Использование

```go
package main

import (
    "fmt"
    "github.com/AndreyyTs/utf8simd"
)

func main() {
    // Валидация UTF-8 байтов
    data := []byte("Привет, мир! 🌍")
    isValid := utf8simd.Valid(data)
    fmt.Printf("Строка валидна: %v\n", isValid)
    
    // Работает с любыми данными
    invalidData := []byte{0xFF, 0xFE, 0xFD}
    isValid = utf8simd.Valid(invalidData)
    fmt.Printf("Невалидные данные: %v\n", isValid)
}
```

## Производительность

### Бенчмарки на различных размерах данных

#### Малые строки (10 байт)
```
ASCII данные:
Stdlib:    3.795 ns/op    2635.38 MB/s
charcoal:  4.056 ns/op    2465.23 MB/s  
SIMD:      5.658 ns/op    1767.41 MB/s

Японский текст (UTF-8):
Stdlib:    27.78 ns/op    1079.80 MB/s
charcoal:  14.73 ns/op    2036.79 MB/s
SIMD:      5.922 ns/op    5065.75 MB/s    (4.7x быстрее stdlib)
```

#### Средние файлы (1 КБ)
```
Смешанный контент:
Stdlib:    893.5 ns/op    1146.01 MB/s
charcoal:  421.7 ns/op    2428.44 MB/s
SIMD:      106.2 ns/op    9641.60 MB/s    (8.4x быстрее stdlib)
```

#### Большие файлы (1 МБ)
```
Смешанный контент:
Stdlib:    916612 ns/op   1143.97 MB/s
charcoal:  416901 ns/op   2515.17 MB/s
SIMD:      102415 ns/op   10238.46 MB/s   (9.0x быстрее stdlib)
```

### Сравнение производительности по размерам

| Размер данных | Stdlib (MB/s) | charcoal (MB/s) | SIMD (MB/s) | Ускорение |
|---------------|---------------|-----------------|-------------|-----------|
| 4 КБ          | 1,280         | 1,645           | **10,030**  | **7.8x**  |
| 32 КБ         | 1,284         | 1,659           | **10,239**  | **8.0x**  |
| 64 КБ         | 1,283         | 1,660           | **10,260**  | **8.0x**  |
| 256 КБ        | 1,253         | 1,647           | **10,269**  | **8.2x**  |
| 4 МБ          | 1,219         | 1,610           | **10,263**  | **8.4x**  |
| 32 МБ         | 1,249         | 1,648           | **10,233**  | **8.2x**  |

## Поддерживаемые архитектуры

- **ARM64**: Использует NEON SIMD инструкции
- **Другие архитектуры**: Автоматический fallback на `unicode/utf8`

## Алгоритм

[Библиотека использует оптимизированный алгоритм валидации UTF-8:](https://arxiv.org/pdf/2010.03090)

1. **Быстрая проверка ASCII**: Векторная проверка на чисто ASCII символы
2. **Алгоритм Мулы (Lemire)**: Эффективная валидация UTF-8 с использованием lookup таблиц
3. **Обработка границ**: Специальная логика для обработки данных размером менее 16 байт
4. **Векторные операции**: Параллельная обработка 16 байт за раз

## Тестирование

Библиотека включает обширное тестирование:

```bash
# Запуск всех тестов
go test .

# Запуск бенчмарков
go test -bench=BenchmarkValid

# Fuzz тестирование
go test -fuzz=FuzzValid
```

### Типы тестов

- **Модульные тесты**: Проверка корректности на различных входных данных
- **Граничные тесты**: Тестирование на границах блоков памяти
- **Fuzz тестирование**: Автоматическая генерация тестовых случаев
- **Бенчмарки**: Измерение производительности

## API

### `func Valid(data []byte) bool`

Проверяет, является ли срез байтов валидной UTF-8 последовательностью.

**Параметры:**
- `data []byte` - срез байтов для проверки

**Возвращает:**
- `bool` - `true` если данные являются валидным UTF-8, `false` в противном случае

**Пример:**
```go
data := []byte("Hello, 世界!")
isValid := utf8simd.Valid(data) // true

invalidData := []byte{0xFF, 0xFE}
isValid = utf8simd.Valid(invalidData) // false
```

## Использование в проекте

Библиотека идеально подходит для:

- **Веб-серверы**: Быстрая валидация входящих данных
- **Парсеры**: Проверка текстовых форматов (JSON, XML, etc.)
- **Обработка файлов**: Валидация больших текстовых файлов
- **API сервисы**: Проверка корректности UTF-8 в запросах

## Ограничения

- Требует Go 1.18+ для поддержки generics в тестах
- SIMD оптимизации доступны только на ARM64
- На других архитектурах производительность соответствует стандартной библиотеке

## Благодарности

Алгоритм основан на работах:
- Daniel Lemire и John Keiser
