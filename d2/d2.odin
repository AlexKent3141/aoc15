package d1

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:strings"

Cuboid :: struct {
  l, w, h: int,
}

surface_area :: proc(p: Cuboid) -> int {
  return 2 * (p.l * p.w + p.l * p.h + p.w * p.h)
}

smallest_side_area :: proc(p: Cuboid) -> int {
  return min(p.l * p.w, p.l * p.h, p.w * p.h)
}

required_paper :: proc(p: Cuboid) -> int {
  return surface_area(p) + smallest_side_area(p)
}

main :: proc() {

  data := os.read_entire_file("input.txt", context.allocator) or_else os.exit(1)
  defer delete(data, context.allocator)

  s := string(data)
  total := 0
  for line in strings.split_lines_iterator(&s) {

    tokens := strings.split(line, "x")
    assert(len(tokens) == 3)

    p := Cuboid{l = strconv.atoi(tokens[0]),
                w = strconv.atoi(tokens[1]),
                h = strconv.atoi(tokens[2])}

    total += required_paper(p)
  }

  fmt.println("P1:", total)
}
