import lustre/attribute
import lustre/element/html

pub fn render() {
  html.header([attribute.class("nav")], [
    style(),
    html.div([attribute.class("nav-inner")], [
      html.nav([attribute.class("nav-brand")], [
        html.a([attribute.href("/")], [html.text("Tidal Utils")]),
      ]),
      html.nav([attribute.class("nav-menu")], [
        html.a([attribute.href("/")], [html.text("Home")]),
      ]),
    ]),
  ])
}

fn style() {
  html.style(
    [],
    "
    .nav-inner {
      display: flex;
      flex-direction: column;
    }
    
    /* Keep links structured */
    .nav-menu {
      display: flex;
      flex-direction: column;
    }
    
    /* Desktop layout */
    @media (min-width: 768px) {
      .nav-inner {
        flex-direction: row;
        align-items: center;
        justify-content: space-between;
      }
    
      .nav-menu {
        flex-direction: row;
      }
    }
    ",
  )
}
