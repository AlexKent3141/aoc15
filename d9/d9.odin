package d9

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:strings"
import "base:intrinsics"

MAX_NODES :: 20
MAX_DISTANCE :: u32(1000000)

Edge :: struct {
  ends: [2]u32,
  length: u32
}

Node :: struct {
  id: u32,
  edges: [dynamic]Edge
}

Metric :: struct {
  worst_val: u32,
  choose_best: proc(x, y: u32) -> u32
}

best_path_distance :: proc(
  current_id: u32,
  nodes: []Node,
  considered: u32,
  metric: Metric) -> u32 {

  dist := metric.worst_val

  current := &nodes[current_id]
  has_available_edges := false
  for e in current^.edges {
    other_end_id := e.ends[0] == current_id ? e.ends[1] : e.ends[0]

    if considered & (1 << other_end_id) == 0 {
      has_available_edges = true

      next_dist := e.length +
        best_path_distance(
          other_end_id,
          nodes,
          considered | (1 << current_id),
          metric)

       dist = metric.choose_best(dist, next_dist)
    }
  }

  if has_available_edges do return dist
  else {
    // Have we reached all destinations?
    if intrinsics.count_ones(considered) == u32(len(nodes)) - 1 do return 0
    else do return metric.worst_val // Cannot complete the path.
  }
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  latest_id := u32(0)
  location_ids := make(map[string]u32)
  defer delete(location_ids)

  nodes := make([]Node, MAX_NODES)

  for line in strings.split_lines_iterator(&s) {
    tokens := strings.split(line, " ")

    start := tokens[0]
    end := tokens[2]
    length := u32(strconv.atoi(tokens[4]))

    // Insert the locations and assign IDs as needed.
    if !(start in location_ids) {
      location_ids[start] = latest_id
      nodes[latest_id] = Node { latest_id, nil }
      latest_id += 1
    }
    if !(end in location_ids) {
      location_ids[end] = latest_id
      nodes[latest_id] = Node { latest_id, nil }
      latest_id += 1
    }

    // Create the edge and link both nodes.
    start_id := location_ids[start]
    end_id := location_ids[end]
    edge := Edge { [2]u32{ start_id, end_id }, length }

    append(&nodes[start_id].edges, edge)
    append(&nodes[end_id].edges, edge)
  }

  p1_metric := Metric { MAX_DISTANCE, proc(x, y: u32) -> u32{ return min(x, y) } }
  p2_metric := Metric { 0, proc(x, y: u32) -> u32{ return max(x, y) } }

  p1_best := p1_metric.worst_val
  p2_best := p2_metric.worst_val

  for start_id in 0..<latest_id {
    dist := best_path_distance(start_id, nodes[0:latest_id], 0, p1_metric)
    p1_best = p1_metric.choose_best(p1_best, dist)

    dist = best_path_distance(start_id, nodes[0:latest_id], 0, p2_metric)
    p2_best = p2_metric.choose_best(p2_best, dist)
  }

  fmt.println("P1:", p1_best, "P2:", p2_best)
}
