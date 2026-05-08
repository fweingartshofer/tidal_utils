import gleam/http/request
import gleam/uri
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  let assert Ok(res) = "code=asdf&state=jkl" |> uri.parse()
  res |> request.from_uri()
  echo res
}
