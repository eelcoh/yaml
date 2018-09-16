module Yaml.Parser exposing (Value, toString, parser, fromString)

import Parser as P exposing ((|=), (|.))
import Yaml.Parser.Ast as Ast
import Yaml.Parser.Util as U
import Yaml.Parser.Document
import Yaml.Parser.String
import Yaml.Parser.Record
import Yaml.Parser.List
import Yaml.Parser.Null


{-| -}
type alias Value =
  Ast.Value


{-| -}
toString : Value -> String
toString =
  Ast.toString



-- PARSER


{-| -}
fromString : String -> Result (List P.DeadEnd) Ast.Value
fromString =
  P.run parser


{-| -}
parser : P.Parser Ast.Value
parser =
  P.succeed identity
    |. Yaml.Parser.Document.begins
    |= value
    |. Yaml.Parser.Document.ends



-- YAML / VALUE


value : P.Parser Ast.Value
value =
  P.oneOf
    [ Yaml.Parser.String.exceptions
    , Yaml.Parser.Record.inline { child = valueInline }
    , Yaml.Parser.List.inline { child = valueInline }
    , P.andThen (Yaml.Parser.List.toplevel { child = valueToplevel }) U.nextIndent
    , P.andThen (Yaml.Parser.Record.toplevel toplevelRecordConfig True) U.nextIndent
    , Yaml.Parser.String.toplevel
    ]


valueToplevel : P.Parser Ast.Value
valueToplevel =
  P.lazy <| \_ -> 
    P.oneOf
      [ Yaml.Parser.String.exceptions
      , Yaml.Parser.Record.inline { child = valueInline }
      , Yaml.Parser.List.inline { child = valueInline }
      , P.andThen (Yaml.Parser.List.toplevel { child = valueToplevel }) P.getCol
      , P.andThen (Yaml.Parser.Record.toplevel toplevelRecordConfig False) P.getCol
      , Yaml.Parser.Null.inline
      , Yaml.Parser.String.inline ['\n']
      ]


valueInline : List Char -> P.Parser Ast.Value
valueInline endings =
  P.lazy <| \_ -> 
    P.oneOf
      [ Yaml.Parser.Record.inline { child = valueInline }
      , Yaml.Parser.List.inline { child = valueInline }
      , Yaml.Parser.String.inline endings
      ]



-- CONFIGS


toplevelRecordConfig : Yaml.Parser.Record.Toplevel
toplevelRecordConfig =
  { childInline = valueInline ['\n']
  , childToplevel = valueToplevel
  , list = Yaml.Parser.List.toplevel { child = valueToplevel }
  }