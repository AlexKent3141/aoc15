package d19

import "core:os"
import "core:fmt"
import "core:strings"
import "core:slice"
import "core:container/avl"
import "core:container/priority_queue"
import "base:runtime"

Mapping :: struct {
  from: u8,
  to: string
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
  strings.write_string(&builder, base[loc+1:])

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
    for i in start..<min(end, len(base_molecule)) {
      if i < len(base_molecule) &&
        base_molecule[i] == from {

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
      best_priority = s.priority
    }

    clear(&neighbours)

    generate_neighbours(
      s.current,
      mappings,
      &neighbours,
      max(0, s.prefix_len - 2),
      s.prefix_len + 1)

    for n in neighbours {
      if len(n) > s.prefix_len + 11 {
        delete(n)
        continue
      }

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

  atom_labels := make(map[string](u8))
  defer delete(atom_labels)
  atom_labels["Al"] = 'a'
  atom_labels["Th"] = 'b'
  atom_labels["F"] = 'c'
  atom_labels["Rn"] = 'd'
  atom_labels["Ar"] = 'e'
  atom_labels["B"] = 'f'
  atom_labels["Ti"] = 'g'
  atom_labels["Ca"] = 'h'
  atom_labels["P"] = 'i'
  atom_labels["Si"] = 'j'
  atom_labels["Y"] = 'k'
  atom_labels["Mg"] = 'l'
  atom_labels["C"] = 'm'
  atom_labels["H"] = 'n'
  atom_labels["N"] = 'o'
  atom_labels["O"] = 'p'
  atom_labels["e"] = 'q'

  relabel := proc(label_map: map[string](u8), s: string) -> string {
    builder := strings.Builder{}
    strings.builder_init(&builder)

    for i := 0; i < len(s); {
      word, ok := strings.substring(s, i, i + 2)
      if ok && word in label_map {
        strings.write_byte(&builder, label_map[word])
        i += 2
      }
      else {
        word, ok = strings.substring(s, i, i + 1)
        strings.write_byte(&builder, label_map[word])
        i += 1
      }
    }

    return strings.to_string(builder)
  }

  data := os.read_entire_file("input.txt") or_else os.exit(1)

  s := string(data)

  mappings := make([dynamic]Mapping)
  defer delete(mappings)

  molecule: Maybe(string) = nil
  for row in strings.split_lines_iterator(&s) {
    if len(row) == 0 do continue

    tokens := strings.split(row, " ")
    if len(tokens) == 1 do molecule = relabel(atom_labels, tokens[0])
    else do append(
      &mappings,
      Mapping { relabel(atom_labels, tokens[0])[0], relabel(atom_labels, tokens[2]) })
  }

  assert(molecule != nil)

  p1: int

  {
    neighbours := make([dynamic]string)
    defer delete(neighbours)

    generate_neighbours(molecule.?, mappings[:], &neighbours, 0, len(molecule.?))

    options: avl.Tree(string)
    avl.init(&options)
    defer avl.destroy(&options)

    for n in neighbours do avl.find_or_insert(&options, n)

    p1 = avl.len(&options)
  }

  // Strategy for P2.
  // A* mate
  start_bytes := []u8 { atom_labels["e"] }

  p2 := p2_solve(cast(string)start_bytes, molecule.?, mappings[:])
  fmt.println("P1:", p1, "P2:", p2)
}
