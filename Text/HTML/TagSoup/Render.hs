{-|
    This module converts a list of 'Tag' back into a string.
-}

module Text.HTML.TagSoup.Render
    (
    renderTags, renderTagsOptions,
    RenderOptions(..), renderOptions
    ) where

import Data.Char
import qualified Data.IntMap as IntMap
import Text.HTML.TagSoup.Entity
import Text.HTML.TagSoup.Type
import Text.StringLike


data RenderOptions str = RenderOptions
    {optEscape :: Char -> str       -- ^ Escape a single text character
    ,optMinimize :: str -> Bool     -- ^ Minimise <b></b> -> <b/>
    }


-- | A configuration which escapes the four characters @&\"\<\>@, and only minimises @\<br\>@ tags.
--   This configuration is chosen to be compatible with Internet Explorer.
renderOptions :: StringLike str => RenderOptions str
renderOptions = RenderOptions
        (\x -> IntMap.findWithDefault (fromString1 x) (ord x) esc)
        (\x -> toString x == "br")
    where esc = IntMap.fromList [(b, fromString $ "&"++a++";") | (a,b) <- htmlEntities]


-- | Show a list of tags, as they might have been parsed. Note that this makes use of
--   'renderOptions'. If you do not desire renderOption's behavior, try instead 'renderTagsOptions'.
renderTags :: StringLike str => [Tag str] -> str
renderTags = renderTagsOptions renderOptions


-- | Show a list of tags as a String. You need to supply a 'RenderOptions' configuration
--   value. One is provided for you as 'renderOptions'; override it as necessary, eg. to avoid
--   escaping any characters one could do:
--
-- > renderTagsOptions (renderOptions{optEscape = (:[])})
renderTagsOptions :: StringLike str => RenderOptions str -> [Tag str] -> str
renderTagsOptions opts = fromString . tags . map (fmap toString)
    where
        tags (TagOpen name atts:TagClose name2:xs)
            | name == name2 && optMinimize opts (fromString name) = open name atts " /" ++ tags xs
        tags (x:xs) = tag x ++ tags xs
        tags [] = []

        tag (TagOpen name atts) = open name atts ""
        tag (TagClose name) = "</" ++ name ++ ">"
        tag (TagText text) = txt text
        tag (TagComment text) = "<!--" ++ com text ++ "-->"
        tag _ = ""

        txt = concatMap (toString . optEscape opts)
        open name atts shut = "<" ++ name ++ concatMap att atts ++ shut ++ ">"
        att (x,"") = " " ++ x
        att ("",y) = " " ++ "\"" ++ txt y ++ "\""
        att (x,y) = " " ++ x ++ "=\"" ++ txt y ++ "\""

        com ('-':'-':'>':xs) = "-- >" ++ com xs
        com (x:xs) = x : com xs
        com [] = []
