module SliceShow.View exposing (view)

import Html exposing (Html, div, ul, li, a)
import Html.Attributes exposing (style, href)
import Html.Events exposing (onWithOptions)
import SliceShow.Messages as Messages exposing (Message)
import SliceShow.Model exposing (Model, currentSlide)
import SliceShow.SlideData exposing (SlideData)
import SliceShow.ContentData exposing (ContentData(..), state)
import SliceShow.State exposing (State(Hidden))
import Window
import Json.Decode as Json


fit : ( Int, Int ) -> ( Int, Int ) -> Float
fit ( w1, h1 ) ( w2, h2 ) =
    if w1 * h2 < w2 * h1 then
        toFloat w1 / toFloat w2
    else
        toFloat h1 / toFloat h2


toPx : Int -> String
toPx x =
    toString x ++ "px"


view : (a -> Html b) -> Model a b -> Html (Message b)
view renderCustom model =
    case currentSlide model of
        Nothing ->
            viewContainer renderCustom model

        Just slide ->
            viewSlide renderCustom model.dimensions slide


viewContainer : (a -> Html b) -> Model a b -> Html (Message b)
viewContainer renderCustom model =
    div
        [ style
            [ "text-align" => "center" ]
        ]
        (List.indexedMap (viewSlideItem renderCustom) model.slides)


(=>) : a -> b -> ( a, b )
(=>) =
    (,)


viewSlideItem : (a -> Html b) -> Int -> SlideData a b -> Html (Message b)
viewSlideItem renderCustom index slide =
    div
        [ style
            [ "position" => "relative"
            , "width" => "240px"
            , "height" => "150px"
            , "display" => "inline-block"
            , "margin" => "20px 0 0 20px"
            , "cursor" => "pointer"
            ]
        , onWithOptions
            "click"
            { preventDefault = True
            , stopPropagation = False
            }
            (Messages.Goto index |> Json.succeed)
        ]
        [ viewSlide renderCustom (Window.Size 240 150) slide
        , a
            [ style
                [ "position" => "absolute"
                , "left" => "0"
                , "top" => "0"
                , "width" => "240px"
                , "height" => "150px"
                ]
            , href ("#" ++ toString (index + 1))
            ]
            []
        ]


viewSlide : (a -> Html b) -> Window.Size -> SlideData a b -> Html (Message b)
viewSlide renderCustom { width, height } slide =
    div
        [ style
            [ "transform" => ("scale(" ++ toString (fit ( width, height ) slide.dimensions) ++ ")")
            , "width" => toPx (Tuple.first slide.dimensions)
            , "height" => toPx (Tuple.second slide.dimensions)
            , "position" => "absolute"
            , "left" => "50%"
            , "top" => "50%"
            , "margin-left" => toPx (Tuple.first slide.dimensions // -2)
            , "margin-top" => toPx (Tuple.second slide.dimensions // -2)
            , "background" => "#fff"
            , "box-sizing" => "border-box"
            , "text-align" => "left"
            ]
        ]
        (viewElements renderCustom slide.elements)
        |> Html.map Messages.Custom


viewElements : (a -> Html b) -> List (ContentData a b) -> List (Html b)
viewElements renderCustom elements =
    elements
        |> List.filter (\c -> state c /= Hidden)
        |> List.map (viewElement renderCustom)


viewElement : (a -> Html b) -> ContentData a b -> Html b
viewElement renderCustom content =
    case content of
        Container _ render items ->
            render (viewElements renderCustom items)

        Item _ html ->
            html

        Custom _ data ->
            renderCustom data
