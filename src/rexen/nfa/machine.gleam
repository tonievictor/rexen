import gleam/dict
import gleam/list
import gleam/set.{type Set}
import gleam/string
import rexen/nfa/state

pub type NFA {
  NFA(
    states: dict.Dict(String, state.State),
    initial_state: String,
    ending_states: List(String),
  )
}

pub fn new() -> NFA {
  NFA(states: dict.new(), initial_state: "", ending_states: [])
}

pub fn set_initial_state(nfa: NFA, state: String) -> NFA {
  NFA(
    states: nfa.states,
    initial_state: state,
    ending_states: nfa.ending_states,
  )
}

pub fn set_ending_states(nfa: NFA, values: List(String)) -> NFA {
  NFA(
    states: nfa.states,
    initial_state: nfa.initial_state,
    ending_states: values,
  )
}

pub fn add_state(nfa: NFA, name: String) -> NFA {
  NFA(
    states: dict.insert(nfa.states, name, state.new(name)),
    initial_state: nfa.initial_state,
    ending_states: nfa.ending_states,
  )
}

pub fn declare_states(nfa: NFA, names: List(String)) -> NFA {
  case names {
    [] -> nfa
    [name, ..rest] -> declare_states(add_state(nfa, name), rest)
  }
}

pub fn add_transition(
  nfa: NFA,
  from: String,
  to: String,
  matcher: state.Matcher,
) -> NFA {
  let assert Ok(from_state) = dict.get(nfa.states, from)
  let assert Ok(_) = dict.get(nfa.states, to)

  let transitions = state.add_transition(from_state.transitions, #(matcher, to))
  let new_state = state.State(name: from_state.name, transitions: transitions)

  NFA(
    states: dict.insert(nfa.states, from, new_state),
    initial_state: nfa.initial_state,
    ending_states: nfa.ending_states,
  )
}

pub type Node {
  Node(index: Int, state: state.State)
}

pub fn evaluate(nfa: NFA, input: String) -> Bool {
  let assert Ok(s) = dict.get(nfa.states, nfa.initial_state)

  let nodes = [Node(0, s)]
  let visited_nodes: Set(Node) = set.new()

  evaluate_loop(nfa, input, nodes, visited_nodes)
}

fn evaluate_loop(
  nfa: NFA,
  input: String,
  nodes: List(Node),
  visited_nodes: Set(Node),
) -> Bool {
  case nodes {
    [] -> False
    [node, ..rest] -> {
      let visited_nodes =
        set.insert(visited_nodes, Node(index: node.index, state: node.state))

      case list.contains(nfa.ending_states, node.state.name) {
        True ->
          case string.length(input) == node.index {
            True -> True
            False -> {
              let char = string.slice(input, node.index, 1)
              let updated_nodes =
                process_transitions(
                  nfa,
                  node.state.transitions,
                  rest,
                  visited_nodes,
                  node,
                  char,
                )

              evaluate_loop(nfa, input, updated_nodes, visited_nodes)
            }
          }
        False -> {
          let char = string.slice(input, node.index, 1)
          let updated_nodes =
            process_transitions(
              nfa,
              node.state.transitions,
              rest,
              visited_nodes,
              node,
              char,
            )

          evaluate_loop(nfa, input, updated_nodes, visited_nodes)
        }
      }
    }
  }
}

fn process_transitions(
  nfa: NFA,
  transitions: List(state.Transition),
  nodes: List(Node),
  visited_nodes: Set(Node),
  node: Node,
  char: String,
) -> List(Node) {
  case transitions {
    [] -> nodes
    [#(matcher, name), ..rest] -> {
      case state.matches(matcher, char) {
        False -> {
          process_transitions(nfa, rest, nodes, visited_nodes, node, char)
        }
        True -> {
          let index = case state.is_epsilon(matcher) {
            True -> node.index
            False -> node.index + 1
          }

          let assert Ok(to) = dict.get(nfa.states, name)
          let new_node = Node(index: index, state: to)

          let nodes = case set.contains(visited_nodes, new_node) {
            True -> nodes
            False -> list.append(nodes, [new_node])
          }

          process_transitions(nfa, rest, nodes, visited_nodes, node, char)
        }
      }
    }
  }
}
