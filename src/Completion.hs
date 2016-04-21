module Completion (complete, completeFile) where
import Data.Maybe
import Data.Foldable
import Data.List
import System.Directory
import Filesystem.Path.CurrentOS

complete :: String -> [String] -> String
complete start alternatives =
    case filter (isPrefixOf start) alternatives of
        [x] -> x
        _ -> start

completeFile :: String -> IO String
completeFile path =
    let
        noSpecial path =
            path /= "." && path /= ".."

        appendSlash path =
            encodeString (decodeString path </> decodeString "")

        appendPath directory file =
            encodeString (decodeString directory </> decodeString file)

        prepareFiles directory =
            map (appendPath directory) . filter noSpecial

        getDirectory =
            encodeString . directory . decodeString

        alternatives path = do
            searchPath <- getDirectory <$> makeAbsolute path
            contents <- getDirectoryContents searchPath
            return (prepareFiles searchPath contents)

    in do
        object <- complete <$> makeAbsolute path <*> alternatives path
        isDirectory <- doesDirectoryExist object
        return (if isDirectory then appendSlash object else object)





