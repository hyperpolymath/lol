// SPDX-License-Identifier: MIT AND LicenseRef-Palimpsest-0.8
// SPDX-FileCopyrightText: 2024-2025 Ehsaneddin Asgari and Contributors

open RescriptCore

/**
 * 1000Langs - Super-Parallel Corpus Crawler
 *
 * A multilingual corpus building system supporting 1500+ languages
 * from parallel Bible translations across multiple sources.
 */

module Config = {
  let version = "0.1.0"
  let name = "1000Langs"
  let description = "Super-parallel corpus crawler for multilingual NLP research"

  type source =
    | BibleCloud
    | BibleCom
    | BibleIs
    | PngScriptures
    | EBible
    | FindBible

  let allSources = [BibleCloud, BibleCom, BibleIs, PngScriptures, EBible, FindBible]

  let sourceToString = source => switch source {
    | BibleCloud => "bible.cloud"
    | BibleCom => "bible.com"
    | BibleIs => "bible.is"
    | PngScriptures => "pngscriptures.org"
    | EBible => "ebible.org"
    | FindBible => "find.bible"
  }
}

module Language = {
  type iso639_3 = string
  type languageName = string

  type t = {
    code: iso639_3,
    name: languageName,
    family: option<string>,
    script: option<string>,
    country: option<string>,
  }

  let make = (~code, ~name, ~family=?, ~script=?, ~country=?, ()) => {
    code,
    name,
    family,
    script,
    country,
  }

  let getCode = lang => lang.code
  let getName = lang => lang.name
}

module Verse = {
  type book = string
  type chapter = int
  type verseNum = int

  type reference = {
    book: book,
    chapter: chapter,
    verse: verseNum,
  }

  type t = {
    reference: reference,
    text: string,
    language: Language.iso639_3,
  }

  let makeReference = (~book, ~chapter, ~verse) => {book, chapter, verse}

  let make = (~reference, ~text, ~language) => {reference, text, language}

  let toCanonicalId = ref =>
    `${ref.book}.${Int.toString(ref.chapter)}.${Int.toString(ref.verse)}`
}

module Corpus = {
  type alignment = {
    referenceId: string,
    translations: Dict.t<string>,
  }

  type t = {
    name: string,
    languages: array<Language.t>,
    alignments: array<alignment>,
    metadata: Dict.t<string>,
  }

  let empty = name => {
    name,
    languages: [],
    alignments: [],
    metadata: Dict.make(),
  }

  let addLanguage = (corpus, lang) => {
    ...corpus,
    languages: Array.concat(corpus.languages, [lang]),
  }

  let addAlignment = (corpus, alignment) => {
    ...corpus,
    alignments: Array.concat(corpus.alignments, [alignment]),
  }

  let languageCount = corpus => Array.length(corpus.languages)
  let alignmentCount = corpus => Array.length(corpus.alignments)
}

let main = () => {
  Console.log(`${Config.name} v${Config.version}`)
  Console.log(Config.description)
  Console.log(`Supported sources: ${Config.allSources->Array.map(Config.sourceToString)->Array.join(", ")}`)
}

main()
