module LiveTranslation exposing (..)

import Debug exposing (toString, log)
import Browser
import Html.Events exposing( onInput )
import Http
import Html exposing (Html, text, div, h1, h3, img, br, button, input, b)
import Html.Attributes exposing (src)

import Maybe
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
            let _ = log "translated" (translatedText translation) in 
            ({ model | translated =  Just translation }, Cmd.none)

        Response (Err message) -> 
            let _ = log "Error:" message in 
            (model, Cmd.none)


            
view : Model -> Html Msg
view model =
    div [] 
        [ h1 [] [ text "Live Translation"]
        
        , div []
            [ input [ onInput Translate ] []
            ]
        , br [] []
        , div [] 
            [ br [] []
            , b [] [ text 
                        ( model.translated
                            |> Maybe.andThen(\ t -> Just (translatedText t))
                            |> Maybe.withDefault ("")
                        )
                    ]
            ]
        ]




main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
