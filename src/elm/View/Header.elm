module View.Header exposing (viewHeader)

import Html exposing (Html, h1, text)
import Html.Attributes exposing (class)


viewHeader : Html msg
viewHeader =
    h1 [ class "Header" ] [ text "Elm Trivia" ]
