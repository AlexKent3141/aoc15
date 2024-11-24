package d21

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:mem"

Item :: struct {
  name: string,
  cost, damage, armor: int
}

weapons :: []Item {
  Item { name = "Dagger",     cost = 8,  damage = 4, armor = 0 },
  Item { name = "Shortsword", cost = 10, damage = 5, armor = 0 },
  Item { name = "Warhammer",  cost = 25, damage = 6, armor = 0 },
  Item { name = "Longsword",  cost = 40, damage = 7, armor = 0 },
  Item { name = "Greataxe",   cost = 74, damage = 8, armor = 0 }
}

armor :: []Item {
  Item { name = "Leather",    cost = 13,  damage = 0, armor = 1 },
  Item { name = "Chainmail",  cost = 31,  damage = 0, armor = 2 },
  Item { name = "Splintmail", cost = 53,  damage = 0, armor = 3 },
  Item { name = "Bandedmail", cost = 75,  damage = 0, armor = 4 },
  Item { name = "Platemail",  cost = 102, damage = 0, armor = 5 }
}

rings :: []Item {
  Item { name = "Damage +1",  cost = 25,  damage = 1, armor = 0 },
  Item { name = "Damage +2",  cost = 50,  damage = 2, armor = 0 },
  Item { name = "Damage +3",  cost = 100, damage = 3, armor = 0 },
  Item { name = "Defense +1", cost = 20,  damage = 0, armor = 1 },
  Item { name = "Defense +2", cost = 40,  damage = 0, armor = 2 },
  Item { name = "Defense +3", cost = 80,  damage = 0, armor = 3 }
}

Agent_Stats :: struct {
  hit_points, damage, armor, cost: int
}

Combination_Iterator :: struct($T: typeid, $M: int) {
  elements: []T,
  current: [M]T,
  index: [M]int,
  valid: bool
}

make_combination_iterator :: proc(
  elements: []$T,
  $M: int) -> Combination_Iterator(T, M) {

  it := Combination_Iterator(T, M){}
  it.elements = elements
  it.valid = M > 0 && len(elements) > 0

  for i in 0..<M do it.index[i] = i

  return it
}

combinate :: proc(it: ^Combination_Iterator($T, $M)) -> (c: [M]T, ok: bool) {
  if !it.valid do return it.current, false

  // Update the current combination based on the index array.
  for i in 0..<M do it.current[i] = it.elements[it.index[i]]

  // Generate the next combination.
  for i := M - 1; i >= 0; i -= 1 {
    if it.index[i] < len(it.elements) - (M - i) {
      it.index[i] += 1
      for j in i + 1..<M {
        it.index[j] = it.index[j - 1] + 1
      }

      return it.current, true
    }
  }

  // If we reach here then we've exhausted all combinations.
  it.valid = false

  return it.current, false
}

stack_to_dynamic :: proc($M: int, c: [M]Item, allocator: mem.Allocator) -> [dynamic]Item {
  d := make([dynamic]Item, allocator = allocator)
  for i in c do append(&d, i)
  return d
}

accumulate_combinations :: proc(
  $M: int,
  group: []Item,
  out: ^[dynamic][dynamic]Item,
  allocator: mem.Allocator) {

  it := make_combination_iterator(group, M)

  c, ok := combinate(&it)
  for ok {
    append(out, stack_to_dynamic(M, c, allocator))
    c, ok = combinate(&it)
  }

  append(out, stack_to_dynamic(M, c, allocator))
}

create_agent :: proc(weapon_combo, armor_combo, ring_combo: [dynamic]Item) -> Agent_Stats {
  agent := Agent_Stats{}
  for w in weapon_combo {
    agent.damage += w.damage
    agent.cost += w.cost
  }
  for a in armor_combo {
    agent.armor += a.armor
    agent.cost += a.cost
  }
  for r in ring_combo {
    agent.damage += r.damage
    agent.armor += r.armor
    agent.cost += r.cost
  }

  return agent
}

player_wins :: proc(player, boss: Agent_Stats) -> bool {
  player := player
  boss := boss

  for {
    // Do player move.
    damage_dealt := max(1, player.damage - boss.armor)
    boss.hit_points -= damage_dealt
    if boss.hit_points <= 0 do return true

    // Do boss move.
    damage_dealt = max(1, boss.damage - player.armor)
    player.hit_points -= damage_dealt
    if player.hit_points <= 0 do return false
  }
}

main :: proc() {

  // Setup arena memory.
  buf := make([]u8, 1000000)
  defer delete(buf)

  a: mem.Arena
  mem.arena_init(&a, buf)

  alloc := mem.arena_allocator(&a)

  data := os.read_entire_file("input.txt", allocator = alloc) or_else os.exit(1)

  s := string(data)

  boss: Agent_Stats

  for row in strings.split_lines_iterator(&s) {
    tokens := strings.split(row, ":", allocator = alloc)
    if tokens[0] == "Hit Points" {
      boss.hit_points = strconv.atoi(strings.trim(tokens[1], " "))
    }
    else if tokens[0] == "Damage" {
      boss.damage = strconv.atoi(strings.trim(tokens[1], " "))
    }
    else if tokens[0] == "Armor" {
      boss.armor = strconv.atoi(strings.trim(tokens[1], " "))
    }
  }

  // Generate all of the possible combinations for each item type.
  weapon_combos := make([dynamic][dynamic]Item, allocator = alloc)
  accumulate_combinations(1, weapons, &weapon_combos, allocator = alloc)

  armor_combos := make([dynamic][dynamic]Item, allocator = alloc)
  append(&armor_combos, make([dynamic]Item)) // 0 armor
  accumulate_combinations(1, armor, &armor_combos, allocator = alloc)

  ring_combos := make([dynamic][dynamic]Item, allocator = alloc)
  append(&ring_combos, make([dynamic]Item)) // 0 rings
  accumulate_combinations(1, rings, &ring_combos, allocator = alloc)
  accumulate_combinations(2, rings, &ring_combos, allocator = alloc)

  // Iterate over all item combinations and find the cheapest path to victory.
  cheapest := 1000000
  most_expensive := 0
  for w in weapon_combos {
    for a in armor_combos {
      for r in ring_combos {
        player := create_agent(w, a, r)
        player.hit_points = 100

        if player.cost < cheapest && player_wins(player, boss) {
          cheapest = player.cost
        }

        if player.cost > most_expensive && !player_wins(player, boss) {
          most_expensive = player.cost
        }
      }
    }
  }

  fmt.println("P1:", cheapest, "P2:", most_expensive)
}
