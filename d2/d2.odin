package d2

import "core:os"
import "core:fmt"
import "core:sort"
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

smallest_side_perimeter :: proc(p: Cuboid) -> int {
  sides := []int{p.l, p.w, p.h}
  sort.quick_sort(sides)
  return 2 * (sides[0] + sides[1])
}

volume :: proc(p: Cuboid) -> int {
  return p.l * p.w * p.h
}

required_paper :: proc(p: Cuboid) -> int {
  return surface_area(p) + smallest_side_area(p)
}

required_ribbon :: proc(p: Cuboid) -> int {
  return smallest_side_perimeter(p) + volume(p)
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)
  total_paper := 0
  total_ribbon := 0
  for line in strings.split_lines_iterator(&s) {

    tokens := strings.split(line, "x")
    assert(len(tokens) == 3)

    p := Cuboid{l = strconv.atoi(tokens[0]),
                w = strconv.atoi(tokens[1]),
                h = strconv.atoi(tokens[2])}

    total_paper += required_paper(p)
    total_ribbon += required_ribbon(p)
  }

  fmt.println("P1:", total_paper, "P2:", total_ribbon)
}
