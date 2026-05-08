import lustre/attribute
import lustre/element
import lustre/element/html

pub fn render(redirect_uri: String) {
  element.fragment([
    style(),
    html.a([attribute.class("tidal-button"), attribute.href(redirect_uri)], [
      html.text("Tidal Login"),
    ]),
  ])
}

fn style() {
  html.style(
    [],
    "
.tidal-button {
  display: inline-block;
  padding: 12px 20px;
  background-color: #000;
  color: #fff;
  font-family: system-ui, -apple-system, sans-serif;
  font-size: 14px;
  font-weight: 600;
  text-decoration: none;
  border: 2px solid #000;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.tidal-button:hover {
  background-color: #fff;
  color: #000;
}

.tidal-button:active {
  transform: scale(0.97);
}

.tidal-button:focus {
  outline: none;
  box-shadow: 0 0 0 3px rgba(0, 0, 0, 0.2);
}
  ",
  )
}
