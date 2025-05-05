package d10

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:unicode"

Group :: struct {
  multiplier, val: int
}

make_groups :: proc(s: string) -> [dynamic]Group {
  groups := make([dynamic]Group)
  count := 0
  prev: Maybe(rune)
  for c in s {
    if c == prev || prev == nil do count += 1
    else {
      append(&groups, Group { multiplier = count, val = cast(int)prev.? - 48 })
      count = 1
    }

    prev = c
  }

  if unicode.is_number(prev.?) {
    append(&groups, Group { multiplier = count, val = cast(int)prev.? - 48 })
  }

  return groups
}

groups_len :: proc(groups: []Group) -> int {
  total := 0
  for g in groups {
    total += g.multiplier
  }

  return total
}

look_and_say :: proc(groups: [dynamic]Group, next: ^[dynamic]Group) {
  mul := 0
  prev: Maybe(int)
  for &g in groups {
    if prev == nil || g.multiplier == prev do mul += 1
    else {
      #force_inline append(next, Group { multiplier = mul, val = prev.? })
      mul = 1
    }

    prev = g.multiplier

    if g.val == prev do mul += 1
    else {
      #force_inline append(next, Group { multiplier = mul, val = prev.? })
      mul = 1
    }

    prev = g.val
  }

  append(next, Group { multiplier = mul, val = prev.? })
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)
  s = s[:len(s) - 1] // Remove the trailing newline char

  groups := make_groups(s)
  defer delete(groups)
  next := make([dynamic]Group)
  defer delete(next)

  p1, p2: int
  for i in 1..=50 {
    look_and_say(groups, &next)
    if i == 40 do p1 = groups_len(next[:])
    if i == 50 do p2 = groups_len(next[:])

    // Swap the buffers ready for the next iteration.
    tmp := groups
    groups = next
    next = tmp

    clear(&next)
  }

  fmt.println("P1:", p1, "P2:", p2)
}
