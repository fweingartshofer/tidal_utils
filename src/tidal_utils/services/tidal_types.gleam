import gleam/dynamic/decode
import gleam/option.{type Option, None}

pub type WithIdentifier(a) {
  WithIdentifier(id: String, payload: a)
}

pub fn get_payload(identifiable: WithIdentifier(a)) {
  identifiable.payload
}

pub type Playlist {
  Playlist(name: String)
}

pub fn playlist_decoder() -> decode.Decoder(Playlist) {
  use name <- decode.field("name", decode.string)
  decode.success(Playlist(name:))
}

pub type User {
  User(
    country: String,
    email: String,
    email_verified: Bool,
    first_name: Option(String),
    last_name: Option(String),
    username: String,
  )
}

pub fn user_decoder() -> decode.Decoder(User) {
  use country <- decode.field("country", decode.string)
  use email <- decode.field("email", decode.string)
  use email_verified <- decode.field("emailVerified", decode.bool)
  use first_name <- decode.optional_field(
    "firstName",
    None,
    decode.optional(decode.string),
  )
  use last_name <- decode.optional_field(
    "lastName",
    None,
    decode.optional(decode.string),
  )
  use username <- decode.field("username", decode.string)
  decode.success(User(
    country:,
    email:,
    email_verified:,
    first_name:,
    last_name:,
    username:,
  ))
}
