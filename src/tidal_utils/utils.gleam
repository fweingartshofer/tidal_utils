import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}

pub fn insert_if_present(l: Dict(a, b), key: a, item: Option(b)) -> Dict(a, b) {
  case item {
    None -> l
    Some(item) -> dict.insert(l, key, item)
  }
}
