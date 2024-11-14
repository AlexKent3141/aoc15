package d16

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:strings"

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  // Hardcode the machine output.
  out := make(map[string]int)
  defer delete(out)

  out["children"] = 3
  out["cats"] = 7
  out["samoyeds"] = 2
  out["pomeranians"] = 3
  out["akitas"] = 0
  out["vizslas"] = 0
  out["goldfish"] = 5
  out["trees"] = 3
  out["cars"] = 2
  out["perfumes"] = 1

  p1, p2 := 0, 0

  for line in strings.split_lines_iterator(&s) {
    tokens := strings.split(line, " ")

    // Does this line satisfy the Aunt constraints?
    correct_p1_aunt := true
    correct_p2_aunt := true
    for i in 0..<3 {
      key := strings.trim_right(tokens[2 + 2 * i], ":")
      val := strconv.atoi(tokens[3 + 2 * i])

      correct_p1_aunt &&= out[key] == val

      if key == "cats" || key == "trees" {
        correct_p2_aunt &&= out[key] < val
      }
      else if key == "pomeranians" || key == "goldfish" {
        correct_p2_aunt &&= out[key] > val
      }
      else do correct_p2_aunt &&= out[key] == val
    }

    if correct_p1_aunt do p1 = strconv.atoi(strings.trim_right(tokens[1], ":"))
    if correct_p2_aunt do p2 = strconv.atoi(strings.trim_right(tokens[1], ":"))
  }

  fmt.println("P1:", p1, "P2:", p2)
}
