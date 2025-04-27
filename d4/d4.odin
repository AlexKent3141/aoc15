package d4

import "core:crypto/hash"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:thread"

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  start := string(data)
  start = start[0:len(start) - 1]

  suffix := 0
  p1: Maybe(int) = nil
  p2: Maybe(int) = nil

  Thread_Data :: struct {
    prefix: string,
    start_suffix: int,
    p1: int,
    p2: int
  }

  for p1 == nil || p2 == nil {
    // Spawn tasks for the next 10000 attempts split into 8.
    NUM_TASKS :: 16
    STEP :: 400000
    PER_TASK :: STEP / NUM_TASKS

    task_suffixes := make([]Thread_Data, NUM_TASKS)
    defer delete(task_suffixes)

    task_suffixes[0] = Thread_Data { start, suffix, 0, 0 }
    for n in 1..<NUM_TASKS {
      task_suffixes[n] = Thread_Data { start, task_suffixes[n - 1].start_suffix + PER_TASK, 0, 0 }
    }

    task_proc := proc(data: ^Thread_Data) {
      buf := [100]u8{}
      digest := make([]byte, hash.DIGEST_SIZES[hash.Algorithm.Insecure_MD5])
      defer delete(digest)

      for suffix in data^.start_suffix..<data^.start_suffix + PER_TASK {
        entries := []string { data^.prefix, strconv.itoa(buf[:], suffix) }
        next := strings.concatenate(entries)
        defer delete(next)
        h := hash.hash(hash.Algorithm.Insecure_MD5, next, digest)

        // Check the prefix.
        // We need to check this at the nibble level (i.e. first 5 nibbles are zero).
        // Break it down into the first 2 bytes + the remaining high part of the next byte.
        if slice.all_of(h[:2], 0) && h[2] >> 4 == 0 {
          if data^.p1 == 0 {
            data^.p1 = suffix
          }

          // Check the next nibble for P2.
          if h[2] & 0xF == 0 && data^.p2 == 0 {
            data^.p2 = suffix
            break
          }
        }
      }
    }

    tasks := make([]^thread.Thread, NUM_TASKS)
    defer {
      for t in tasks do thread.destroy(t)
      delete(tasks)
    }

    for n in 0..<NUM_TASKS {
      tasks[n] = thread.create_and_start_with_poly_data(&task_suffixes[n], task_proc)
    }

    for t in tasks {
      thread.join(t)
    }

    // If any of the tasks found the solution then store the lowest one.
    for data in task_suffixes {
      if data.p1 != 0 && (p1 == nil || data.p1 < p1.?) {
        p1 = data.p1
      }
      if data.p2 != 0 && (p2 == nil || data.p2 < p2.?) {
        p2 = data.p2
      }
    }

    suffix += STEP
  }

  fmt.println("P1:", p1, "P2:", p2)
}
