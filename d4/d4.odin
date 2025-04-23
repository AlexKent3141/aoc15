package d4

import "core:os"
import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:crypto/hash"

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  start := string(data)

  digest := make([]byte, hash.DIGEST_SIZES[hash.Algorithm.Insecure_MD5])
  defer delete(digest)

  buf: [100]u8
  suffix := -1
  p1: Maybe(int) = nil
  p2: int
  for {
    suffix += 1
    entries := []string { start[0:len(start)-1], strconv.itoa(buf[:], suffix) }
    next := strings.concatenate(entries)

    h := hash.hash(hash.Algorithm.Insecure_MD5, next, digest)

    // Check the prefix.
    // We need to check this at the nibble level (i.e. first 5 nibbles are zero).
    // Break it down into the first 2 bytes + the remaining high part of the next byte.
    if slice.all_of(h[:2], 0) && h[2] >> 4 == 0 {
      if p1 == nil {
        p1 = suffix
      }

      // Check the next nibble for P2.
      if h[2] & 0xF == 0 {
        p2 = suffix
        break
      }
    }
  }

  fmt.println("P1:", p1, "P2:", p2)
}
