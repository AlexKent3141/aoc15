package d20

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "base:intrinsics"

LIMIT :: 1000000

sieve :: proc(target_sum: int) -> (p1_answer, p2_answer: int, ok: bool) {
  divisor_sums_p1 := make([]int, LIMIT)
  defer delete(divisor_sums_p1)
  divisor_sums_p2 := make([]int, LIMIT)
  defer delete(divisor_sums_p2)

  for d in 1..<LIMIT {
    // Update p1 sums.
    j := d
    for j < LIMIT {
      divisor_sums_p1[j] += 10 * d
      j += d
    }

    // Update p2 sums.
    j = d
    for _ in 0..<50 {
      if j >= LIMIT do break
      divisor_sums_p2[j] += 11 * d
      j += d
    }
  }

  p1, p2: Maybe(int)
  for i in 0..<LIMIT {
    if p1 == nil && divisor_sums_p1[i] >= target_sum do p1 = i
    if p2 == nil && divisor_sums_p2[i] >= target_sum do p2 = i
  }

  if p1 != nil && p2 != nil do return p1.?, p2.?, true

  return 0, 0, false
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  target := strconv.atoi(s)

  p1, p2, ok := sieve(target)
  if !ok {
    fmt.println("Could not find solution")
    os.exit(1)
  }

  fmt.println("P1:", p1, "P2:", p2)
}
