package d23

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:testing"

InstructionType :: enum {
  HLF,
  TPL,
  INC,
  JMP,
  JIE,
  JIO
}

Instruction :: struct {
  type: InstructionType,
  register: int,
  offset: int
}

Computer :: struct {
  registers: [2]int,
  instruction_index: int
}

halted :: proc(computer: Computer, instructions: []Instruction) -> bool {
  return computer.instruction_index < 0 ||
         computer.instruction_index >= len(instructions)
}

step :: proc(computer: ^Computer, instructions: []Instruction) {
  i := instructions[computer^.instruction_index]
  switch i.type {
    case InstructionType.HLF:
      computer^.registers[i.register] /= 2
      computer^.instruction_index += 1
    case InstructionType.TPL:
      computer^.registers[i.register] *= 3
      computer^.instruction_index += 1
    case InstructionType.INC:
      computer^.registers[i.register] += 1
      computer^.instruction_index += 1
    case InstructionType.JMP:
      computer^.instruction_index += i.offset
    case InstructionType.JIE:
      val := computer^.registers[i.register]
      computer^.instruction_index += val % 2 == 0 ? i.offset : 1
    case InstructionType.JIO:
      val := computer^.registers[i.register]
      computer^.instruction_index += val == 1 ? i.offset : 1
  }
}

@(test)
basic_program :: proc(t: ^testing.T) {
  computer := Computer{}

  instructions := []Instruction {
    { InstructionType.INC, 0, 0 },
    { InstructionType.JIO, 0, 2 },
    { InstructionType.TPL, 0, 0 },
    { InstructionType.INC, 0, 0 }
  }

  for !halted(computer, instructions) {
    step(&computer, instructions)
  }

  testing.expect(t, computer.registers[0] == 2)
  testing.expect(t, computer.registers[1] == 0)
}

main :: proc() {
  data := os.read_entire_file("input.txt") or_else os.exit(1)
  defer delete(data)

  s := string(data)

  instructions := make([dynamic]Instruction)
  defer delete(instructions)

  for row in strings.split_lines_iterator(&s) {
    i := Instruction{}
    tokens := strings.split(row, " ")
    defer delete(tokens)
    if tokens[0] == "hlf" {
      i.type = InstructionType.HLF
      i.register = tokens[1] == "a" ? 0 : 1
    }
    else if tokens[0] == "tpl" {
      i.type = InstructionType.TPL
      i.register = tokens[1] == "a" ? 0 : 1
    }
    else if tokens[0] == "inc" {
      i.type = InstructionType.INC
      i.register = tokens[1] == "a" ? 0 : 1
    }
    else if tokens[0] == "jmp" {
      i.type = InstructionType.JMP
      i.offset = strconv.atoi(tokens[1])
    }
    else if tokens[0] == "jie" {
      i.type = InstructionType.JIE
      i.register = tokens[1][0] == 'a' ? 0 : 1
      i.offset = strconv.atoi(tokens[2])
    }
    else if tokens[0] == "jio" {
      i.type = InstructionType.JIO
      i.register = tokens[1][0] == 'a' ? 0 : 1
      i.offset = strconv.atoi(tokens[2])
    }

    append(&instructions, i)
  }

  computer := Computer{}
  for !halted(computer, instructions[:]) {
    step(&computer, instructions[:])
  }

  p1 := computer.registers[1]
  
  computer = Computer{}
  computer.registers[0] = 1
  for !halted(computer, instructions[:]) {
    step(&computer, instructions[:])
  }

  p2 := computer.registers[1]

  fmt.println("P1:", p1, "P2:", p2)
}
