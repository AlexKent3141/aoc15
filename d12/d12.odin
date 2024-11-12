package d12

import "core:os"
import "core:fmt"
import "core:encoding/json"

count :: proc(value: json.Value, ignore_red: bool = false) -> (value_total: i64, value_contains_red: bool) {

  total := i64(0)
  contains_red := false

  if a, ok := value.(json.Array); ok {
    for v in a {
      sub_total, _ := count(v, ignore_red)
      total += sub_total
    }
  }
  else if o, ok := value.(json.Object); ok {
    // Need to potentially ignore the whole object.
    object_total := i64(0)
    object_contains_red := false
    for k, v in o {
      sub_total, sub_contains_red := count(v, ignore_red)

      object_total += sub_total
      object_contains_red ||= sub_contains_red
    }

    if !ignore_red || !object_contains_red do total += object_total
  }
  else if n, ok := value.(i64); ok do total += n
  else if s, ok := value.(string); ok do contains_red ||= s == "red"

  return total, contains_red
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  value := json.parse_string(string(data), parse_integers = true) or_else os.exit(1)

  p1, _ := count(value)
  p2, _ := count(value, true)
  fmt.println("P1:", p1, "P2:", p2)
}
