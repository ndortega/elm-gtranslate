module GTranslate.Free.Core exposing (apply, batchRecords, batchStrings, find, toEnglish, toTargetLang, translate, zipMap)

import String exposing (fromInt)
import GTranslate.Free.Config exposing (..)
import GTranslate.Free.Translation exposing (..)
import Http


{-| Translates text from a specific language into another specific language. This function takes an optional string
which can be used to 'id' or 'tag' this translation, a config, and the source text you want to translate.

    For a comprehensive list of supported languages, see [here.](https://cloud.google.com/translate/docs/languages)

-}
translate :
    Maybe String
    -> Config a msg
    -> String
    -> Cmd msg
translate identifier config sourceText =
    Http.send (getMessage config) <|
        Http.get
            ("https://translate.googleapis.com/translate_a/single?client=gtx&sl="
                ++ sourceOrAuto config
                ++ "&tl="
                ++ getTargetLang config
                ++ "&dt=t&q="
                ++ sourceText
            )
            (translationDecoder identifier (getTargetLang config))


{-| Translate any language into english.
For a comprehensive list of supported languages, see [here.](https://cloud.google.com/translate/docs/languages)
-}
toEnglish : (Result Http.Error Translation -> msg) -> String -> Cmd msg
toEnglish message sourceText =
    translate Nothing (initConfig "en" message) sourceText


{-| Convert any language to a target language.
For a comprehensive list of supported languages, go [here.](https://cloud.google.com/translate/docs/languages)
-}
toTargetLang : (Result Http.Error Translation -> msg) -> String -> String -> Cmd msg
toTargetLang message targetLanguage sourceText =
    translate Nothing (initConfig targetLanguage message) sourceText


{-| Convience function used to apply a list of Translations to a list of records,
updating the specified properties with the values from the Translation record
-}
apply :
    Config a msg
    -> (Translation -> a -> a)
    -> List Translation
    -> List a
    -> List a
apply config update translations records =
    case getGenerator config of
        -- Case 1: We have a custom uid generator function, use that to create & lookup matching records
        Just createUID ->
            records
                |> List.map
                    (\item ->
                        translations
                            |> find (\t -> id t == Just (createUID item))
                            -- find all elements that have this unique id
                            |> Maybe.andThen (\match -> Just (item |> update match))
                            -- update the item
                            |> Maybe.withDefault item
                     -- If no matching element can be found, then just return the original item
                    )

        -- Case 2: No uid generator, so step over both lists applying each translation to each adjacent record
        Nothing ->
            let
                -- sort lists by their id, which is their index by default
                sorted =
                    translations
                        |> List.sortBy
                            (\t ->
                                case id t of
                                    Just x ->
                                        x

                                    Nothing ->
                                        ""
                            )

                -- Call our zipMap function and update each record with a translation
                ( updatedRecords, _ ) =
                    ( records, sorted )
                        |> zipMap (\( record, translation ) -> ( record |> update translation, translation ))
            in
            updatedRecords


{-| Convience function used translate a list of strings from one language to another.
Each translation is assigned an id (as a String) which is just the index of the
text in the list.
-}
batchStrings :
    Config String msg
    -> List String
    -> Cmd msg
batchStrings config lines =
    let
        message =
            getMessage config

        source =
            sourceOrAuto config

        target =
            getTargetLang config

        commands =
            case getGenerator config of
                Just generator ->
                    -- if uidGenerator is present, use this instead
                    lines
                        |> List.map
                            (\item ->
                                item |> translate (Just (generator item)) config
                            )

                Nothing ->
                    lines
                        --- default to using the index as the id
                        |> List.indexedMap
                            (\index item ->
                                item |> translate (Just (fromInt index)) config
                            )
    in
    Cmd.batch commands


{-| Convience function used extract & translate a property from a genereic type.
-}
batchRecords :
    Config a msg
    -> (a -> String)
    -> List a
    -> Cmd msg
batchRecords config accessor objects =
    objects
        |> List.indexedMap
            (\index item ->
                let
                    identifier =
                        case getGenerator config of
                            Just func ->
                                Just (func item)

                            Nothing ->
                                Just (fromInt index)
                in
                translate identifier config (accessor item)
            )
        |> Cmd.batch



-- Iterate over each element in a list and return the first element that satistfy's the predicate


find :
    (a -> Bool)
    -> List a
    -> Maybe a
find predicate list =
    case list of
        [] ->
            Nothing

        head :: tail ->
            if predicate head then
                Just head

            else
                find predicate tail


{-| This function recursively iterates over two lists at the same time and applies
a custom function to each pair of elements. If both lists are not the same size,
all extra elements will be copied over without being modified.
-}
zipMap :
    (( a, b ) -> ( a, b ))
    -> ( List a, List b )
    -> ( List a, List b )
zipMap strategy bothLists =
    let
        -- Our recursive function which does they synchronized mapping
        helper lists acc =
            case lists of
                -- Base case: return the accumulator
                ( [], [] ) ->
                    acc

                ( h1 :: t1, h2 :: t2 ) ->
                    let
                        -- Step 1: Deconstruct the accumulator
                        ( list1, list2 ) =
                            acc

                        -- Step 2: Apply the function to both elements
                        ( e1, e2 ) =
                            strategy ( h1, h2 )

                        -- Step 3: Append the newly modified elments to the head of both lists
                        newAcc =
                            ( e1 :: list1, e2 :: list2 )
                    in
                    -- call recursive function
                    helper ( t1, t2 ) newAcc

                -- Copy over extra elements
                ( h1 :: t1, [] ) ->
                    let
                        ( list1, list2 ) =
                            acc

                        -- Append the unchanged head of the first list and don't modify the second
                        newAcc =
                            ( h1 :: list1, list2 )
                    in
                    -- call recursive function
                    helper ( t1, [] ) newAcc

                -- Copy over extra elements
                ( [], h2 :: t2 ) ->
                    let
                        ( list1, list2 ) =
                            acc

                        -- Append the unchanged head of the second list and don't modify the first list
                        newAcc =
                            ( list1, h2 :: list2 )
                    in
                    -- call recursive function
                    helper ( [], t2 ) newAcc

        -- Call the recursive helper function
        ( l1, l2 ) =
            helper bothLists ( [], [] )

        -- reverse both lists so that they are back in their original order
        orderedLists =
            ( List.reverse l1, List.reverse l2 )
    in
    orderedLists
