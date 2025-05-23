import gleam/list
import gleeunit
import gleeunit/should
import rexen
import rexen/nfa/machine

pub fn main() {
  gleeunit.main()
}

pub fn compute_test() {
  let assert Ok(nfa) = rexen.new("(a*b*)c(d|e)")
  compute_loop(
    nfa,
    ["abcd", "abce", "aabbbcd", "aaaabbbbce", "bc", "bceeee"],
    [],
  )
  |> should.equal([True, True, True, True, False, False])
}

fn compute_loop(
  nfa: machine.NFA,
  input: List(String),
  output: List(Bool),
) -> List(Bool) {
  case input {
    [] -> output
    [str, ..rest] -> {
      compute_loop(nfa, rest, list.append(output, [rexen.compute(nfa, str)]))
    }
  }
}
