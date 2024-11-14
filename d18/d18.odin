package d18

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:slice"

N :: 100

count_on_neighbours :: proc(x, y: int, grid: [N * N]bool) -> int {
  on := 0
  if x > 0 do on += int(grid[x - 1 + N * y])
  if x < N - 1 do on += int(grid[x + 1 + N * y])
  if y > 0 do on += int(grid[x + N * (y - 1)])
  if y < N - 1 do on += int(grid[x + N * (y + 1)])
  if x > 0 && y > 0 do on += int(grid[x - 1 + N * (y - 1)])
  if x > 0 && y < N - 1 do on += int(grid[x - 1 + N * (y + 1)])
  if x < N - 1 && y > 0 do on += int(grid[x + 1 + N * (y - 1)])
  if x < N - 1 && y < N - 1 do on += int(grid[x + 1 + N * (y + 1)])

  return on 
}

step :: proc(src: [N * N]bool, dst: ^[N * N]bool) {
  for x in 0..<N {
    for y in 0..<N {
      n := count_on_neighbours(x, y, src)
      if src[x + N * y] do dst^[x + N * y] = n == 2 || n == 3
      else do dst^[x + N * y] = n == 3
    }
  }
}

set_corners_on :: proc(grid: ^[N * N]bool) {
  grid^[0] = true
  grid^[N - 1] = true
  grid^[N * (N - 1)] = true
  grid^[N * N - 1] = true
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  // Keep two grids for each problem part and switch between them on each iteration.
  grid1: [2][N * N]bool
  grid2: [2][N * N]bool

  row_index := 0
  for row in strings.split_lines_iterator(&s) {
    for c, i in row {
      grid1[0][N * row_index + i] = c == '#'
      grid2[0][N * row_index + i] = c == '#'
    }

    row_index += 1
  }

  set_corners_on(&grid2[0])

  src_index := 0
  for _ in 1..=100 {
    step(grid1[src_index], &grid1[1 - src_index])
    step(grid2[src_index], &grid2[1 - src_index])

    // Ensure corners are on in the destination grid for P2.
    set_corners_on(&grid2[1 - src_index])

    src_index = 1 - src_index
  }

  p1 := slice.count(grid1[src_index][:], true)
  p2 := slice.count(grid2[src_index][:], true)

  fmt.println("P1:", p1, "P2:", p2)
}
