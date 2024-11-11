package d10

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:strings"

look_and_say :: proc(s: string) -> string {
  builder := strings.builder_make()
  count := 0
  prev: Maybe(rune)
  for c in s {
    if c == prev || prev == nil do count += 1
    else {
      strings.write_int(&builder, count)
      strings.write_rune(&builder, prev.?)

      count = 1
    }

    prev = c
  }

  strings.write_int(&builder, count)
  strings.write_rune(&builder, prev.?)

  return strings.to_string(builder)
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)
  s = s[:len(s) - 1] // Remove the trailing newline char

  p1, p2: int
  for i in 1..=50 {
    s = look_and_say(s)
    if i == 40 do p1 = len(s)
    if i == 50 do p2 = len(s)
  }

  fmt.println("P1:", p1, "P2:", p2)
}
