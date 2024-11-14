package d17

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:slice"

N :: 150

count_combos :: proc(
  volumes, solution_counts: []int,
  current_index, current_sum, num_containers_used: int) -> int {

  if current_sum == N {
    solution_counts[num_containers_used] += 1
    return 1
  }

  if current_sum > N do return 0
  if current_index >= len(volumes) do return 0

  // Consider more options.
  combos := 0
  for index in current_index..<len(volumes) {
    next_sum := current_sum + volumes[index]
    combos += count_combos(
      volumes, solution_counts, index + 1, next_sum, num_containers_used + 1)
  }

  return combos
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  volumes := make([dynamic]int)
  defer delete(volumes)

  for line in strings.split_lines_iterator(&s) do append(&volumes, strconv.atoi(line))

  solution_counts := make([]int, len(volumes))
  defer delete(solution_counts)

  p1 := count_combos(volumes[:], solution_counts[:], 0, 0, 0)
  p2 := slice.filter(solution_counts[:], proc(val: int) -> bool { return val > 0 })[0]

  fmt.println("P1:", p1, "P2:", p2)
}
