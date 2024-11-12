package d11

import "core:os"
import "core:fmt"
import "core:strings"

increment :: proc(s: ^[]u8) {
  index := len(s) - 1
  s[index] += 1
  for s[index] > 'z' {
    s[index] = 'a'
    index -= 1
    assert(index >= 0)
    s[index] += 1
  }
}

valid :: proc(a: []u8) -> bool {
  contains_straight := proc(a: []u8) -> bool {
    for i in 0..<len(a) - 2 {
      if a[i] + 1 == a[i + 1] && a[i] + 2 == a[i + 2] do return true
    }

    return false
  }

  contains_two_pairs := proc(a: []u8) -> bool {
    for i in 0..<len(a) - 1 {
      first_pair := a[i] == a[i + 1]
      if first_pair {
        for j in i + 2..<len(a) - 1 {
          second_pair := a[j] == a[j + 1]
          if second_pair && a[i] != a[j] do return true
        }
      }
    }

    return false
  }

  contains_safe_letters := proc(a: []u8) -> bool {
    for c in a {
      if c == 'i' || c == 'o' || c == 'l' do return false
    }

    return true
  }

  return contains_straight(a) && contains_two_pairs(a) && contains_safe_letters(a)
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  data = data[:len(data) - 1]

  for !valid(data) do increment(&data)

  // Copy the data for the P1 answer.
  p1_data := make([]u8, len(data))
  defer delete(p1_data)
  copy(p1_data, data)
  p1 := string(p1_data)

  increment(&data)
  for !valid(data) do increment(&data)
  p2 := string(data)

  fmt.println("P1:", p1, "P2:", p2)
}
