import flwr_oauth2.{ClientId, Secret}
import gleam/result
import gleam/uri
import glenvy/dotenv
import glenvy/env
import woof

pub type Config {
  Config(
    client_id: flwr_oauth2.ClientId,
    secret: flwr_oauth2.Secret,
    redirect_uri: uri.Uri,
    authorization_uri: uri.Uri,
    token_uri: uri.Uri,
    scope: flwr_oauth2.Scope,
    database_url: String,
  )
}

pub fn create() -> Result(Config, Nil) {
  let _ = dotenv.load()
  use client_id <- result.try(env("TIDAL_UTILS_CLIENT_ID"))
  let client_id = ClientId(client_id)
  use client_secret <- result.try(env("TIDAL_UTILS_CLIENT_SECRET"))
  let client_secret = Secret(client_secret)
  use redirect_uri <- result.try(env("TIDAL_UTILS_REDIRECT_URI"))
  use redirect_uri <- result.try(
    uri.parse(redirect_uri)
    |> woof.log_error("Could not parse redirect uri", [
      #("redirect uri", redirect_uri),
    ]),
  )
  let assert Ok(authorization_uri) =
    uri.parse("https://login.tidal.com/authorize")
  let assert Ok(token_uri) = uri.parse("https://auth.tidal.com/v1/oauth2/token")
  use database_url <- result.try(env("DATABASE_URL"))

  Ok(Config(
    client_id:,
    secret: client_secret,
    redirect_uri:,
    authorization_uri:,
    token_uri:,
    scope: ["playlists.read", "collection.read", "user.read"],
    database_url:,
  ))
}

fn env(name: String) -> Result(String, Nil) {
  env.string(name)
  |> woof.log_error(name <> " required", [])
  |> result.replace_error(Nil)
}
