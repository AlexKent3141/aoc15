package d14

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:strings"

Reindeer :: struct {
  speed, flight_time, rest_time, time_in_state, distance_travelled, lead_count: int,
  flying: bool
}

step :: proc(r: ^Reindeer) {
  r^.time_in_state += 1

  if r^.flying {
    r^.distance_travelled += r^.speed
    if r^.time_in_state == r^.flight_time {
      r^.flying = false
      r^.time_in_state = 0
    }
  }
  else {
    if r^.time_in_state == r^.rest_time {
      r^.flying = true
      r^.time_in_state = 0
    }
  }
}

pick_best_deer :: proc(
  deer: []Reindeer,
  metric: proc(d: Reindeer) -> int) -> ^Reindeer {

  best_score := 0
  best: ^Reindeer
  for &d in deer {
    score := metric(d)
    if score > best_score {
      best_score = score
      best = &d
    }
  }

  return best
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  deer := make([dynamic]Reindeer)
  defer delete(deer)

  for line in strings.split_lines_iterator(&s) {
    tokens := strings.split(line, " ")

    append(&deer, Reindeer {
      speed = strconv.atoi(tokens[3]),
      flight_time = strconv.atoi(tokens[6]),
      rest_time = strconv.atoi(tokens[13]),
      time_in_state = 0,
      distance_travelled = 0,
      lead_count = 0,
      flying = true
    })
  }

  for _ in 0..<2503 {
    for &d in deer do step(&d)

    // Update the leader.
    leader := pick_best_deer(
      deer[:],
      proc(d: Reindeer) -> int { return d.distance_travelled })

    // We can have joint leaders.
    leading_dist := leader^.distance_travelled
    for &d in deer {
      if d.distance_travelled == leading_dist do d.lead_count += 1
    }
  }

  furthest_travelled := pick_best_deer(
    deer[:],
    proc(d: Reindeer) -> int { return d.distance_travelled })

  most_points := pick_best_deer(
    deer[:],
    proc(d: Reindeer) -> int { return d.lead_count })

  fmt.println("P1:", furthest_travelled^.distance_travelled,
              "P2:", most_points^.lead_count)
}
