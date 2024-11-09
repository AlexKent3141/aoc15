package d7

import "core:strconv"
import "core:os"
import "core:fmt"
import "core:strings"

Operation :: enum {
  RAW_SIGNAL,
  SIGNAL,
  NOT,
  LSHIFT,
  RSHIFT,
  AND,
  OR
}

id_from_str :: proc(s: string) -> int {
  id := 0
  for c in s {
    id <<= 8
    id += int(c)
  }

  return id
}

Node :: struct {
  id: int,
  value: Maybe(u16),
  input_id1, input_id2: Maybe(int),
  op: Operation,
  arg: u16
}

init_node :: proc(id: int, n: ^Node, tokens: []string) {
  n^.id = id

  parse_binary_op :: proc(op: Operation, n: ^Node, tokens: []string) {
    n^.op = op
    num, ok := strconv.parse_int(tokens[0])
    if ok do n^.arg = u16(num)
    else do n^.input_id1 = id_from_str(tokens[0])
    num, ok = strconv.parse_int(tokens[2])
    if ok do n^.arg = u16(num)
    else do n^.input_id2 = id_from_str(tokens[2])
  }

  if tokens[0] == "NOT" {
    n^.op = Operation.NOT
    n^.input_id1 = id_from_str(tokens[1])
  }
  else if (tokens[1] == "->") {
    num, ok := strconv.parse_int(tokens[0])
    if ok {
      n^.op = Operation.RAW_SIGNAL
      n^.value = u16(num)
    }
    else {
      n^.op = Operation.SIGNAL
      n^.input_id1 = id_from_str(tokens[0])
    }
  }
  else if (tokens[1] == "LSHIFT") {
    n^.op = Operation.LSHIFT
    n^.input_id1 = id_from_str(tokens[0])
    n^.arg = u16(strconv.atoi(tokens[2]))
  }
  else if (tokens[1] == "RSHIFT") {
    n^.op = Operation.RSHIFT
    n^.input_id1 = id_from_str(tokens[0])
    n^.arg = u16(strconv.atoi(tokens[2]))
  }
  else if (tokens[1] == "AND") do parse_binary_op(Operation.AND, n, tokens)
  else do parse_binary_op(Operation.OR, n, tokens)
}

// Recursively evaluate the value of the specified node.
eval :: proc(n: ^Node, nodes: ^[]Node) -> u16 {

  if n^.value != nil do return n^.value.?

  id1 := n^.input_id1
  id2 := n^.input_id2

  switch n^.op {
  case Operation.RAW_SIGNAL:
  case Operation.SIGNAL:
    n^.value = eval(&nodes^[id1.?], nodes)
  case Operation.NOT:
    n^.value = ~eval(&nodes^[id1.?], nodes)
  case Operation.LSHIFT:
    val := eval(&nodes^[id1.?], nodes)
    n^.value = val << uint(n^.arg)
  case Operation.RSHIFT:
    n^.value = eval(&nodes^[id1.?], nodes) >> uint(n^.arg)
  case Operation.AND:
    if id1 != nil && id2 != nil {
      n^.value = eval(&nodes^[id1.?], nodes) & eval(&nodes^[id2.?], nodes)
    }
    else if id1 != nil do n^.value = eval(&nodes^[id1.?], nodes) & n^.arg
    else do n^.value = n^.arg & eval(&nodes^[id2.?], nodes)

  case Operation.OR:
    if id1 != nil && id2 != nil {
      n^.value = eval(&nodes^[id1.?], nodes) | eval(&nodes^[id2.?], nodes)
    }
    else if id1 != nil do n^.value = eval(&nodes^[id1.?], nodes) | n^.arg
    else do n^.value = n^.arg | eval(&nodes^[id2.?], nodes)
  }

  return n^.value.?
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  nodes := make([]Node, 256 * 256)
  defer delete(nodes)

  for line in strings.split_lines_iterator(&s) {
    tokens := strings.split(line, " ")
    id := id_from_str(tokens[len(tokens) - 1])
    init_node(id, &nodes[id], tokens)
  }

  id := id_from_str("a")
  p1_val := eval(&nodes[id], &nodes)

  // Reset gates.
  for id in 0..< 256 * 256 {
    n: ^Node = &nodes[id]
    if n^.op != Operation.RAW_SIGNAL do n^.value = nil
  }

  // Change "b" input.
  id = id_from_str("b")
  nodes[id].value = p1_val

  id = id_from_str("a")
  p2_val := eval(&nodes[id], &nodes)
  fmt.println("P1:", p1_val, "P2:", p2_val)
}
