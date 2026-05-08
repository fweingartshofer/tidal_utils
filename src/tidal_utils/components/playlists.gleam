import gleam/list
import lustre/element
import lustre/element/html
import tidal_utils/services/tidal_types.{type Playlist}

pub fn render(playlists: List(Playlist)) {
  element.fragment([
    html.h2([], [html.text("Playlists")]),
    html.ul(
      [],
      playlists
        |> list.map(fn(p) { html.li([], [html.text(p.name)]) }),
    ),
  ])
}
