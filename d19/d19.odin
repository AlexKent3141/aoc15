package d19

import "core:os"
import "core:fmt"
import "core:strings"
import "core:slice"
import "core:container/avl"
import "core:container/priority_queue"
import "base:runtime"

Mapping :: struct {
  from, to: string
}

create_replaced :: proc(
  base: string,
  mapping: Mapping,
  loc: int) -> string {

  from := mapping.from
  to := mapping.to

  // Create the replaced string.
  builder := strings.Builder{}
  strings.builder_init(&builder)
  strings.write_string(&builder, base[:loc])
  strings.write_string(&builder, to)
  strings.write_string(&builder, base[loc+len(from):])

  return strings.to_string(builder)
}

generate_neighbours :: proc(
  base_molecule: string,
  mappings: []Mapping,
  molecules: ^[dynamic]string,
  start, end: int) {

  // Consider replacments in each location.
  for mapping in mappings {
    from := mapping.from
  //for i in 0..<len(base_molecule) {
    for i in start..<min(end, len(base_molecule)) {
      // Is the replacement string here?
      if i < len(base_molecule) - len(from) + 1 &&
        slice.cmp(base_molecule[i:i+len(from)], from) == slice.Ordering.Equal {

        s := create_replaced(base_molecule, mapping, i)
        append(molecules, s)
      }
    }
  }
}

p2_solve :: proc(start, target: string, mappings: []Mapping) -> int {

  AS_Node :: struct {
    current: string,
    num_steps, prefix_len, priority: int,
  }

  calculate_priority := proc(source, target: string) -> (prefix_len, priority: int) {
    // Check similarity between the source and target.
    count := 0
    for i in 0..<min(len(source), len(target)) {
      if source[i] != target[i] do break
      count += 1
    }

    // Count measures the similarly. Now subtract the difference.
    max_diff := max(len(source) - count, len(target) - count)

    return count, count - max_diff
  }

  todo: priority_queue.Priority_Queue(AS_Node)
  priority_queue.init(
    &todo,
    less = proc(a, b: AS_Node) -> bool { return a.priority > b.priority },
    swap = proc(q: []AS_Node, i, j: int) { slice.swap(q, i, j) })

  defer priority_queue.destroy(&todo)

  prefix_len, priority := calculate_priority(start, target)
  priority_queue.push(&todo, AS_Node { start, 0, prefix_len, priority })

  neighbours := make([dynamic]string)
  defer delete(neighbours)

  done: avl.Tree(string)
  avl.init(&done)
  defer avl.destroy(&done)

  best_priority := -100000

  for priority_queue.len(todo) > 0 {
    s := priority_queue.pop(&todo)

    if s.current == target do return s.num_steps

    if s.priority > best_priority {
      fmt.println(s)
      best_priority = s.priority
    }

    clear(&neighbours)

    generate_neighbours(
      s.current,
      mappings,
      &neighbours,
      max(0, s.prefix_len - 2),
      s.prefix_len + 18 )

    for n in neighbours {
      if len(n) > s.prefix_len + 18 do continue

      _, inserted, err := avl.find_or_insert(&done, n)
      assert(err == runtime.Allocator_Error.None)

      if inserted {
        prefix_len, priority := calculate_priority(n, target)

        priority_queue.push(
          &todo,
          AS_Node { n, s.num_steps + 1, prefix_len, priority })
      }
    }
  }

  assert(false)
  return 0
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)

  s := string(data)

  mappings := make([dynamic]Mapping)
  defer delete(mappings)

  molecule: Maybe(string) = nil
  for row in strings.split_lines_iterator(&s) {
    if len(row) == 0 do continue

    tokens := strings.split(row, " ")
    if len(tokens) == 1 do molecule = tokens[0]
    else do append(&mappings, Mapping { tokens[0], tokens[2] })
  }

  assert(molecule != nil)

  {
    neighbours := make([dynamic]string)
    defer delete(neighbours)

    generate_neighbours(molecule.?, mappings[:], &neighbours, 0, len(molecule.?))

    options: avl.Tree(string)
    avl.init(&options)
    defer avl.destroy(&options)

    for n in neighbours do avl.find_or_insert(&options, n)

    fmt.println("P1:", avl.len(&options))
  }

  // Strategy for P2.
  // A* mate
  p2 := p2_solve("e", molecule.?, mappings[:])
  fmt.println("P2:", p2)
}
