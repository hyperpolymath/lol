// SPDX-License-Identifier: MIT AND LicenseRef-Palimpsest-0.8
// SPDX-FileCopyrightText: 2024-2025 Ehsaneddin Asgari and Contributors

open RescriptCore

/**
 * Bible.cloud Crawler
 *
 * Crawler implementation for the Digital Bible Platform (bible.cloud)
 * API-based access to Bible translations in 1500+ languages.
 */

open Crawler.Types

module Config = {
  let baseUrl = "https://api.scripture.api.bible/v1"
  let webUrl = "https://bible.cloud"
  let apiVersion = "v1"

  type apiCredentials = {
    apiKey: string,
    apiSecret: option<string>,
  }
}

module Endpoints = {
  let bibles = () => `${Config.baseUrl}/bibles`
  let bible = bibleId => `${Config.baseUrl}/bibles/${bibleId}`
  let books = bibleId => `${Config.baseUrl}/bibles/${bibleId}/books`
  let chapters = (bibleId, bookId) => `${Config.baseUrl}/bibles/${bibleId}/books/${bookId}/chapters`
  let verses = (bibleId, chapterId) => `${Config.baseUrl}/bibles/${bibleId}/chapters/${chapterId}/verses`
  let verse = (bibleId, verseId) => `${Config.baseUrl}/bibles/${bibleId}/verses/${verseId}`
}

module Types = {
  type bibleInfo = {
    id: string,
    name: string,
    nameLocal: string,
    language: Lang1000.Language.t,
    description: option<string>,
    copyright: option<string>,
  }

  type bookInfo = {
    id: string,
    bibleId: string,
    abbreviation: string,
    name: string,
    nameLong: string,
  }

  type chapterInfo = {
    id: string,
    bibleId: string,
    bookId: string,
    number: string,
    reference: string,
  }
}

module Parser = {
  open Types

  let parseBibleList = (_json: string): Crawler.Parser.parseResult<array<bibleInfo>> => {
    // TODO: Implement JSON parsing with proper error handling
    Crawler.Parser.NoMatch
  }

  let parseBooks = (_json: string): Crawler.Parser.parseResult<array<bookInfo>> => {
    // TODO: Implement JSON parsing
    Crawler.Parser.NoMatch
  }

  let parseChapters = (_json: string): Crawler.Parser.parseResult<array<chapterInfo>> => {
    // TODO: Implement JSON parsing
    Crawler.Parser.NoMatch
  }

  let parseVerseText = (_html: string): Crawler.Parser.parseResult<string> => {
    // CSS selector: .verse-text, .scripture-text
    Crawler.Parser.NoMatch
  }
}

module Crawler = {
  type t = {
    credentials: option<Config.apiCredentials>,
    rateLimiter: Crawler.RateLimiter.t,
    state: crawlerState,
  }

  let make = (~apiKey=?, ()) => {
    credentials: apiKey->Option.map(key => {Config.apiKey: key, apiSecret: None}),
    rateLimiter: Crawler.RateLimiter.make(~delayMs=500, ()),
    state: Idle,
  }

  let fetchBibles = (_crawler: t): crawlResult<array<Types.bibleInfo>> => {
    // TODO: Implement API call
    Pending
  }

  let fetchBooks = (_crawler: t, _bibleId: string): crawlResult<array<Types.bookInfo>> => {
    Pending
  }

  let fetchChapter = (_crawler: t, _bibleId: string, _chapterId: string): crawlResult<array<Lang1000.Verse.t>> => {
    Pending
  }
}
