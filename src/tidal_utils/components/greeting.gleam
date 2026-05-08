import gleam/option.{type Option, Some}
import lustre/element/html
import tidal_utils/services/tidal_types

pub fn render(user: Option(tidal_types.User)) {
  case user {
    Some(user) ->
      html.h1([], [
        html.text("Welcome "),
        html.text(user.username),
        html.text("!"),
      ])
    _ -> html.h1([], [html.text("Welcome!")])
  }
}
