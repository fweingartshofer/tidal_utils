import lustre/element
import lustre/element/html

pub fn render(message: String) {
  element.fragment([
    html.h1([], [html.text("An error ocurred")]),
    html.br([]),
    html.text(message),
  ])
}
