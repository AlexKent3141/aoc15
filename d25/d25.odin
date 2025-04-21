package d25

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  tokens := strings.split(s, " ")
  defer delete(tokens)

  row, col := strconv.atoi(tokens[16]),  strconv.atoi(tokens[18])

  first_code := proc(row, col: int) -> int {
    // Find the row start.
    row_start := 1 + row * (row - 1) / 2

    // Add the difference to get to the column.
    col_offset := (col - 1 + row + 1) * (col - 1 + row) / 2 - (row + 1) * row / 2
    return row_start + col_offset
  }

  second_code := proc(start, mul, mod, power: int) -> int {
    current := start
    for _ in 1..<power {
      current *= mul
      current %= mod
    }

    return current
  }

  code1 := first_code(row, col)
  code2 := second_code(20151125, 252533, 33554393, code1)

  fmt.println("P1:", code2)
}
