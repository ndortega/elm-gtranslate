module GTranslate.Free.Translation exposing (TRecord, Translation(..), changeID, confidence, decodeIndex, id, originalText, sentenceDecoder, sourceLanguage, targetLanguage, translatedText, translationDecoder, updateRecord)

import Array exposing (Array, get)
import Json.Decode exposing (..)
import Maybe exposing (withDefault)
import Debug exposing (toString)

{-| This is the type that is decoded from the JSON from the google translate api. This type
contains useful information like: translation, original text, source language,
target language, and confidence level.
-}
type Translation
    = Translation TRecord



-- This record is an internal type used by this package


type alias TRecord =
    { translation : String
    , originalText : String
    , sourceLang : String
    , targetLang : String
    , confidence : Maybe Float -- some translations dont' require google to guess the source language origin
    , identifier : Maybe String -- not all actions require an ID to be assigned to a Translation
    }


{-| Get the translated text from a Translation type

    import GoogleTranslate exposing (Translation, translatedText)

    Translation "how are you doing?" "¿como estas?" "es" "en" 0.98
        |> translatedText

    --> "how are you doing?"

-}
translatedText : Translation -> String
translatedText translation =
    case translation of
        Translation t ->
            t.translation


{-| Get the original text from a Translation type

    import GoogleTranslate exposing (Translation, originalText)

    Translation "how are you doing?" "¿como estas?" "es" "en" 0.98
        |> originalText

    --> "¿como estas?"

-}
originalText : Translation -> String
originalText translation =
    case translation of
        Translation t ->
            t.originalText


{-| Get the source language from a Translation type

    import GoogleTranslate exposing (Translation, sourceLanguage)

    Translation "how are you doing?" "¿como estas?" "es" "en" 0.98
        |> sourceLanguage

    --> "es"

-}
sourceLanguage : Translation -> String
sourceLanguage translation =
    case translation of
        Translation t ->
            t.sourceLang


{-| Get the target language from this Translation type

    import GoogleTranslate exposing (Translation, targetLanguage)

    Translation "how are you doing?" "¿como estas?" "es" "en" 0.98
        |> targetLanguage

    --> "en"

-}
targetLanguage : Translation -> String
targetLanguage translation =
    case translation of
        Translation t ->
            t.targetLang


{-| Get the confidence level from a Translation type which ranges from (0 - 1)

    import GoogleTranslate exposing (Translation, confidence)

    Translation "how are you doing?" "¿como estas?" "es" "en" 0.98
        |> confidence

    --> 0.98

-}
confidence : Translation -> Maybe Float
confidence translation =
    case translation of
        Translation t ->
            t.confidence


{-| Get the id of this Translation if it exists

    import GoogleTranslate exposing (Translation, confidence)

    Translation "1" "how are you doing?" "¿como estas?" "es" "en" 0.98
        |> confidence

    --> "1"

-}
id : Translation -> Maybe String
id translation =
    case translation of
        Translation t ->
            t.identifier


{-| Convience function to add/overwrite an id on a translation object
-}
changeID : String -> Translation -> Translation
changeID identifier translation =
    case translation of
        Translation t ->
            Translation { t | identifier = Just identifier }


{-| Convience function used to update a custom type with the translated
text from a Translation
-}
updateRecord : (a -> String -> a) -> Translation -> a -> a
updateRecord update translation object =
    translation
        |> translatedText
        |> update object


{-| Given an index in an array, attempt to decode the value at that location using the
provided decoder.
-}
decodeIndex : Int -> Decoder a -> Array Value -> Maybe a
decodeIndex index decoder arr =
    case get index arr of
        -- get object at index in aray
        Just v ->
            case decodeValue decoder v of
                -- attempt to decode the object at that index
                Ok x ->
                    Just x

                Err _ ->
                    Nothing

        Nothing ->
            Nothing


sentenceDecoder : Array (Array Value) -> List { original : String, translated : String }
sentenceDecoder sentences =
    sentences
        |> Array.toList
        |> List.filterMap
            (\sentence ->
                let
                    -- Extract all values from the summary array
                    decodedTranslation =
                        decodeIndex 0 string sentence

                    decodedText =
                        decodeIndex 1 string sentence
                in
                -- Ensure those summary values all exist and were decoded successfully
                case ( decodedTranslation, decodedText ) of
                    ( Just translated, Just original ) ->
                        Just { original = original, translated = translated }

                    _ ->
                        Nothing
            )



-- Given just an array, decode certain values at specific points into a Translation type


translationDecoder : Maybe String -> String -> Decoder Translation
translationDecoder identifier targetLang =
    array value
        |> andThen
            (\arr ->
                let
                    -- extract variables
                    decodedNestedArray =
                        decodeIndex 0 (array (array value)) arr

                    decodedLanguage =
                        decodeIndex 2 string arr

                    decodedConfidence =
                        decodeIndex 6 (maybe float) arr
                in
                -- ensure that all values were decoded correctly
                case ( decodedNestedArray, decodedLanguage ) of
                    ( Just sentences, Just sourceLang ) ->
                        let
                            decodedSentences =
                                sentenceDecoder sentences

                            translated =
                                decodedSentences |> List.map (\e -> e.translated) |> List.foldl (++) ""

                            original =
                                decodedSentences |> List.map (\e -> e.original) |> List.foldl (++) ""

                            conf =
                                Maybe.withDefault Nothing decodedConfidence
                        in
                        succeed (Translation (TRecord translated original sourceLang targetLang conf identifier))

                    ( Nothing, _ ) ->
                        fail ("Missing translation object: " ++ toString decodedNestedArray)

                    ( _, Nothing ) ->
                        fail ("Missing Language: " ++ toString decodedLanguage)
            )
