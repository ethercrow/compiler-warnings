#!/usr/bin/env runhaskell
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

import qualified Data.Text as T
import Data.Binary (encode, decode)
import Test.Tasty.TH
import Test.Tasty.HUnit
import Test.Tasty.QuickCheck
import Text.Warning

main :: IO ()
main = $defaultMainGenerator

case_0 :: Assertion
case_0 =
    let input = unlines
            [ "foo:3:5: Fail"
            ]
        warnings =
            [ Warning "foo" 3 5 3 6 " Fail"
            ]
    in do parseWarnings input @?= warnings

case_ghc_1 :: Assertion
case_ghc_1 =
    let input = unlines
            [ "modules/Warning.hs:29:5: Not in scope: ‘eit'"
            ]
        warnings =
            [ Warning "modules/Warning.hs" 29 5 29 6 " Not in scope: ‘eit'"
            ]
    in do parseWarnings input @?= warnings

case_ghc_1_with_newlines :: Assertion
case_ghc_1_with_newlines =
    let input = unlines
            [ ""
            , "modules/Warning.hs:29:5: Not in scope: ‘eit'"
            , ""
            ]
        warnings =
            [ Warning "modules/Warning.hs" 29 5 29 6 " Not in scope: ‘eit'"
            ]
    in do parseWarnings input @?= warnings

case_ghc_2 :: Assertion
case_ghc_2 =
    let input = unlines
            [ "modules/Warning.hs:29:5: Not in scope: ‘eit'"
            -- , ""
            , "modules/Warning.hs:29:9: Not in scope: ‘her'"
            ]
        warnings =
            [ Warning "modules/Warning.hs" 29 5 29 6 " Not in scope: ‘eit'"
            , Warning "modules/Warning.hs" 29 9 29 10 " Not in scope: ‘her'"
            ]
    in do parseWarnings input @?= warnings

case_ghc_2_with_newlines :: Assertion
case_ghc_2_with_newlines =
    let input = unlines
            [ "modules/Warning.hs:29:5: Not in scope: ‘eit'"
            , ""
            , "modules/Warning.hs:29:9: Not in scope: ‘her'"
            ]
        warnings =
            [ Warning "modules/Warning.hs" 29 5 29 6 " Not in scope: ‘eit'"
            , Warning "modules/Warning.hs" 29 9 29 10 " Not in scope: ‘her'"
            ]
    in do parseWarnings input @?= warnings

case_ghc_2_perhaps_you_meant :: Assertion
case_ghc_2_perhaps_you_meant =
    let input = unlines
            [ "modules/Warning.hs:30:5:"
            , "    Not in scope: ‘eit'"
            , "    Perhaps you meant ‘pi’ (imported from Prelude)"
            , ""
            , "modules/Warning.hs:29:9: Not in scope: ‘her'"
            ]
        warnings =
            [ Warning "modules/Warning.hs" 30 5 30 6
                (T.intercalate "\n"
                    [ ""
                    , "    Not in scope: ‘eit'"
                    , "    Perhaps you meant ‘pi’ (imported from Prelude)"
                    ])
            , Warning "modules/Warning.hs" 29 9 29 10 " Not in scope: ‘her'"
            ]
    in do parseWarnings input @?= warnings

case_make :: Assertion
case_make =
    let input = unlines
            [ "ghc -imodules -ferror-spans -Wall -Werror -c modules/Warning.hs"
            , "modules/Warning.hs:30:5-6:"
            , "    Not in scope: 'ei'"
            , "    Perhaps you meant 'pi' (imported from Prelude)"
            , "     modules/Warning.hs:30:8-11: Not in scope: 'ther'"
            , "Makefile:6: recipe for target 'modules/Warning.o' failed"
            , "make: *** [modules/Warning.o] Error 1"
            ]
        warnings =
            [ Warning "modules/Warning.hs" 30 5 30 6
                (T.intercalate "\n"
                    [ ""
                    , "    Not in scope: 'ei'"
                    , "    Perhaps you meant 'pi' (imported from Prelude)"
                    , "     modules/Warning.hs:30:8-11: Not in scope: 'ther'"
                    ])
            , Warning "Makefile" 6 1 6 (-1) " recipe for target 'modules/Warning.o' failed"
            ]
    in do parseWarnings input @?= warnings

case_ghc_multiline :: Assertion
case_ghc_multiline =
    let input = unlines
            [ "[1 of 1] Compiling Main             ( test/Main.hs, .stack-work/dist/x86_64-osx/Cabal-1.24.0.0/build/tasty/tasty-tmp/Main.o )"
            , ""
            , "test/Main.hs:(148,1)-(149,120): warning: [-Worphans]"
            , "    Orphan instance: instance Arbitrary Warning"
            , "    To avoid this"
            , "    move the instance declaration to the module of the class or of the type, or"
            , "    wrap the type with a newtype and declare the instance on the new type."
            , "Linking .stack-work/dist/x86_64-osx/Cabal-1.24.0.0/build/tasty/tasty .."
            ]
        warnings =
            [ Warning "test/Main.hs" 148 1 149 120
                (T.intercalate "\n"
                    [ " warning: [-Worphans]"
                    , "    Orphan instance: instance Arbitrary Warning"
                    , "    To avoid this"
                    , "    move the instance declaration to the module of the class or of the type, or"
                    , "    wrap the type with a newtype and declare the instance on the new type."
                    ])
            ]
    in do parseWarnings input @?= warnings

case_typescript :: Assertion
case_typescript =
    let input = "lol.ts(13,9): error TS2304: Cannot find name 'lol'."
        warnings = [Warning "lol.ts" 13 9 13 10 " error TS2304: Cannot find name 'lol'."]
    in do parseWarnings input @?= warnings

case_colons_in_error_message :: Assertion
case_colons_in_error_message =
    let input = unlines
            [ "modules/Snippet.hs:75:34-37:"
            , "     Couldn't match expected type ‘WriterT"
            , "\t\t\t\t\tR.YiString"
            , "                                     transformers-0.3.0.0:Data.Functor.Identity.Identity"
            , "                                     a’"
            , "                 with actual type ‘a’"
            ]
        warnings =
            [ Warning "modules/Snippet.hs" 75 34 75 37
                (T.intercalate "\n"
                    [ ""
                    , "     Couldn't match expected type ‘WriterT"
                    , "\t\t\t\t\tR.YiString"
                    , "                                     transformers-0.3.0.0:Data.Functor.Identity.Identity"
                    , "                                     a’"
                    , "                 with actual type ‘a’"
                    ])
            ]
    in do parseWarnings input @?= warnings

prop_binary_roundtrip :: Warning -> Bool
prop_binary_roundtrip w = decode (encode w) == w

instance Arbitrary Warning where
    arbitrary = Warning <$> arbitrary <*> arbitrary <*> arbitrary <*> arbitrary <*> arbitrary <*> (T.pack <$> arbitrary)