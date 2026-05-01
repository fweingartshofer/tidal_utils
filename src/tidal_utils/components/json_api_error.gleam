import dream/http/response
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/element.{type Element}
import lustre/element/html
import tidal_utils/services/json_api.{type Error}

pub fn render(code: Int, errors: List(Error)) -> response.Response {
  errors
  |> list.map(to_html)
  |> list.prepend(html.h1([], [html.text("Errors")]))
  |> html.div([], _)
  |> element.to_string()
  |> response.html_response(code, _)
}

fn to_html(error: Error) -> Element(String) {
  let source =
    error.source
    |> option.map(fn(x: json_api.Source) {
      option.values([x.header, x.parameter, x.pointer])
      |> list.first()
      |> option.from_result()
    })
    |> option.flatten()
  html.template([], [
    html.h2([], [html.text(option.unwrap(error.title, "Error"))]),
    html.dl(
      [],
      []
        |> add_description_pair("Code", error.code)
        |> add_description_pair("Tidal Error ID", error.id)
        |> add_description_pair("Source", source),
    ),
    html.p([], [
      html.text(option.unwrap(
        error.detail,
        "Please contact the system administrator",
      )),
    ]),
  ])
}

fn add_description_pair(
  descriptions: List(Element(a)),
  title: String,
  description: Option(String),
) -> List(Element(a)) {
  case description {
    None -> descriptions
    Some(description) ->
      [html.dt([], [html.text(title)]), html.dd([], [html.text(description)])]
      |> list.append(descriptions, _)
  }
}
