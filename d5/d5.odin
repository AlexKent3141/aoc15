package d5

import "core:os"
import "core:fmt"
import "core:slice"
import "core:strings"

VOWELS :: []u8 { 'a', 'e', 'i', 'o', 'u' }
NAUGHTY_PAIRS :: []string { "ab", "cd", "pq", "xy" }

Naughty :: enum {
  NaughtyPair,
  AtLeast3Vowels,
  DupePair,
  UnoverlappingDupePair,
  DupeWithLetterBetween
}

NaughtySet :: bit_set[Naughty]

is_nice :: proc(s: string, criteria: NaughtySet) -> bool {

  if Naughty.NaughtyPair in criteria {
    for bad in NAUGHTY_PAIRS {
      if strings.contains(s, bad) do return false
    }
  }

  vowel_count := 0
  dupe_count := 0
  unoverlapping_dupe_count := 0
  dupe_with_space_count := 0

  for i in 0..<len(s) {
    c := s[i]
    if slice.count(VOWELS, c) > 0 do vowel_count += 1
    if i < len(s) - 1 {
      if c == s[i + 1] do dupe_count += 1

      pair_str := string(s[i:i+2])
      if strings.contains(s[i+2:], pair_str) do unoverlapping_dupe_count += 1
    }
    if i < len(s) - 2 do dupe_with_space_count += cast(int)(c == s[i + 2])
  }

  vowels_satisfied := vowel_count >= 3 || !(Naughty.AtLeast3Vowels in criteria)
  dupes_satisfied := dupe_count >= 1 || !(Naughty.DupePair in criteria)
  unoverlapping_dupes_satisfied := unoverlapping_dupe_count > 0 ||
    !(Naughty.UnoverlappingDupePair in criteria)
  dupes_with_space_satisfied := dupe_with_space_count > 0 ||
    !(Naughty.DupeWithLetterBetween in criteria)

  return vowels_satisfied &&
         dupes_satisfied &&
         unoverlapping_dupes_satisfied &&
         dupes_with_space_satisfied
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)
  p1_criteria: NaughtySet = { .NaughtyPair, .AtLeast3Vowels, .DupePair }
  p2_criteria: NaughtySet = { .UnoverlappingDupePair, .DupeWithLetterBetween }

  nice_total1 := 0
  nice_total2 := 0

  for line in strings.split_lines_iterator(&s) {
    if is_nice(line, p1_criteria) do nice_total1 += 1
    if is_nice(line, p2_criteria) do nice_total2 += 1
  }

  fmt.println("P1:", nice_total1, "P2:", nice_total2)
}
