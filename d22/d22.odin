package d22

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:testing"
import "core:container/queue"

Game_State :: struct {
  // Player state.
  player_hit_points, player_mana, player_mana_spent: int,

  // Boss state.
  boss_hit_points, boss_damage: int,

  // Remaining effect turns.
  shield_turns, poison_turns, recharge_turns: int
}

Action :: enum {
  MISSILE,
  DRAIN,
  SHIELD,
  POISON,
  RECHARGE
}

SPELL_COSTS := []int { 53, 73, 113, 173, 229 }

step_effects :: proc(state: ^Game_State) {
  if state.shield_turns > 0 do state.shield_turns -= 1
  if state.poison_turns > 0 {
    state.boss_hit_points -= 3
    state.poison_turns -= 1
  }
  if state.recharge_turns > 0 {
    state.player_mana += 101
    state.recharge_turns -= 1
  }
}

do_player_turn1 :: proc(state: ^Game_State, action: Action) {
  step_effects(state)

  // Do player action.
  switch action {
    case Action.MISSILE:
      state.boss_hit_points -= 4
    case Action.DRAIN:
      state.player_hit_points += 2
      state.boss_hit_points -= 2
    case Action.SHIELD:
      assert(state.shield_turns == 0)
      state.shield_turns = 6
    case Action.POISON:
      assert(state.poison_turns == 0)
      state.poison_turns = 6
    case Action.RECHARGE:
      assert(state.recharge_turns == 0)
      state.recharge_turns = 5
  }

  assert(SPELL_COSTS[action] <= state.player_mana)
  state.player_mana -= SPELL_COSTS[action]
  state.player_mana_spent += SPELL_COSTS[action]
}

do_player_turn2 :: proc(state: ^Game_State, action: Action) {
  state^.player_hit_points -= 1
  if state^.player_hit_points <= 0 do return
  do_player_turn1(state, action)
}

do_boss_turn :: proc(state: ^Game_State) {
  step_effects(state)

  // If boss is dead stop here.
  if state.boss_hit_points <= 0 do return

  // Do boss action.
  player_armor := state.shield_turns > 0 ? 7 : 0
  state.player_hit_points -= max(1, state.boss_damage - player_armor)
}

playable_actions :: proc(state: Game_State, actions: ^[dynamic]Action) {
  if state.player_mana >= SPELL_COSTS[Action.MISSILE] do append(actions, Action.MISSILE)
  if state.player_mana >= SPELL_COSTS[Action.DRAIN] do append(actions, Action.DRAIN)

  if state.player_mana >= SPELL_COSTS[Action.SHIELD] && state.shield_turns <= 1 {
    append(actions, Action.SHIELD)
  }

  if state.player_mana >= SPELL_COSTS[Action.POISON] && state.poison_turns <= 1 {
    append(actions, Action.POISON)
  }

  if state.player_mana >= SPELL_COSTS[Action.RECHARGE] && state.recharge_turns <= 1 {
    append(actions, Action.RECHARGE)
  }
}

@(test)
sample_game1 :: proc(t: ^testing.T) {
  state := Game_State{
    player_hit_points = 10,
    player_mana       = 250,
    boss_hit_points   = 13,
    boss_damage       = 8
  }

  do_player_turn1(&state, Action.POISON)
  do_boss_turn(&state)
  do_player_turn1(&state, Action.MISSILE)
  do_boss_turn(&state)

  testing.expect(t, state.player_hit_points == 2)
  testing.expect(t, state.player_mana == 24)
  testing.expect(t, state.boss_hit_points == 0)
}

@(test)
sample_game2 :: proc(t: ^testing.T) {
  state := Game_State{
    player_hit_points = 10,
    player_mana       = 250,
    boss_hit_points   = 14,
    boss_damage       = 8
  }

  do_player_turn1(&state, Action.RECHARGE)
  do_boss_turn(&state)
  do_player_turn1(&state, Action.SHIELD)
  do_boss_turn(&state)
  do_player_turn1(&state, Action.DRAIN)
  do_boss_turn(&state)
  do_player_turn1(&state, Action.POISON)
  do_boss_turn(&state)
  do_player_turn1(&state, Action.MISSILE)
  do_boss_turn(&state)

  testing.expect(t, state.player_hit_points == 1)
  testing.expect(t, state.player_mana == 114)
  testing.expect(t, state.boss_hit_points == -1)
}

min_mana_cost :: proc(
  initial_state: Game_State,
  actions: ^[dynamic]Action,
  do_player_turn: proc(^Game_State, Action)) -> int {

  min_spent_mana := 1_000_000
  todo := queue.Queue(Game_State){}
  queue.push_back(&todo, initial_state)
  for queue.len(todo) > 0 {
    current := queue.pop_back(&todo)

    if current.player_hit_points <= 0 do continue

    if current.boss_hit_points <= 0 {
      min_spent_mana = min(min_spent_mana, current.player_mana_spent)
      continue
    }

    // Consider playable actions.
    playable_actions(current, actions)
    defer clear(actions)

    for a in actions {
      next := current
      do_player_turn(&next, a)
      do_boss_turn(&next)

      if next.player_mana_spent > min_spent_mana do continue

      queue.push_back(&todo, next)
    }
  }

  return min_spent_mana
}

main :: proc() {

  data := os.read_entire_file("input.txt") or_else os.exit(1)

  s := string(data)

  initial_state := Game_State{player_hit_points = 50, player_mana = 500}

  for row in strings.split_lines_iterator(&s) {
    tokens := strings.split(row, ":")
    if tokens[0] == "Hit Points" {
      initial_state.boss_hit_points = strconv.atoi(strings.trim(tokens[1], " "))
    }
    else if tokens[0] == "Damage" {
      initial_state.boss_damage = strconv.atoi(strings.trim(tokens[1], " "))
    }
  }

  // Plan: A regular BFS should be fine. It will terminate pretty fast: either we'll
  // kill the boss or we will be killed.
  actions := make([dynamic]Action)
  defer delete(actions)

  min_spent_mana1 := min_mana_cost(initial_state, &actions, do_player_turn1)
  min_spent_mana2 := min_mana_cost(initial_state, &actions, do_player_turn2)

  fmt.println("P1:", min_spent_mana1, "P2:", min_spent_mana2)
}
