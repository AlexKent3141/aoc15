package d13

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:slice"
import "base:runtime"

happiness :: proc(costs: [$N][$M]int) -> int {
  #assert(N == M)

  // Assess happiness of each permutation.
  indices := [N]int{}
  for i in 0..<N do indices[i] = i

  it := slice.make_permutation_iterator(indices[:])
  defer slice.destroy_permutation_iterator(it)

  best_happiness := 0
  for slice.permute(&it) {
    happiness := 0
    for i in 1..<N {
      happiness += costs[indices[i]][indices[i - 1]]
      happiness += costs[indices[i - 1]][indices[i]]
    }

    happiness += costs[indices[0]][indices[N - 1]]
    happiness += costs[indices[N - 1]][indices[0]]

    best_happiness = max(best_happiness, happiness)
  }

  return best_happiness
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  // Iterate through the first time to assign all of the character IDs.
  data2 := make([]u8, len(data))
  defer delete(data2)
  copy(data2, data)

  s := string(data2)

  latest_id := 0
  name_to_id := make(map[string]int)
  defer delete(name_to_id)

  for line in strings.split_lines_iterator(&s) {
    tokens := strings.split(line[:len(line) - 1], " ")

    name := tokens[0]
    if _, ok := name_to_id[name]; !ok {
      name_to_id[name] = latest_id
      latest_id += 1
    }
  }

  s = string(data)

  costs := [8][8]int{}
  for line in strings.split_lines_iterator(&s) {
    tokens := strings.split(line[:len(line) - 1], " ")

    person1 := tokens[0]
    person2 := tokens[10]

    sign := tokens[2] == "gain" ? 1 : -1
    amount := strconv.atoi(tokens[3])

    costs[name_to_id[person1]][name_to_id[person2]] = sign * amount
  }

  p1 := happiness(costs)

  // Extend the costs and indices for an extra term.
  costs2 := [9][9]int{}
  for i in 0..<8 do runtime.copy_slice(costs2[i][:], costs[i][:])

  p2 := happiness(costs2)

  fmt.println("P1:", p1, "P2:", p2)
}
