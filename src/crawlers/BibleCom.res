// SPDX-License-Identifier: MIT AND LicenseRef-Palimpsest-0.8
// SPDX-FileCopyrightText: 2024-2025 Ehsaneddin Asgari and Contributors

open RescriptCore

/**
 * Bible.com Crawler
 *
 * Crawler implementation for YouVersion (bible.com)
 * Web scraping approach for Bible translations.
 */

open Crawler.Types

module Config = {
  let baseUrl = "https://www.bible.com"
  let apiUrl = "https://www.bible.com/api/bible"

  type versionInfo = {
    id: int,
    abbreviation: string,
    title: string,
    languageTag: string,
  }
}

module Endpoints = {
  let versions = () => `${Config.baseUrl}/versions`
  let version = versionId => `${Config.baseUrl}/versions/${Int.toString(versionId)}`
  let bible = (versionId, bookCode, chapter) =>
    `${Config.baseUrl}/bible/${Int.toString(versionId)}/${bookCode}.${Int.toString(chapter)}`
  let search = (versionId, query) =>
    `${Config.baseUrl}/search/bible?version_id=${Int.toString(versionId)}&q=${query}`
}

module Selectors = {
  // CSS selectors for bible.com HTML structure
  let verseContainer = ".ChapterContent_verse__uvbXo"
  let verseNumber = ".ChapterContent_label__R2PLt"
  let verseText = ".ChapterContent_content__RlRwn"
  let chapterNav = ".ChapterContent_nav__vVPwy"
  let versionSelector = ".VersionSelector_container__3uKjR"
}

module Types = {
  type versionMeta = {
    id: int,
    abbreviation: string,
    title: string,
    language: Lang1000.Language.t,
    hasAudio: bool,
    hasOffline: bool,
  }

  type chapterContent = {
    versionId: int,
    book: string,
    chapter: int,
    verses: array<Lang1000.Verse.t>,
    nextChapter: option<(string, int)>,
    prevChapter: option<(string, int)>,
  }
}

module Parser = {
  open Types

  let parseVersionList = (_html: string): Crawler.Parser.parseResult<array<versionMeta>> => {
    // Parse version listing page
    Crawler.Parser.NoMatch
  }

  let parseChapter = (_html: string): Crawler.Parser.parseResult<chapterContent> => {
    // Parse chapter content using CSS selectors
    Crawler.Parser.NoMatch
  }

  let extractVerseText = (_element: string): option<string> => {
    // Extract clean verse text from HTML element
    None
  }

  let normalizeText = (text: string): string => {
    text
    ->String.trim
    ->String.replaceRegExp(%re("/\s+/g"), " ")
  }
}

module Crawler = {
  type t = {
    rateLimiter: Crawler.RateLimiter.t,
    state: crawlerState,
    cachedVersions: option<array<Types.versionMeta>>,
  }

  let make = () => {
    rateLimiter: Crawler.RateLimiter.make(~delayMs=1000, ()),
    state: Idle,
    cachedVersions: None,
  }

  let fetchVersions = (_crawler: t): crawlResult<array<Types.versionMeta>> => {
    Pending
  }

  let fetchChapter = (_crawler: t, _versionId: int, _book: string, _chapter: int): crawlResult<Types.chapterContent> => {
    Pending
  }

  let fetchBook = (_crawler: t, _versionId: int, _book: string): crawlResult<array<Types.chapterContent>> => {
    Pending
  }
}
