// SPDX-License-Identifier: MIT AND LicenseRef-Palimpsest-0.8
// SPDX-FileCopyrightText: 2024-2025 Ehsaneddin Asgari and Contributors

open RescriptCore

/**
 * Digital Bible Platform API
 *
 * Official API wrapper for the Digital Bible Platform,
 * providing access to Bible translations in 1500+ languages.
 */

module Config = {
  let apiBaseUrl = "https://api.scripture.api.bible/v1"
  let cdnBaseUrl = "https://cdn.scripture.api.bible"

  type environment =
    | Production
    | Sandbox

  let getBaseUrl = env => switch env {
    | Production => apiBaseUrl
    | Sandbox => "https://api-sandbox.scripture.api.bible/v1"
  }
}

module Types = {
  type language = {
    id: string,
    name: string,
    nameLocal: string,
    script: string,
    scriptDirection: [#ltr | #rtl],
  }

  type bible = {
    id: string,
    dblId: string,
    abbreviation: string,
    abbreviationLocal: string,
    name: string,
    nameLocal: string,
    description: option<string>,
    descriptionLocal: option<string>,
    language: language,
    countries: array<string>,
    type_: string,
  }

  type rec book = {
    id: string,
    bibleId: string,
    abbreviation: string,
    name: string,
    nameLong: string,
    chapters: array<chapter>,
  }
  and chapter = {
    id: string,
    bibleId: string,
    bookId: string,
    number: string,
    reference: string,
  }

  type verse = {
    id: string,
    orgId: string,
    bibleId: string,
    bookId: string,
    chapterId: string,
    reference: string,
    content: string,
  }

  type passage = {
    id: string,
    bibleId: string,
    orgId: string,
    reference: string,
    content: string,
    verseCount: int,
    copyright: string,
  }

  type apiMeta = {
    fums: string,
    fumsId: string,
    fumsJs: string,
  }

  type apiResponse<'a> = {
    data: 'a,
    meta: option<apiMeta>,
  }

  type apiError = {
    statusCode: int,
    error: string,
    message: string,
  }
}

module Client = {
  open Types

  type t = {
    apiKey: string,
    environment: Config.environment,
    rateLimiter: Crawler.RateLimiter.t,
  }

  let make = (~apiKey, ~environment=Config.Production, ()) => {
    apiKey,
    environment,
    rateLimiter: Crawler.RateLimiter.make(~delayMs=100, ()),
  }

  let getAuthHeaders = client => {
    let headers = Dict.make()
    Dict.set(headers, "api-key", client.apiKey)
    Dict.set(headers, "Accept", "application/json")
    headers
  }

  // API Methods
  let getBibles = (_client: t, ~language: option<string>=?, ~abbreviation: option<string>=?, ()): promise<result<array<bible>, apiError>> => {
    ignore(language)
    ignore(abbreviation)
    Promise.resolve(Error({statusCode: 501, error: "NotImplemented", message: "TODO"}))
  }

  let getBible = (_client: t, ~bibleId: string): promise<result<bible, apiError>> => {
    ignore(bibleId)
    Promise.resolve(Error({statusCode: 501, error: "NotImplemented", message: "TODO"}))
  }

  let getBooks = (_client: t, ~bibleId: string): promise<result<array<book>, apiError>> => {
    ignore(bibleId)
    Promise.resolve(Error({statusCode: 501, error: "NotImplemented", message: "TODO"}))
  }

  let getChapters = (_client: t, ~bibleId: string, ~bookId: string): promise<result<array<chapter>, apiError>> => {
    ignore(bibleId)
    ignore(bookId)
    Promise.resolve(Error({statusCode: 501, error: "NotImplemented", message: "TODO"}))
  }

  let getVerses = (_client: t, ~bibleId: string, ~chapterId: string): promise<result<array<verse>, apiError>> => {
    ignore(bibleId)
    ignore(chapterId)
    Promise.resolve(Error({statusCode: 501, error: "NotImplemented", message: "TODO"}))
  }

  let getPassage = (_client: t, ~bibleId: string, ~passageId: string): promise<result<passage, apiError>> => {
    ignore(bibleId)
    ignore(passageId)
    Promise.resolve(Error({statusCode: 501, error: "NotImplemented", message: "TODO"}))
  }
}
