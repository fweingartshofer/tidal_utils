import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode.{type Decoder}
import gleam/option.{type Option, None, Some}

pub type JsonApiResponse(included, attributes) {
  ErrorResponse(
    meta: Option(Dynamic),
    jsonapi: Option(Jsonapi),
    links: Option(Links),
    errors: List(Error),
  )
  SuccessResponse(
    meta: Option(Dynamic),
    jsonapi: Option(Jsonapi),
    links: Option(Links),
    included: Option(List(ResourceObject(included))),
    data: Option(Data(attributes)),
  )
}

pub fn json_api_response_decoder(
  included_decoder: Decoder(included),
  attributes_decoder: Decoder(attributes),
) -> Decoder(JsonApiResponse(included, attributes)) {
  use jsonapi <- decode.optional_field(
    "jsonapi",
    None,
    decode.optional(jsonapi_decoder()),
  )
  use meta <- decode.optional_field(
    "meta",
    None,
    decode.optional(decode.dynamic),
  )
  use links <- links_field_decoder()
  let success_decoder = {
    use data <- decode.optional_field(
      "data",
      None,
      decode.optional(data_decoder(attributes_decoder)),
    )
    use included <- decode.optional_field(
      "included",
      None,
      decode.optional(decode.list(resource_object_decoder(included_decoder))),
    )
    decode.success(SuccessResponse(meta:, jsonapi:, links:, included:, data:))
  }
  let error_response_decoder = {
    use errors <- decode.field("errors", decode.list(error_decoder()))
    decode.success(ErrorResponse(meta:, jsonapi:, links:, errors:))
  }
  decode.one_of(success_decoder, [error_response_decoder])
}

pub type Data(attributes) {
  One(ResourceObject(attributes))
  Many(List(ResourceObject(attributes)))
  IdentifierOne(ResourceIdentifierObject)
  IdentifierMany(List(ResourceIdentifierObject))
}

fn data_decoder(attributes_decoder) {
  decode.one_of(decode.map(resource_object_decoder(attributes_decoder), One), [
    decode.map(decode.list(resource_object_decoder(attributes_decoder)), Many),
    decode.map(resource_identifier_object_decoder(), IdentifierOne),
    decode.map(
      decode.list(resource_identifier_object_decoder()),
      IdentifierMany,
    ),
  ])
}

pub type Jsonapi {
  Jsonapi(
    version: Option(String),
    ext: Option(List(String)),
    profile: Option(List(String)),
    meta: Option(Dynamic),
  )
}

fn jsonapi_decoder() -> Decoder(Jsonapi) {
  use version <- decode.field("version", decode.optional(decode.string))
  use ext <- decode.field("ext", decode.optional(decode.list(decode.string)))
  use profile <- decode.field(
    "profile",
    decode.optional(decode.list(decode.string)),
  )
  use meta <- decode.field("meta", decode.optional(decode.dynamic))
  decode.success(Jsonapi(version:, ext:, profile:, meta:))
}

pub type ResourceIdentifierObject {
  ResourceIdentifierObject(
    type_: String,
    id: Option(String),
    lid: Option(String),
    meta: Option(Dynamic),
  )
}

fn resource_identifier_object_decoder() -> Decoder(ResourceIdentifierObject) {
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.optional(decode.string))
  use meta <- decode.optional_field(
    "meta",
    None,
    decode.optional(decode.dynamic),
  )
  decode.success(ResourceIdentifierObject(type_:, id:, lid: None, meta:))
}

pub type ResourceObject(attributes) {
  ResourceObject(
    id: Option(String),
    lid: Option(String),
    type_: String,
    attributes: Option(attributes),
    relationships: Option(Dict(String, RelationshipObject)),
    links: Option(Links),
  )
}

fn resource_object_decoder(
  attribute_decoder: Decoder(attributes),
) -> Decoder(ResourceObject(attributes)) {
  use id <- decode.field("id", decode.optional(decode.string))
  use type_ <- decode.field("type", decode.string)
  use attributes: attributes <- decode.field("attributes", attribute_decoder)
  let attributes = Some(attributes)
  use relationships <- decode.field(
    "relationships",
    decode.optional(decode.dict(decode.string, relationship_object_decoder())),
  )
  use links <- links_field_decoder()
  decode.success(ResourceObject(
    id:,
    lid: None,
    type_:,
    attributes:,
    relationships:,
    links:,
  ))
}

pub type RelationshipObject {
  RelationshipObject(
    links: Option(Links),
    data: Option(ResourceLinkage),
    meta: Option(Dynamic),
  )
}

fn relationship_object_decoder() -> Decoder(RelationshipObject) {
  use links <- links_field_decoder()
  use data <- decode.optional_field(
    "data",
    None,
    decode.optional(resource_linkage_decoder()),
  )
  use meta <- decode.optional_field(
    "meta",
    None,
    decode.optional(decode.dynamic),
  )
  decode.success(RelationshipObject(links:, data:, meta:))
}

pub type ResourceLinkage {
  ToOne(resource: Option(ResourceIdentifierObject))
  ToMany(resources: List(ResourceIdentifierObject))
}

fn resource_linkage_decoder() -> Decoder(ResourceLinkage) {
  decode.one_of(
    decode.map(decode.list(resource_identifier_object_decoder()), ToMany),
    [decode.map(decode.optional(resource_identifier_object_decoder()), ToOne)],
  )
}

pub type Error {
  ApiError(
    id: Option(String),
    links: Option(Links),
    status: Option(String),
    code: Option(String),
    title: Option(String),
    detail: Option(String),
    source: Option(Source),
    meta: Option(Dynamic),
  )
}

fn error_decoder() -> Decoder(Error) {
  use id <- decode.field("id", decode.optional(decode.string))
  use links <- links_field_decoder()
  use status <- decode.field("status", decode.optional(decode.string))
  use code <- decode.field("code", decode.optional(decode.string))
  use title <- decode.field("title", decode.optional(decode.string))
  use detail <- decode.field("detail", decode.optional(decode.string))
  use source <- decode.field("source", decode.optional(source_decoder()))
  use meta <- decode.optional_field(
    "meta",
    None,
    decode.optional(decode.dynamic),
  )
  decode.success(ApiError(
    id:,
    links:,
    status:,
    code:,
    title:,
    detail:,
    source:,
    meta:,
  ))
}

pub type Source {
  Source(
    pointer: Option(String),
    parameter: Option(String),
    header: Option(String),
  )
}

fn source_decoder() -> Decoder(Source) {
  use pointer <- decode.field("pointer", decode.optional(decode.string))
  use parameter <- decode.field("parameter", decode.optional(decode.string))
  use header <- decode.field("header", decode.optional(decode.string))
  decode.success(Source(pointer:, parameter:, header:))
}

pub type Links =
  Dict(String, LinkObject)

fn links_decoder() {
  decode.optional(decode.dict(decode.string, link_object_decoder()))
}

fn links_field_decoder(
  callback: fn(Option(Dict(String, LinkObject))) -> Decoder(a),
) -> Decoder(a) {
  decode.optional_field("links", None, links_decoder(), callback)
}

pub type LinkObject {
  URI(uri: String)
  LinkObject(
    href: String,
    rel: Option(String),
    describedby: Option(String),
    title: Option(String),
    type_: Option(String),
    hreflang: Option(Hreflang),
    meta: Option(Dynamic),
  )
}

fn link_object_decoder() -> Decoder(LinkObject) {
  let link_object_decoder = {
    use href <- decode.field("href", decode.string)
    use rel <- decode.field("rel", decode.optional(decode.string))
    use describedby <- decode.field(
      "describedby",
      decode.optional(decode.string),
    )
    use title <- decode.field("title", decode.optional(decode.string))
    use type_ <- decode.field("type_", decode.optional(decode.string))
    use hreflang <- decode.field(
      "hreflang",
      decode.optional(hreflang_decoder()),
    )
    use meta <- decode.optional_field(
      "meta",
      None,
      decode.optional(decode.dynamic),
    )
    decode.success(LinkObject(
      href:,
      rel:,
      describedby:,
      title:,
      type_:,
      hreflang:,
      meta:,
    ))
  }
  decode.one_of(decode.map(decode.string, URI), [link_object_decoder])
}

pub type Hreflang {
  Language(language: String)
  Languages(languages: List(String))
}

fn hreflang_decoder() -> Decoder(Hreflang) {
  decode.one_of(decode.map(decode.string, Language), [
    decode.map(decode.list(decode.string), Languages),
  ])
}
