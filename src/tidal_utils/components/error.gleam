import dream/http/response

pub fn render(code: Int, message: String) -> response.Response {
  { "<h1>An Error ocurred</h1><br/>" <> message }
  |> response.html_response(code, _)
}
