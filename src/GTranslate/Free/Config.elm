module GTranslate.Free.Config 
    exposing (..)

{-| Free & type-safe google translate api. 

# Opaque Types
@docs   Config
        , initConfig
        , withSourceLang
        , withGenerator
-}



import Http 
import GTranslate.Free.Translation exposing (Translation)


{-| some docs -}
type Config a msg 
    = Config (CRecord a msg)


{-| This config type is used to help configure how you want to translate text 
    and how to generate unique id's for each translation
-}
type alias CRecord a msg = 
    { targetLanguage: String 
    , message: Result Http.Error Translation -> msg
    , sourceLanguage: Maybe String 
    , uidGenerator: Maybe (a -> String)
    }


{-| This provides a helper function to create a bare bones config object with no
    uidGenerator or sourceLanguage is specified
-}
initConfig: String -> (Result Http.Error Translation -> msg) -> Config a msg 
initConfig lang msg =
    Config 
        { targetLanguage = lang  
        , message = msg
        , sourceLanguage = Nothing 
        , uidGenerator = Nothing 
        }


        
{-| add/update a source language of a pre-existing CRecord 
-}
withSourceLang: String -> Config a msg -> Config a msg 
withSourceLang lang config =
    case config of 
        Config record -> 
            Config 
                { record | sourceLanguage = Just lang }

{-| add/update a uid generator function of a pre-existing CRecord 
-}
withUID: (a -> String) -> Config a msg -> Config a msg 
withUID func config =
    case config of 
        Config record -> 
            Config 
                { record | uidGenerator = Just func }


-- Unwrap the CRecord from a Config type
unwrap: Config a msg -> CRecord a msg
unwrap op =
    case op of 
        Config record -> record


getMessage: Config a msg -> (Result Http.Error Translation -> msg) 
getMessage config =
    (unwrap config).message


getTargetLang: Config a msg -> String  
getTargetLang config =
    (unwrap config).targetLanguage

    
getSourceLang: Config a msg -> Maybe String  
getSourceLang config =
    (unwrap config).sourceLanguage

getGenerator: Config a msg -> Maybe (a -> String) 
getGenerator config =
    (unwrap config).uidGenerator



sourceOrAuto: Config a msg -> String 
sourceOrAuto config =
    case (unwrap config).sourceLanguage of 
        Just source -> source
        Nothing -> "auto"

