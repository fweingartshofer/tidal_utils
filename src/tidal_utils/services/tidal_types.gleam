import gleam/dynamic/decode

pub type Playlist {
  Playlist(name: String)
}

pub fn playlist_decoder() -> decode.Decoder(Playlist) {
  use name <- decode.field("name", decode.string)
  decode.success(Playlist(name:))
}
