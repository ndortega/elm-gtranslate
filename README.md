# GTranslate


The goal of this library is to provide a type-safe way to interact with the Google Translation api. This project will eventually come in two flavors: Free & Official. Currently, only the Free module is implemented which allows you to make a limited number of translations (try to avoid hundreds of requests/min from the same ip). 

#### GTranslate.Free
This module takes advantage of a legacy endpoint which allows us to generate translations for free. No Google account, api key, or any other credentials are needed. I'd recommend this library for prototyping and personal projects that don't require heavy amounts of translations, because Google will throttle you if you make too many requests. As long as you don't spam Google with hundreds of requests/minute you shouldn't be affected. 

#### GTranslate.Official
This should come as no surprise, but this module will eventually utilize the official Google Translation API. This will require authentication tokens in order to make requests. If you're cheap and you still don't want to pay Google, I'd recommend  looking into https://www.npmjs.com/package/google-translate-token which will generate tokens for free. 

## Example

Below is a short program that translates a list of Spanish phrases into English. This snippet also shows how to use the ``apply`` function to update existing data structures with completed translations. (The logic for displaying these phrases are entirely up to you)

```elm
import Http
import GTranslate.Free exposing (..)


                        -- MESSAGES --
type Msg 
    = Response (Result Http.Error Translation )
    | Translate 
    | Apply 


                        -- Models --    
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
    Response -- 'Response' is our message that will process incoming Translations
        |> initConfig "en"      -- specify that english is our target language
        |> withSourceLang "es"  -- **OPTIONAL** specify that spanish is our source language
        |> withUID (\ p -> toString p.id ) -- **OPTIONAL** the function used to generate a unique id for each record



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

```

# About
This project is bootstrapped with [Create Elm App](https://github.com/halfzebra/create-elm-app).

Below you will find some information on how to perform basic tasks.
You can find the most recent version of this guide [here](https://github.com/halfzebra/create-elm-app/blob/master/template/README.md).

## Table of Contents

* [Folder structure](#folder-structure)
* [Installing Elm packages](#installing-elm-packages)
* [Available scripts](#available-scripts)
  * [elm-app build](#elm-app-build)
  * [elm-app start](#elm-app-start)
  * [elm-app install](#elm-app-install)
  * [elm-app test](#elm-app-test)
* [Generate Documentation](#generate-docs)
 
## Folder structure

```sh
my-app/
├── .gitignore
├── README.md
├── elm.json
├── elm-stuff
├── public
│   ├── favicon.ico
│   ├── index.html
│   ├── logo.svg
│   └── manifest.json
├── src
│   ├── examples
|   |   ├── Demo.elm
|   |   ├── LiveTranslation.elm
|   ├── GTranslate
|   |   ├── Free.elm
|   |   ├── Official.elm
│   ├── index.js
│   ├── main.css
│   └── registerServiceWorker.js
└── tests
    └── Tests.elm
```

For the project to build, these files must exist with exact filenames:

* `public/index.html` is the page template;
* `public/favicon.ico` is the icon you see in the browser tab;
* `src/index.js` is the JavaScript entry point.

You can delete or rename the other files.

You may create subdirectories inside src.


## Installing Elm packages

```sh
elm-app install <package-name>
```

Other `elm-package` commands are also [available].(#package)

## Available scripts

In the project directory you can run:

### `elm-app build`

Builds the app for production to the `build` folder.

The build is minified, and the filenames include the hashes.
Your app is ready to be deployed!

### `elm-app start`

Runs the app in the development mode.
Open [http://localhost:3000](http://localhost:3000) to view it in the browser.

The page will reload if you make edits.
You will also see any lint errors in the console.

You may change the listening port number by using the `PORT` environment variable.

### `elm-app install`

Alias for [`elm install`](http://guide.elm-lang.org/get_started.html#elm-install)

Use it for installing Elm packages from [package.elm-lang.org](http://package.elm-lang.org/)

### `elm-app test`

Run tests with [node-test-runner](https://github.com/rtfeldman/node-test-runner/tree/master)

You can make test runner watch project files by running:

```sh
elm-app test --watch
```

### Generate Docs

`elm make --docs=docs.json`

This will generate the documentation for this package