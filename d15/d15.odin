package d15

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:slice"

Ingredient :: [5]int

assess :: proc(a, b, c, d: int, ingredients: []Ingredient) -> (score: int, calories: int) {

  total := a * ingredients[0] + b * ingredients[1] + c * ingredients[2] + d * ingredients[3]

  if slice.any_of_proc(total[:4], proc(n: int) -> bool { return n < 0 }) {
     return 0, total[4]
  }

  return total[0] * total[1] * total[2] * total[3], total[4]
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  ingredients := make([dynamic]Ingredient)
  defer delete(ingredients)

  for line in strings.split_lines_iterator(&s) {
    tokens := strings.split(line, " ")

    append(&ingredients, Ingredient {
      strconv.atoi(tokens[2]),
      strconv.atoi(tokens[4]),
      strconv.atoi(tokens[6]),
      strconv.atoi(tokens[8]),
      strconv.atoi(tokens[10])
    })
  }

  assert(len(ingredients) == 4)

  // Need to generate each possible distribution of ingredients.
  // The total ingredients should be 100.
  p1, p2 := 0, 0
  for a in 0..=100 {
    for b in 0..=100 {
      if a + b > 100 do break
      for c in 0..=100 {
        if a + b + c > 100 do break
        d := 100 - a - b - c

        // Assess this combo.
        score, calories := assess(a, b, c, d, ingredients[:])

        p1 = max(p1, score)

        if calories == 500 do p2 = max(p2, score)
      }
    }
  }

  fmt.println("P1:", p1, "P2:", p2)
}
