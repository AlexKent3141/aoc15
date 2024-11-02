package d3

import "core:container/avl"
import "core:os"
import "core:fmt"
import "core:slice"
import "core:strings"

Point :: struct {
  x, y: int
}

step :: proc(p: Point, c: rune) -> Point {
  n := p
  switch c {
    case '^': n.y += 1
    case 'v': n.y -= 1
    case '>': n.x += 1
    case '<': n.x -= 1
  }

  return n
}

point_cmp :: proc(a, b: Point) -> slice.Ordering {
  if a.x != b.x do return a.x < b.x ? slice.Ordering.Less : slice.Ordering.Greater
  if a.y != b.y do return a.y < b.y ? slice.Ordering.Less : slice.Ordering.Greater
  return slice.Ordering.Equal
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  tree: avl.Tree(Point)
  avl.init(&tree, point_cmp)

  p := Point{0, 0}
  avl.find_or_insert(&tree, p)

  for c in s {
    p = step(p, c)
    avl.find_or_insert(&tree, p)
  }

  fmt.println("P1:", avl.len(&tree))
}
