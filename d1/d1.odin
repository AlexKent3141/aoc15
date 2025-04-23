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

  // Find index when we go to the basement.
  p2: int
  level := 0
  for i in 0..<len(s) {
    if s[i] == '(' do level += 1
    else do level -= 1

    if level < 0 {
      p2 = i + 1
      break
    }
  }

  fmt.println("P1:", p1, "P2:", p2)
}
