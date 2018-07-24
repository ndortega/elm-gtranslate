module GTranslate.Free
    exposing 
        ( Translation  
        , translatedText
        , originalText
        , sourceLanguage        -- Tranlation related Functions --
        , targetLanguage
        , id 
        , changeID

        
        , Config 
        , initConfig
        , withSourceLang
        , withUID
        , configSourceLang      -- Config related Functions --
        , configTargetLang
        , configMessage
        , configUID


        , translate
        , toEnglish             -- Macro functions
        , toTargetLang 
        , apply
        , batchStrings
        , batchRecords
        )

{-| The goal of this library is to provide a type-safe way to interact with the Google Translation api. 
    This project will eventually come in two flavors: Free & Official. Currently, only the Free module 
    is implemented which allows you to make a limited number of translations / minute. 


# Core Functions
These functions are helpful when you want to translate one thing at a time.

@docs   translate
        , toEnglish
        , toTargetLang


# Advanced Functions
These functions are useful when you want to translate many things at the same time. Tranlsations like these are done
simulataneously and will not execute in any order. 

@docs batchStrings
        , batchRecords
        , apply


# Opaque Types

@docs Translation, Config


# Config Functions 

@docs   initConfig
        , withSourceLang
        , withUID
        , configSourceLang     
        , configTargetLang
        , configMessage
        , configUID

# Translation Functions 

@docs   translatedText
        , originalText
        , sourceLanguage       
        , targetLanguage
        , id 
        , changeID


-}

import Http
import GTranslate.Free.Translation exposing (..)
import GTranslate.Free.Config exposing (..)
import GTranslate.Free.Core as Core 



--                                          Opaque Types 

{-| This is the type that is decoded from the JSON from the google translate api. This type 
    contains useful information like: translation, original text, source language, 
    target language, and confidence level.
-}
type alias Translation = 
    GTranslate.Free.Translation.Translation


{-| This type is used to tell our library how to translate and "tag" each
    translation. The 'a'in the type signature represents the custom record type 
    than you can optionally provide a function to create a unique ID for each 
    record. 
-}
type alias Config a msg 
    = GTranslate.Free.Config.Config a msg 


--                                          Functions from the Translation module



{-| Get the translated text from a Translation type

    import GTranslate.Free exposing (Translation, translatedText)

    Translation "how are you doing?" "¿como estas?" "es" "en" 0.98
        |> translatedText 

    --> "how are you doing?"
-}
translatedText: Translation -> String 
translatedText = 
    GTranslate.Free.Translation.translatedText


{-| Get the original text from a Translation type

    import GTranslate.Free exposing (Translation, originalText)

    Translation "how are you doing?" "¿como estas?" "es" "en" 0.98
        |> originalText 
        
    --> "¿como estas?"
-}
originalText: Translation -> String 
originalText = 
    GTranslate.Free.Translation.originalText


{-| Get the source language from a Translation type

    import GTranslate.Free exposing (Translation, sourceLanguage)

    Translation "how are you doing?" "¿como estas?" "es" "en" 0.98
        |> sourceLanguage 
        
    --> "es"
-}
sourceLanguage: Translation -> String 
sourceLanguage = 
    GTranslate.Free.Translation.sourceLanguage


{-| Get the target language from this Translation type

    import GTranslate.Free exposing (Translation, targetLanguage)

    Translation "how are you doing?" "¿como estas?" "es" "en" 0.98
        |> targetLanguage 
        
    --> "en"
-}
targetLanguage: Translation -> String 
targetLanguage = 
    GTranslate.Free.Translation.targetLanguage
        



-- {-| Get the confidence level from a Translation type which ranges from (0 - 1). 
--     Confidence is based on the percieved source language. If you explicitly 
--     translated spanish to english, then no confidence will be given because 
--     google did not have to guess the source language. 
    
--     import GTranslate.Free exposing (Translation, confidence)

--     Translation "how are you doing?" "¿como estas?" "es" "en" 0.98
--         |> confidence 
        
--     --> 0.98
-- -}
-- confidence: Translation -> Maybe Float 
-- confidence = 
--     GTranslate.Free.Translation.confidence



{-| Get the id of this Translation if it exists. The id is optional and must be a string
    
    import GTranslate.Free exposing (Translation, id)

    Translation "1" "how are you doing?" "¿como estas?" "es" "en" 0.98 "sample-1"
        |> id 
        
    --> "1"
-}
id: Translation -> Maybe String  
id = 
    GTranslate.Free.Translation.id


{-| Convience function to add/overwrite an id on a translation object  
-}
changeID: String -> Translation -> Translation 
changeID =  
    GTranslate.Free.Translation.changeID



--                                          Functions from the Config Module


{-| This provides a helper function to create a bare bones config object with no
    uidGenerator or sourceLanguage is specified
-}
initConfig: String -> (Result Http.Error Translation -> msg) -> Config a msg 
initConfig = 
    GTranslate.Free.Config.initConfig


        
{-| add/update a source language of a pre-existing Config 
-}
withSourceLang: String -> Config a msg -> Config a msg 
withSourceLang = 
    GTranslate.Free.Config.withSourceLang 

{-| add/update a uid generator function of a pre-existing Config 
-}
withUID: (a -> String) -> Config a msg -> Config a msg 
withUID = 
    GTranslate.Free.Config.withUID


{-| Gets the source language used in this Config
-}
configSourceLang : Config a msg -> Maybe String
configSourceLang =  
    GTranslate.Free.Config.getSourceLang

{-| Gets the target language used in this Config 
-}
configTargetLang : Config a msg -> String
configTargetLang = 
    GTranslate.Free.Config.getTargetLang 

{-| Gets the custom message used in this Config 
-}
configMessage : Config a msg -> Result Http.Error Translation -> msg
configMessage =  
    GTranslate.Free.Config.getMessage 

{-| Gets the unique id generator function used in this config record
-}
configUID : Config a msg -> Maybe (a -> String)
configUID =  
    GTranslate.Free.Config.getGenerator








--                                                  Functions from the Macros module


{-| Translates text from a specific language into another specific language. This function takes an optional string
    which can be used to 'id' or 'tag' this translation, a config, and the source text you want to translate.

    For a comprehensive list of supported languages, go [here.](https://cloud.google.com/translate/docs/languages)

    import Http
    import GTranslate.Free exposing (Translation, translate)

    -- MESSAGE
    type Msg 
        = Response (Result Http.Error Translation )
        | Translate String 

    -- our configuration record used in the application
    customConfig : Config String Msg
    customConfig =
        Response -- 'Response' is our message 
            |> initConfig "en"      -- specify that english is our target language
            |> withSourceLang "es"  -- specify that spanish is our source language

    -- UPDATE
    update : Msg -> Model -> ( Model, Cmd Msg )
    update message model =
        case message of 

            Translate text ->
                -- Translate the 'text' input variable
                (model, translate Nothing customConfig text ) -- translate spanish (es) to english (en)

            Response (Ok translation) -> 
                -- do something with the translation
                (model, Cmd.none)

            Response (Err msg) ->  
                -- handle error here
                (model, Cmd.none)

-}
translate
    : Maybe String 
    -> Config a msg 
    -> String 
    -> Cmd msg 
translate = 
    Core.translate




{-| Translate any language into english.
    For a comprehensive list of supported languages, go [here.](https://cloud.google.com/translate/docs/languages)

    import Http
    import GTranslate.Free exposing (Translation, toEnglish)

    -- MESSAGE
    type Msg 
        = Response (Result Http.Error Translation )
        | Translate String 


    -- UPDATE
    update : Msg -> Model -> ( Model, Cmd Msg )
    update message model =
        case message of 

            Translate text ->
                (model, toEnglish Response text ) -- translate any language to english

            Response (Ok translation) -> 
                -- do something with the translation
                (model, Cmd.none)

            Response (Err msg) ->  
                -- handle error here
                (model, Cmd.none)

-}
toEnglish 
    : (Result Http.Error Translation -> msg) 
    -> String 
    -> Cmd msg
toEnglish = 
    Core.toEnglish 





{-| Convert any language to a target language.
    For a comprehensive list of supported languages, go [here.](https://cloud.google.com/translate/docs/languages)

    import Http
    import GTranslate.Free exposing (Translation, toTargetLang)

    -- MESSAGE
    type Msg 
        = Response (Result Http.Error Translation )
        | Translate String 


    -- UPDATE
    update : Msg -> Model -> ( Model, Cmd Msg )
    update message model =
        case message of 

            Translate text ->
                (model, toTargetLang Response "hy" text ) -- translate any language to Armenian

            Response (Ok translation) -> 
                -- do something with the translation
                (model, Cmd.none)

            Response (Err msg) ->  
                -- handle error here
                (model, Cmd.none)

-}
toTargetLang 
    : (Result Http.Error Translation -> msg) 
    -> String 
    -> String 
    -> Cmd msg
toTargetLang = 
    Core.toTargetLang



{-| This function is your bread & butter when it comes to handling bulk
    translations. This function takes a config type, an update function, a list of 
    translations, and the list of records you want to apply the translations to. 
    If a uid generator is provided in the config this function will use that to 
    lookup the matching record to update. If no uid generator is provided, then 
    this function will automatically sort the list of translations to match the 
    original order of your records. Afterwards, this function will step over both
    lists and update each translation with the adjacent record. 

    
    import Http
    import GTranslate.Free exposing (..)


    -- Models
    type alias Phrase =
        { text: String
        , id: Int
        }

    type alias Model =
        { phrases: List Phrase
        , translations: List Translation 
        }


    init : ( Model, Cmd Msg )
    init = 
        ({ phrases =  
            [ Phrase "Caballo regalado no se le mira el diente." 1
            , Phrase "Al mal tiempo, buena cara." 2
            , Phrase "A falta de pan, buenas son tortas." 3
            , Phrase "Barriga llena, corazón contento." 4
            ]
        , translations = [] }
        , Cmd.none)

    -- our configuration record used in the application
    customConfig : Config Phrase Msg
    customConfig =
        Response -- 'Response' is our message 
            |> initConfig "en"      -- specify that english is our target language
            |> withSourceLang "es"  -- specify that spanish is our source language
            |> withUID (\ p -> toString p.id )


    -- MESSAGE
    type Msg 
        = Response (Result Http.Error Translation )
        | Translate 
        | Apply 


    -- UPDATE
    update : Msg -> Model -> ( Model, Cmd Msg )
    update message model =
        case message of 

        Apply -> 

             let 
                -- The update function used to apply a translation to a phrase
                update = (\ translation phrase -> { phrase | text = translatedText translation } )

                -- Apply the already completed translatations to our list of phrases
                newPhrases = model.phrases |> apply customConfig update model.translations 

            in

            -- update our model 
            ({ model | phrases = newPhrases }, Cmd.none )


        Translate ->
            -- Translate the all stored phrases
            (model, batchRecords customConfig (\p -> p.text) model.phrases ) 

        Response (Ok translation) -> 
            -- store our completed translations
            ({ model | translations = translation :: model.translations }, Cmd.none)

        Response (Err msg) ->  
            -- handle error here
            (model, Cmd.none)


-}
apply
    : Config a msg 
    -> (Translation -> a -> a)
    -> List Translation
    -> List a
    -> List a
apply = 
    Core.apply



{-| Convience function used translate a list of strings from one language to another. 
    Each translation is assigned an id (as a String) which is just the index of the 
    text in the list.
-}
batchStrings
    : Config String msg
    -> List String
    -> Cmd msg
batchStrings = 
    Core.batchStrings



{-| Convience function used translate a list of custom records from one language to another. 
    Each translation is assigned an id (as a String) based on the given UID generator function. 
    If no function is present in the config, then each record is assigned a string representing 
    the index it appears in the list. You can see an example usuage of this function in the 'apply' 
    function example.
-}
batchRecords
    : Config a msg
    -> ( a -> String )
    -> List a
    -> Cmd msg
batchRecords =
    Core.batchRecords