module LiveTranslation exposing (main)


import Http
import Html exposing (..)
import Html.Events exposing (..)

import Http
import GTranslate.Free exposing (..)



type Msg 
    = Translate String 
    | Response (Result Http.Error Translation )


type alias Model =
    { language: String 
    , translated: Maybe Translation
    }

init: (Model, Cmd Msg ) 
init = 
    ({ language = "es" 
     , translated = Nothing 
     }
    , Cmd.none)



update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of

        Translate text ->
            (model, toTargetLang Response model.language text )

        Response (Ok translation) -> 
            let _ = Debug.log "translated" (translatedText translation) in 
            ({ model | translated =  Just translation }, Cmd.none)

        Response (Err message) -> 
            let _ = Debug.log "err" message in 
            (model, Cmd.none)


            
view : Model -> Html Msg
view model =
    div [] 
        [ h1 [] [ text "Live Translation"]
        
        , div []
            [ input [ onInput Translate ] []
            ]
        
        , div []
            ( 
                 model.translated 
                    |> Maybe.andThen (\t -> Just (translatedText t))
                    |> Maybe.withDefault []
                    |> List.map( \s -> h3 [] [ text s ])
            )

        ]




main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }
