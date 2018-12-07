module Demo exposing (..)


import Debug exposing (toString)
import Browser
import Html.Events exposing( onClick )
import Http
import Html exposing (Html, text, div, h1, h3, img, br, button)
import Html.Attributes exposing (src)

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
                updateStrategy = (\ translation phrase -> { phrase | text = translatedText translation } )

                -- Apply the already completed translatations to our list of phrases
                newPhrases = model.phrases |> apply customConfig updateStrategy model.translations 

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


-- VIEW
view : Model -> Html Msg
view model =
    let 
        styles = 
            [ ("float", "left")
            , ("margin", "30px")
            ] 
    in 
    div []
        [ div []
            [ button [onClick Translate] [text "Translate"]
            , button [onClick Apply ] [ text "Apply" ]
            , br [] []
            , div [] 
                (
                    model.phrases 
                        |> List.map (\phrase -> h3[][ text phrase.text ] )
                )
            ]
    
        , div [   ]
            [ div [] 
                (
                    model.translations 
                        |> List.map (\t -> (   h3[][ text (translatedText t)]
                                        -- div []
                                        --     ( (translatedText t) |> List.map(\ sentence ->  h3[][ text sentence] ) )
                                    )
                        )
                )
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
