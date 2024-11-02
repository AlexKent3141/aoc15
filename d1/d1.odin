package d1

import "core:os"
import "core:fmt"
import "core:strings"

main :: proc() {

  data, ok := os.read_entire_file("input.txt", context.allocator)
  if !ok {
    fmt.println("Failed reading file")
    return
  }
  defer delete(data, context.allocator)

  s := string(data)

  p1 := strings.count(s, "(") - strings.count(s, ")")
  fmt.println("P1:", p1)

  // Find index when we go to the basement.
  level := 0
  for i in 0..<len(s) {
    if s[i] == '(' do level += 1
    else do level -= 1

    if level < 0 {
      fmt.println("P2:", i + 1)
      break
    }
  }
}
