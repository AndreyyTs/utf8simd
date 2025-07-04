//go:build !purego

#include "textflag.h"

// func validateNEON(p []byte) bool
// Функция валидации UTF-8 строки с использованием ARM64 NEON SIMD инструкций
TEXT ·Valid(SB),NOSPLIT,$0-25
    // Загружаем параметры функции из стека
    MOVD    s_base+0(FP), R10      // Указатель на начало строки в R10
    MOVD    s_len+8(FP), R11       // Длина строки в R11
    CBZ     R11, valid             // Если длина = 0, строка валидна
    CMP     $16, R11               
    BLT     small                  // Если длина < 16 байт, обрабатываем отдельно

    // Инициализация маски для проверки ASCII символов (бит 7 = 1 означает не-ASCII)
    VMOVQ   $0x8080808080808080, $0x8080808080808080, V0

ascii_loop:
    // Быстрая проверка на ASCII символы (оптимизация для чисто ASCII строк)
    CMP     $16, R11
    BLT     small                  // Если осталось < 16 байт, переходим к обработке остатка

    VLD1    (R10), [V1.B16]        // Загружаем 16 байт в SIMD регистр V1
    VCMTST  V1.B16, V0.B16, V2.B16 // Тестируем биты 0x80 (проверка на не-ASCII)
    VMOV    V2.D[0], R2            // Перемещаем результат в скалярные регистры
    VMOV    V2.D[1], R3
    ORR     R2, R3, R2             // Объединяем результаты
    CBNZ    R2, stop_ascii         // Если найден не-ASCII символ, прекращаем ASCII цикл

    ADD     $16, R10               // Переходим к следующему блоку
    SUB     $16, R11               // Уменьшаем счетчик оставшихся байт
    B       ascii_loop             // Продолжаем ASCII цикл

stop_ascii:
    // Инициализация констант для алгоритма Мулы (Lemire) валидации UTF-8
    // Эти константы используются в lookup таблицах для быстрой валидации UTF-8
    VMOVQ   $0x0202020202020202, $0x4915012180808080, V11  // Lookup таблица 1
    VMOVQ   $0xcbcbcb8b8383a3e7, $0xcbcbdbcbcbcbcbcb, V13  // Lookup таблица 2  
    VMOVQ   $0x0101010101010101, $0x01010101babaaee6, V15  // Lookup таблица 3
    VMOVQ   $0x0F0F0F0F0F0F0F0F, $0x0F0F0F0F0F0F0F0F, V18  // Маска для младших 4 бит
    VMOVQ   $0x0707070707070707, $0x0707070707070707, V12  // Маска 0x07
    VMOVQ   $0xFFFFFFFFFFFFFFFF, $0xFFFFFFFFFFFFFFFF, V14  // Маска всех единиц
    VMOVQ   $0x7F7F7F7F7F7F7F7F, $0x7F7F7F7F7F7F7F7F, V16  // Маска 0x7F
    VMOVQ   $0xDFDFDFDFDFDFDFDF, $0xDFDFDFDFDFDFDFDF, V17  // Маска 0xDF
    VMOVQ   $0x0808080808080808, $0x0808080808080808, V19  // Маска 0x08
    VMOVQ   $0x8080808080808080, $0x8080808080808080, V20  // Маска 0x80
    VMOVQ   $0x0000000000000000, $0x0000000000000000, V30  // Нулевой вектор
    VMOVQ   $0x0000000000000000, $0x0000000000000000, V3   // Предыдущий блок данных

aligned_loop:
    // Основной цикл валидации UTF-8 с использованием алгоритма Мулы
    VLD1.P  16(R10), [V4.B16]      // Загружаем 16 байт и увеличиваем указатель
    
    // Сдвигаем данные для анализа переходов между байтами
    VEXT    $15, V4.B16, V3.B16, V5.B16  // Берем последний байт предыдущего блока + текущий
    VUSHR   $4, V5.B16, V6.B16     // Сдвигаем на 4 бита вправо (старшие 4 бита)
    VTBL    V6.B16, [V11.B16], V6.B16    // Lookup в первой таблице
    VAND    V5.B16, V18.B16, V7.B16      // Выделяем младшие 4 бита
    VTBL    V7.B16, [V13.B16], V7.B16    // Lookup во второй таблице
    VUSHR   $4, V4.B16, V8.B16     // Старшие 4 бита текущего блока
    VTBL    V8.B16, [V15.B16], V8.B16    // Lookup в третьей таблице
    
    // Комбинируем результаты lookup'ов
    VAND    V6.B16, V7.B16, V9.B16
    VAND    V9.B16, V8.B16, V10.B16
    
    // Дополнительные проверки для специальных случаев UTF-8
    VEXT    $14, V4.B16, V3.B16, V5.B16  // Проверка на позиции -2
    VUSHR   $5, V5.B16, V6.B16     // Сдвиг на 5 бит для проверки старших битов
    VCMEQ   V12.B16, V6.B16, V6.B16      // Сравнение с 0x07
    
    VEXT    $13, V4.B16, V3.B16, V5.B16  // Проверка на позиции -3
    VUSHR   $4, V5.B16, V9.B16     // Сдвиг на 4 бита
    VCMEQ   V18.B16, V9.B16, V9.B16      // Сравнение с 0x0F
    VORR    V6.B16, V9.B16, V9.B16       // Объединение результатов
    
    // Финальная проверка валидности
    VAND    V9.B16, V20.B16, V9.B16      // Применяем маску 0x80
    VSUB    V9.B16, V10.B16, V9.B16      // Вычитаем из основного результата
    VMOV    V9.D[0], R1            // Перемещаем результат в скалярные регистры
    VMOV    V9.D[1], R2
    ORR     R1, R2, R1             // Объединяем половины результата
    CBNZ    R1, no_valid           // Если результат не ноль, строка невалидна
    
    VMOV    V4.B16, V3.B16         // Сохраняем текущий блок как предыдущий
    SUB     $16, R11, R11          // Уменьшаем счетчик оставшихся байт
    CMP     $16, R11               

    BGE     aligned_loop           // Если осталось >= 16 байт, продолжаем цикл

    B small_no_const               // Переходим к обработке остатка

small:
    // Обработка небольших строк (< 16 байт)
    CBZ     R11, valid             // Если байт не осталось, строка валидна

tail_loop:
    // Простая проверка по одному байту для маленьких строк
    MOVBU   (R10), R2              // Загружаем один байт
    AND     $0x80, R2              // Проверяем старший бит
    CBNZ    R2, check_utf8         // Если установлен, нужна полная проверка UTF-8
    ADD     $1, R10                // Переходим к следующему байту
    SUB     $1, R11                // Уменьшаем счетчик
    CBNZ    R11, tail_loop         // Продолжаем пока есть байты
    B       valid                  // Все байты ASCII - строка валидна

check_utf8:
    // Инициализация констант для полной проверки UTF-8
    // (те же константы, что и выше)
    VMOVQ   $0x0202020202020202, $0x4915012180808080, V11
    VMOVQ   $0xcbcbcb8b8383a3e7, $0xcbcbdbcbcbcbcbcb, V13
    VMOVQ   $0x0101010101010101, $0x01010101babaaee6, V15
    VMOVQ   $0x0F0F0F0F0F0F0F0F, $0x0F0F0F0F0F0F0F0F, V18
    VMOVQ   $0x0707070707070707, $0x0707070707070707, V12
    VMOVQ   $0xFFFFFFFFFFFFFFFF, $0xFFFFFFFFFFFFFFFF, V14
    VMOVQ   $0x7F7F7F7F7F7F7F7F, $0x7F7F7F7F7F7F7F7F, V16
    VMOVQ   $0xDFDFDFDFDFDFDFDF, $0xDFDFDFDFDFDFDFDF, V17
    VMOVQ   $0x0808080808080808, $0x0808080808080808, V19
    VMOVQ   $0x8080808080808080, $0x8080808080808080, V20
    VMOVQ   $0x0000000000000000, $0x0000000000000000, V30
    VMOVQ   $0x0000000000000000, $0x0000000000000000, V3

small_no_const:
    // Подготовка данных для обработки остатка < 16 байт
    SUB $16, R10, R10              // Откатываемся на 16 байт назад
    ADD R11, R10, R10              // Добавляем количество оставшихся байт
    VLD1.P  16(R10), [V4.B16]      // Загружаем 16 байт (включая "мусор")

    // Использование таблицы переходов для маскирования лишних байт
    ADR  shift_table, R2           // Адрес таблицы переходов
    MOVW R11, R3                   // Количество валидных байт
    LSL $2,  R3                    // Умножаем на 4 (размер инструкции)
    ADD R3, R2                     // Вычисляем адрес перехода
    B (R2)                         // Переходим к соответствующему обработчику

shift_table:
    // Таблица переходов для обработки 0-15 байт
    B do_shift_0                   // 0 байт - заполняем ASCII символами
    B do_shift_1                   // 1 байт валидный
    B do_shift_2                   // 2 байта валидных
    B do_shift_3                   // 3 байта валидных
    B do_shift_4                   // 4 байта валидных
    B do_shift_5                   // 5 байт валидных
    B do_shift_6                   // 6 байт валидных
    B do_shift_7                   // 7 байт валидных
    B do_shift_8                   // 8 байт валидных
    B do_shift_9                   // 9 байт валидных
    B do_shift_10                  // 10 байт валидных
    B do_shift_11                  // 11 байт валидных
    B do_shift_12                  // 12 байт валидных
    B do_shift_13                  // 13 байт валидных
    B do_shift_14                  // 14 байт валидных
    B do_shift_15                  // 15 байт валидных

do_shift_0:
    // 0 валидных байт - заполняем вектор ASCII символами 'a' (0x61)
    VMOVQ   $0x6161616161616161, $0x6161616161616161, V4
    B end_swith
do_shift_1:
    // 1 валидный байт - сдвигаем на 15 позиций (маскируем 15 байт)
    VEXT    $15, V30.B16, V4.B16, V4.B16
    B end_swith
do_shift_2:
    // 2 валидных байта - сдвигаем на 14 позиций
    VEXT    $14, V30.B16, V4.B16, V4.B16
    B end_swith
do_shift_3:
    // 3 валидных байта - сдвигаем на 13 позиций
    VEXT    $13, V30.B16, V4.B16, V4.B16
    B end_swith
do_shift_4:
    // 4 валидных байта - сдвигаем на 12 позиций
    VEXT    $12, V30.B16, V4.B16, V4.B16
    B end_swith
do_shift_5:
    // 5 валидных байт - сдвигаем на 11 позиций
    VEXT    $11, V30.B16, V4.B16, V4.B16
    B end_swith
do_shift_6:
    // 6 валидных байт - сдвигаем на 10 позиций
    VEXT    $10, V30.B16, V4.B16, V4.B16
    B end_swith
do_shift_7:
    // 7 валидных байт - сдвигаем на 9 позиций
    VEXT    $9, V30.B16, V4.B16, V4.B16
    B end_swith
do_shift_8:
    // 8 валидных байт - сдвигаем на 8 позиций
    VEXT    $8, V30.B16, V4.B16, V4.B16
    B end_swith
do_shift_9:
    // 9 валидных байт - сдвигаем на 7 позиций
    VEXT    $7, V30.B16, V4.B16, V4.B16
    B end_swith
do_shift_10:
    // 10 валидных байт - сдвигаем на 6 позиций
    VEXT    $6, V30.B16, V4.B16, V4.B16
    B end_swith
do_shift_11:
    // 11 валидных байт - сдвигаем на 5 позиций
    VEXT    $5, V30.B16, V4.B16, V4.B16
    B end_swith
do_shift_12:
    // 12 валидных байт - сдвигаем на 4 позиции
    VEXT    $4, V30.B16, V4.B16, V4.B16
    B end_swith
do_shift_13:
    // 13 валидных байт - сдвигаем на 3 позиции
    VEXT    $3, V30.B16, V4.B16, V4.B16
    B end_swith
do_shift_14:
    // 14 валидных байт - сдвигаем на 2 позиции
    VEXT    $2, V30.B16, V4.B16, V4.B16
    B end_swith
do_shift_15:
    // 15 валидных байт - сдвигаем на 1 позицию
    VEXT    $1, V30.B16, V4.B16, V4.B16
    B end_swith

end_swith:
    // Выполняем ту же валидацию UTF-8, что и в основном цикле
    VEXT    $15, V4.B16, V3.B16, V5.B16   // Анализ переходов между байтами
    VUSHR   $4, V5.B16, V6.B16            // Старшие 4 бита
    VTBL    V6.B16, [V11.B16], V6.B16     // Lookup таблица 1
    VAND    V5.B16, V18.B16, V7.B16       // Младшие 4 бита
    VTBL    V7.B16, [V13.B16], V7.B16     // Lookup таблица 2
    VUSHR   $4, V4.B16, V8.B16            // Старшие 4 бита текущих байт
    VTBL    V8.B16, [V15.B16], V8.B16     // Lookup таблица 3
    VAND    V6.B16, V7.B16, V9.B16        // Комбинирование результатов
    VAND    V9.B16, V8.B16, V10.B16

    // Дополнительные проверки
    VEXT    $14, V4.B16, V3.B16, V5.B16   // Проверка позиции -2
    VUSHR   $5, V5.B16, V6.B16
    VCMEQ   V12.B16, V6.B16, V6.B16

    VEXT    $13, V4.B16, V3.B16, V5.B16   // Проверка позиции -3
    VUSHR   $4, V5.B16, V9.B16
    VCMEQ   V18.B16, V9.B16, V9.B16
    VORR    V6.B16, V9.B16, V9.B16

    // Финальная валидация
    VAND    V9.B16, V20.B16, V9.B16
    VSUB    V9.B16, V10.B16, V9.B16
    VMOV    V9.D[0], R1                   // Получаем результат
    VMOV    V9.D[1], R2
    ORR     R1, R2, R1
    CBNZ    R1, no_valid                  // Если не ноль, строка невалидна

valid:
    // Строка валидна - возвращаем true (1)
    MOVD    $1, R0
    MOVD    R0, ret+24(FP)
    RET

no_valid:
    // Строка невалидна - возвращаем false (0)
    MOVD    $0, R0
    MOVD    R0, ret+24(FP)
    RET
