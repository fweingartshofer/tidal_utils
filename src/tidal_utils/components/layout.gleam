import dream/http
import dream/http/response.{Response, Text}
import lustre/attribute
import lustre/element
import lustre/element/html
import tidal_utils/components/navbar

pub fn wrap_(element: element.Element(a)) {
  html.html([attribute.lang("en")], [
    html.head([], [
      html.meta([attribute.charset("UTF-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width, initial-scale=1.0"),
      ]),
      html.title([], "Tidal Utils"),
    ]),
    html.body([], [
      style(),
      navbar.render(),
      html.main([], [
        html.body([], [html.main([], [element])]),
      ]),
    ]),
  ])
  |> element.to_string()
}

pub fn wrap(original_response: http.Response) {
  case original_response.body {
    Text(body) -> {
      let body =
        html.html([attribute.lang("en")], [
          html.head([], [
            html.meta([attribute.charset("UTF-8")]),
            html.meta([
              attribute.name("viewport"),
              attribute.content("width=device-width, initial-scale=1.0"),
            ]),
            html.link([
              attribute.rel("preconnect"),
              attribute.href("https://fonts.googleapis.com"),
            ]),
            html.link([
              attribute.rel("preconnect"),
              attribute.href("https://fonts.gstatic.com"),
              attribute.crossorigin(""),
            ]),
            html.link([
              attribute.href(
                "https://fonts.googleapis.com/css2?family=Atkinson+Hyperlegible:ital,wght@0,400;0,700;1,400;1,700&display=swap",
              ),
              attribute.rel("stylesheet"),
            ]),
            html.title([], "Tidal Utils"),
          ]),
          html.body([], [
            style(),
            navbar.render(),
            html.main([], [
              html.body([], [element.unsafe_raw_html("", "", [], body)]),
            ]),
          ]),
        ])
        |> element.to_string()
        |> Text
      Response(..original_response, body:)
    }
    _ -> original_response
  }
}

fn style() {
  html.style(
    [],
    "
      body {
        font-family: 'Atkinson Hyperlegible', sans-serif;
      }
  ",
  )
}
