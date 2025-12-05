// SPDX-License-Identifier: MIT AND LicenseRef-Palimpsest-0.8
// SPDX-FileCopyrightText: 2024-2025 Ehsaneddin Asgari and Contributors

/**
 * PNG Scriptures Crawler
 *
 * Crawler for pngscriptures.org - Papua New Guinea Bible translations
 * in numerous Papuan and Austronesian languages.
 */

open Crawler.Types

module Config = {
  let baseUrl = "https://pngscriptures.org"
  let downloadUrl = "https://pngscriptures.org/download"

  type format =
    | Zip
    | Pdf
    | Epub
    | Html
}

module Endpoints = {
  let languages = () => `${Config.baseUrl}/languages`
  let language = langCode => `${Config.baseUrl}/lng/${langCode}`
  let download = (langCode, format) => {
    let formatStr = switch format {
      | Config.Zip => "zip"
      | Config.Pdf => "pdf"
      | Config.Epub => "epub"
      | Config.Html => "html"
    }
    `${Config.downloadUrl}/${langCode}/${formatStr}`
  }
}

module Types = {
  type pngLanguage = {
    code: string,
    name: string,
    alternateName: option<string>,
    region: string,
    population: option<int>,
    hasNewTestament: bool,
    hasOldTestament: bool,
  }

  type downloadInfo = {
    language: pngLanguage,
    format: Config.format,
    sizeBytes: option<int>,
    lastUpdated: option<string>,
  }
}

module Parser = {
  open Types

  let parseLanguageList = (_html: string): Crawler.Parser.parseResult<array<pngLanguage>> => {
    // Parse language listing from main page
    Crawler.Parser.NoMatch
  }

  let parseZipContents = (_archive: string): Crawler.Parser.parseResult<array<(string, string)>> => {
    // Parse ZIP archive to extract HTML files
    Crawler.Parser.NoMatch
  }

  let parseHtmlBook = (_html: string): Crawler.Parser.parseResult<array<Lang1000.Verse.t>> => {
    // Parse individual book HTML file
    Crawler.Parser.NoMatch
  }
}

module Crawler = {
  type t = {
    rateLimiter: Crawler.RateLimiter.t,
    state: crawlerState,
    downloadDir: string,
  }

  let make = (~downloadDir="./downloads/png", ()) => {
    rateLimiter: Crawler.RateLimiter.make(~delayMs=2000, ()),
    state: Idle,
    downloadDir,
  }

  let fetchLanguages = (_crawler: t): crawlResult<array<Types.pngLanguage>> => {
    Pending
  }

  let downloadTranslation = (_crawler: t, _langCode: string, _format: Config.format): crawlResult<string> => {
    // Returns path to downloaded file
    Pending
  }

  let extractAndParse = (_crawler: t, _zipPath: string): crawlResult<Lang1000.Corpus.t> => {
    Pending
  }
}
