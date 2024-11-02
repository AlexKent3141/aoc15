package d3

import "core:container/avl"
import "core:os"
import "core:fmt"
import "core:slice"
import "core:strings"

Point :: struct {
  x, y: int
}

step :: proc(p: Point, c: $T) -> Point {
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

  tree1, tree2: avl.Tree(Point)
  avl.init(&tree1, point_cmp)
  avl.init(&tree2, point_cmp)

  p := Point{0, 0}

  s1 := Point{0, 0}
  s2 := Point{0, 0}

  avl.find_or_insert(&tree1, p)
  avl.find_or_insert(&tree2, p)

  for i in 0..<len(s) {
    p = step(p, s[i])
    avl.find_or_insert(&tree1, p)

    if i & 1 == 0 {
      s1 = step(s1, s[i])
      avl.find_or_insert(&tree2, s1)
    }
    else {
      s2 = step(s2, s[i])
      avl.find_or_insert(&tree2, s2)
    }
  }

  fmt.println("P1:", avl.len(&tree1), "P2:", avl.len(&tree2))
}
