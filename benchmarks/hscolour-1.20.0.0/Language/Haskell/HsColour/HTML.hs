-- | Formats Haskell source code using HTML with font tags.
module Language.Haskell.HsColour.HTML 
    ( hscolour
    , top'n'tail
     -- * Internals
    , renderAnchors, renderComment, renderNewLinesAnchors, escape
    ) where

{-@ LIQUID "--totality" @-}

import Language.Haskell.HsColour.Anchors
import Language.Haskell.HsColour.Classify as Classify
import Language.Haskell.HsColour.Colourise

import Data.Char(isAlphaNum)
import Text.Printf


-- | Formats Haskell source code using HTML with font tags.
hscolour :: ColourPrefs -- ^ Colour preferences.
         -> Bool        -- ^ Whether to include anchors.
         -> String      -- ^ Haskell source code.
         -> String      -- ^ Coloured Haskell source code.
hscolour pref anchor = 
    pre
    . (if anchor then renderNewLinesAnchors
                      . concatMap (renderAnchors (renderToken pref))
                      . insertAnchors
                 else concatMap (renderToken pref))
    . tokenise

top'n'tail :: String -> String -> String
top'n'tail title = (htmlHeader title ++) . (++htmlClose)

pre :: String -> String
pre = ("<pre>"++) . (++"</pre>")

renderToken :: ColourPrefs -> (TokenType,String) -> String
renderToken pref (t,s) = fontify (colourise pref t)
                         (if t == Comment then renderComment s else escape s)

renderAnchors :: (a -> String) -> Either String a -> String
renderAnchors _      (Left v) = "<a name=\""++v++"\"></a>"
renderAnchors render (Right r) = render r

-- if there are http://links/ in a comment, turn them into
-- hyperlinks
renderComment :: String -> String
renderComment ('h':'t':'t':'p':':':'/':'/':xs) =
        renderLink ("http://" ++ a) ++ renderComment b
    where
        -- see http://www.gbiv.com/protocols/uri/rfc/rfc3986.html#characters
        isUrlChar x = isAlphaNum x || x `elem` ":/?#[]@!$&'()*+,;=-._~%"
        (a,b) = span isUrlChar xs
        renderLink link = "<a href=\"" ++ link ++ "\">" ++ escape link ++ "</a>"
        
renderComment (x:xs) = escape [x] ++ renderComment xs
renderComment [] = []

renderNewLinesAnchors :: String -> String
renderNewLinesAnchors = unlines . map render . zip [1..] . lines
    where render (line, s) = "<a name=\"line-" ++ show line ++ "\"></a>" ++ s

-- Html stuff
fontify ::  [Highlight] -> String -> String
fontify [] s     = s
fontify (h:hs) s = font h (fontify hs s)

font ::  Highlight -> String -> String
font Normal         s = s
font Bold           s = "<b>"++s++"</b>"
font Dim            s = "<em>"++s++"</em>"
font Underscore     s = "<u>"++s++"</u>"
font Blink          s = "<blink>"++s++"</blink>"
font ReverseVideo   s = s
font Concealed      s = s
font (Foreground (Rgb r g b)) s = printf   "<font color=\"#%02x%02x%02x\">%s</font>" r g b s
font (Background (Rgb r g b)) s = printf "<font bgcolor=\"#%02x%02x%02x\">%s</font>" r g b s
font (Foreground c) s =   "<font color="++show c++">"++s++"</font>"
font (Background c) s = "<font bgcolor="++show c++">"++s++"</font>"
font Italic         s = "<i>"++s++"</i>"

escape ::  String -> String
escape ('<':cs) = "&lt;"++escape cs
escape ('>':cs) = "&gt;"++escape cs
escape ('&':cs) = "&amp;"++escape cs
escape (c:cs)   = c: escape cs
escape []       = []

htmlHeader ::  String -> String
htmlHeader title = unlines
  [ "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 3.2 Final//EN\">"
  , "<html>"
  , "<head>"
  ,"<!-- Generated by HsColour, http://code.haskell.org/~malcolm/hscolour/ -->"
  , "<title>"++title++"</title>"
  , "</head>"
  , "<body>"
  ]
htmlClose ::  String
htmlClose  = "\n</body>\n</html>"
