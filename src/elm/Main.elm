port module Main exposing (..)

import Html exposing (Html, text, input, select, option, div)
import Html.Attributes exposing (value)
import Array exposing (Array)
import Data.Difficulty exposing (Difficulty)
import Data.Question exposing (Question, questionDecoder)
import View.Header exposing (viewHeader)
import View.Question
import Util exposing (onChange, (=>), appendIf)
import Request.TriviaQuestions exposing (TriviaResults)
import Request.Helpers exposing (queryString)
import View.Button
import Http exposing (Error)


-- MAIN


port output : GameResults -> Cmd msg


port incoming : (List GameResults -> msg) -> Sub msg



-- SUBSCIRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    incoming SavedGameResults


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


type alias GameResults =
    { score : Int
    , total : Int
    , percent : Float
    }


type alias Model =
    { amount : Int
    , limit : Int
    , difficulty : Difficulty
    , questions : Array Question
    }


initModel : Model
initModel =
    Model
        5
        50
        Data.Difficulty.default
        (Array.empty)


init : ( Model, Cmd Msg )
init =
    ( initModel, getTrivia initModel )



-- UPDATE


type Msg
    = Answer Int String
    | UpdateAmount String
    | ChangeDifficulty Difficulty
    | Start
    | GetQuestions (Result Error TriviaResults)
    | SubmitAnswers
    | SavedGameResults (List GameResults)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Answer i val ->
            ( model.questions
                -- Maybe Question
                |> Array.get i
                -- Maybe Question
                |> Maybe.map
                    (\q -> { q | userAnswer = Just val })
                -- Maybe (Array Question)
                |> Maybe.map
                    (\q -> Array.set i q model.questions)
                -- Maybe Model
                |> Maybe.map (\arr -> { model | questions = arr })
                |> Maybe.withDefault model
            , Cmd.none
            )

        UpdateAmount str ->
            case String.toInt str of
                Ok val ->
                    if val > model.limit then
                        { model | amount = model.limit } ! []
                    else
                        { model | amount = val } ! []

                Err err ->
                    model ! []

        ChangeDifficulty lvl ->
            { model | difficulty = lvl } ! []

        Start ->
            ( model, getTrivia model )

        GetQuestions res ->
            case res of
                Ok { questions } ->
                    ( { model
                        | questions = Array.fromList questions
                      }
                    , Cmd.none
                    )

                Err _ ->
                    model ! []

        SubmitAnswers ->
            let
                length =
                    Array.length model.questions

                score =
                    Array.foldl
                        (\{ userAnswer, correct } acc ->
                            case userAnswer of
                                Just v ->
                                    if v == correct then
                                        acc + 1
                                    else
                                        acc

                                Nothing ->
                                    acc
                        )
                        0
                        model.questions

                percentage =
                    ((toFloat score) / (toFloat length)) * 100

                res =
                    GameResults score length percentage
            in
                ( model, output res )

        SavedGameResults res ->
            model ! []



-- VIEW


view : Model -> Html Msg
view { amount, questions } =
    div
        []
        [ viewHeader
        , input
            [ onChange UpdateAmount
            , value (toString amount)
            ]
            []
        , select [ onChange (ChangeDifficulty << Data.Difficulty.get) ]
            (List.map (\key -> option [] [ text key ])
                Data.Difficulty.keys
            )
        , View.Button.btn Start "Start"
        , div
            []
            (questions
                |> Array.indexedMap (\i q -> View.Question.view (Answer i) q)
                |> Array.toList
            )
        , View.Button.btn SubmitAnswers "Submit"
        ]



-- HTTP


getTrivia : Model -> Cmd Msg
getTrivia model =
    let
        difficultyValue =
            model.difficulty
                |> Data.Difficulty.toString
                |> String.toLower

        flag =
            Data.Difficulty.isAny model.difficulty
    in
        Http.send GetQuestions <|
            Http.get
                (Request.TriviaQuestions.apiUrl
                    ([ "amount" => toString model.amount ]
                        |> appendIf (not flag) ("difficulty" => difficultyValue)
                        |> queryString
                    )
                )
                Request.TriviaQuestions.triviaDecoder
