package d8

import "core:os"
import "core:fmt"
import "core:strings"

memory_size :: proc(s: string) -> int {
  count := 0

  // Iterate avoiding enclosing quotes.
  i := 1
  for i < len(s) - 1 {
    // Skip the rest of the escape sequence.
    if s[i] == '\\' {
      if s[i + 1] == 'x' do i += 4
      else do i += 2
    }
    else do i += 1

    count += 1
  }

  return count
}

encoded_size :: proc(s: string) -> int {
  count := 2 // Quotes around the encoded string

  for c in s {
    if c == '\\' || c == '\"' do count += 2
    else do count += 1
  }

  return count
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  memory_count := 0
  literals_count := 0
  encoded_count := 0

  for line in strings.split_lines_iterator(&s) {
    memory_count += memory_size(line)
    literals_count += len(line)
    encoded_count += encoded_size(line)
  }

  fmt.println("P1", literals_count - memory_count, "P2", encoded_count - literals_count)
}
