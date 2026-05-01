import gleam/option

pub type TidalAuthContext {
  TidalAuthContext(session_id: String, access_token: option.Option(String))
}
