module Request.TriviaQuestions exposing (apiUrl, triviaDecoder, TriviaResults)

import Json.Decode exposing (Decoder, map2, field, int, list)
import Data.Question exposing (Question, questionDecoder)


apiUrl : String -> String
apiUrl str =
    "https://opentdb.com/api.php" ++ str


type alias TriviaResults =
    { code : Int
    , questions : List Question
    }


triviaDecoder : Decoder TriviaResults
triviaDecoder =
    map2
        TriviaResults
        (field "response_code" int)
        (field "results" (list questionDecoder))
