import dream/http/response
import dream/http/status
import gleam/list
import gleam/option
import lustre/element
import lustre/element/html
import tidal_utils/services/json_api.{type ResourceObject}
import tidal_utils/services/tidal_types.{type Playlist}

pub fn render(playlists: List(ResourceObject(Playlist))) -> response.Response {
  echo playlists
  case playlists {
    [] ->
      element.fragment([
        html.h1([], [html.text("Playlists")]),
        html.p([], [html.text("Nothing to show")]),
      ])
    _ ->
      element.fragment([
        html.h1([], [html.text("Playlists")]),
        html.ul(
          [],
          playlists
            |> list.filter_map(fn(p) { p.attributes |> option.to_result(Nil) })
            |> list.map(fn(p) { html.li([], [html.text(p.name)]) }),
        ),
      ])
  }
  |> element.to_string()
  |> response.html_response(status.ok, _)
}
