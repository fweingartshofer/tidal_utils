import flwr_oauth2
import gleam/dynamic
import gleam/dynamic/decode
import gleam/float
import gleam/option
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}

pub type Tokens {
  Tokens(
    access_token: String,
    refresh_token: option.Option(String),
    expires_at: option.Option(Timestamp),
  )
}

pub fn tokens_decoder() -> decode.Decoder(Tokens) {
  use access_token <- decode.field("access_token", decode.string)
  use refresh_token <- decode.field(
    "refresh_token",
    decode.optional(decode.string),
  )
  use expires_at <- decode.field("expires_at", decode.optional(decode.int))
  let expires_at = expires_at |> option.map(timestamp.from_unix_seconds)
  decode.success(Tokens(access_token:, refresh_token:, expires_at:))
}

pub fn from_access_token_response(response: flwr_oauth2.AccessTokenResponse) {
  let now = timestamp.system_time()
  let expires_at =
    response.expires_in
    |> option.map(duration.seconds)
    |> option.map(timestamp.add(now, _))
  Tokens(
    access_token: response.access_token,
    refresh_token: response.refresh_token,
    expires_at:,
  )
}

pub fn tokens_encoder(tokens: Tokens) -> dynamic.Dynamic {
  dynamic.properties([
    #(dynamic.string("access_token"), dynamic.string(tokens.access_token)),
    #(
      dynamic.string("refresh_token"),
      tokens.refresh_token
        |> option.map(dynamic.string)
        |> option.lazy_unwrap(dynamic.nil),
    ),
    #(
      dynamic.string("expires_at"),
      tokens.expires_at
        |> option.map(timestamp.to_unix_seconds)
        |> option.map(float.truncate)
        |> option.map(dynamic.int)
        |> option.lazy_unwrap(dynamic.nil),
    ),
  ])
}
