package d24

import "core:os"
import "core:fmt"
import "core:math"
import "core:slice"
import "core:strings"
import "core:strconv"

Combination_Iterator :: struct($T: typeid) {
  m: int,
  elements: []T,
  current: []T,
  index: []int,
  first_call: bool,
  valid: bool
}

make_combination_iterator :: proc(
  elements: []$T,
  m: int) -> Combination_Iterator(T) {

  it := Combination_Iterator(T){}
  it.m = m
  it.elements = elements
  it.current = make([]T, m)
  it.index = make([]int, m)
  it.first_call = true
  it.valid = m > 0 && len(elements) > 0

  for i in 0..<m {
    it.index[i] = i
    it.current[i] = elements[it.index[i]]
  }

  return it
}

delete_combination_iterator :: proc(it: ^Combination_Iterator($T)) {
  delete(it^.current)
  delete(it^.index)
}

combinate :: proc(it: ^Combination_Iterator($T)) -> (c: []T, ok: bool) {
  if !it.valid do return it.current, false

  if it.first_call {
    it.first_call = false
    return it.current, true
  }

  // Generate the next combination.
  for i := it.m - 1; i >= 0; i -= 1 {
    if it.index[i] < len(it.elements) - (it.m - i) {
      it.index[i] += 1
      it.current[i] = it.elements[it.index[i]]
      for j in i + 1..<it.m {
        it.index[j] = it.index[j - 1] + 1
        it.current[j] = it.elements[it.index[j]]
      }

      return it.current, true
    }
  }

  // If we reach here then we've exhausted all combinations.
  it.valid = false

  return it.current, false
}

vals_after_removing_combination :: proc(it: Combination_Iterator($T)) -> []int {
  remaining := make([dynamic]int)

  for i in 0..<len(it.elements) {
    // If this index is not in the indices for the current combination retain
    // this element.
    _, found_index := slice.linear_search(it.index[:], i)
    if !found_index do append(&remaining, it.elements[i])
  }

  return remaining[:]
}

can_fully_partition :: proc(vals: []int, target: int) -> bool {
  if math.sum(vals[:]) == target do return true

  for n := 1; n < len(vals); n += 1 {
    it := make_combination_iterator(vals[:], n)
    defer delete_combination_iterator(&it)

    c, ok := combinate(&it)
    for ok {
      // Does this combo match the target?
      if math.sum(c) == target {
        // Try to partition the remainder.
        remaining := vals_after_removing_combination(it)
        defer delete(remaining)

        if can_fully_partition(remaining[:], target) do return true
      }

      c, ok = combinate(&it)
    }
  }

  return false
}

find_min_quantum_score :: proc(vals: []int, target: int) -> int {
  best_quantum_score := 1_000_000_000_000

  found_smallest := false
  for smallest := 1; smallest < len(vals) && !found_smallest; smallest += 1 {
    it := make_combination_iterator(vals[:], smallest)
    defer delete_combination_iterator(&it)
    c, ok := combinate(&it)
    for ok {
      if math.sum(c[:]) == target {
        // We've found a new candidate for the smallest partition.
        // Can we partition the remaining elements evenly?
        remaining := vals_after_removing_combination(it)
        defer delete(remaining)

        if can_fully_partition(remaining[:], target) {
          score := math.prod(c[:])
          if score < best_quantum_score {
            best_quantum_score = score
          }
        }

        found_smallest = true
      }

      c, ok = combinate(&it)
    }
  }

  return best_quantum_score
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  vals := make([dynamic]int)
  defer delete(vals)

  for row in strings.split_lines_iterator(&s) {
    append(&vals, strconv.atoi(row))
  }

  fmt.println("P1:", find_min_quantum_score(vals[:], math.sum(vals[:]) / 3),
              "P2:", find_min_quantum_score(vals[:], math.sum(vals[:]) / 4))
}
