package d6

import "core:strconv"
import "core:os"
import "core:fmt"
import "core:strings"

WIDTH :: 1000
HEIGHT :: 1000

Location :: struct { x, y: int }

location_from_str :: proc(s: string) -> Location {
  tokens := strings.split(s, ",")
  assert(len(tokens) == 2)
  return { x = strconv.atoi(tokens[0]), y = strconv.atoi(tokens[1]) }
}

act_on_rect :: proc(
  lights: ^[]int,
  corner1, corner2: Location,
  action: proc(s: int) -> int) {

  for y in corner1.y..=corner2.y {
    for x in corner1.x..=corner2.x {
      lights[WIDTH * y + x] = action(lights[WIDTH * y + x])
    }
  }
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  lights_p1 := make([]int, HEIGHT * WIDTH)
  defer delete(lights_p1)
  lights_p2 := make([]int, HEIGHT * WIDTH)
  defer delete(lights_p2)

  for line in strings.split_lines_iterator(&s) {
    tokens := strings.split(line, " ")

    if tokens[0] == "turn" {
      on: bool = tokens[1] == "on"
      from := location_from_str(tokens[2])
      to := location_from_str(tokens[4])

      if on do act_on_rect(&lights_p1, from, to, proc(s: int) -> int { return 1 })
      else  do act_on_rect(&lights_p1, from, to, proc(s: int) -> int { return 0 })

      if on do act_on_rect(&lights_p2, from, to, proc(s: int) -> int { return s + 1 })
      else do act_on_rect(&lights_p2, from, to, proc(s: int) -> int { return max(s - 1, 0) })
    }
    else {
      assert(tokens[0] == "toggle")
      from := location_from_str(tokens[1])
      to := location_from_str(tokens[3])

      act_on_rect(&lights_p1, from, to, proc(s: int) -> int { return s == 1 ? 0 : 1 })
      act_on_rect(&lights_p2, from, to, proc(s: int) -> int { return s + 2 })
    }
  }

  total1 := 0
  total2 := 0
  for y in 0..<HEIGHT {
    for x in 0..<WIDTH {
      total1 += cast(int)(lights_p1[WIDTH * y + x] == 1)
      total2 += lights_p2[WIDTH * y + x]
    }
  }

  fmt.println("P1:", total1, "P2:", total2)
}
