{-# LANGUAGE OverloadedStrings, TemplateHaskell #-}
import Control.Monad
import Control.Monad.IO.Class
import System.Environment
import System.Directory
import Brick
import Brick.Widgets.Edit
import Data.Text.Zipper
import Graphics.Vty.Attributes
import Graphics.Vty.Input.Events
import Lens.Micro
import Lens.Micro.Extras
import Lens.Micro.TH
import Completion


data Object
    = File
    | Directory
    | DoesNotExist
    deriving Eq

data AppStatus
    = Running
    | Canceled
    | Terminated
    | Confirmed FilePath

data AppState = AppState
    { _appEditor :: Editor
    , _appStatus :: AppStatus
    , _appWarning :: Bool
    , _oldPath :: FilePath
    }
$(makeLenses ''AppState)


main :: IO ()
main = do
    filenames <- getArgs
    forM_ filenames $ \filename -> do
        absolute <- makeAbsolute filename
        object <- objectAt absolute
        case object of
            DoesNotExist ->
                putStrLn ("Warning! Skipping non-existing file: " ++ absolute)
            _ ->
                rename absolute object


objectAt :: FilePath -> IO Object
objectAt path = do
    fileExists <- doesFileExist path
    directoryExists <- doesDirectoryExist path
    case (fileExists, directoryExists) of
        (True, False) -> return File
        (False, True) -> return Directory
        _ -> return DoesNotExist
    

rename :: FilePath -> Object -> IO ()
rename absolute object = do
    finalAppState <- run absolute
    case finalAppState ^. appStatus of
        Running -> error "this should never happen"
        Canceled -> return ()
        Terminated -> error "keyboard interrupt, terminating..."
        Confirmed newPath ->
            case object of
                File -> renameFile absolute newPath
                Directory -> renameDirectory absolute newPath
                _ -> error "this should never happen"
                        

run :: FilePath -> IO AppState
run path = do
    defaultMain (App draw showFirstCursor eventHandler initApp theme id) $ AppState
        { _appEditor = editor "editor" (str . concat) (Just 1) path
        , _appStatus = Running
        , _appWarning = True
        , _oldPath = path
        }


theme :: AppState -> AttrMap
theme state =
    let
        color = if state ^. appWarning then red else green
    in
        attrMap (Attr Default Default Default)
            [("edit", Attr Default (SetTo color) Default)]


initApp :: AppState -> EventM AppState
initApp state =
    return (state & appEditor %~ applyEdit gotoEOL)


draw :: AppState -> [Widget]
draw state =
    [
    str ("Old name: " ++ state ^. oldPath)
    <=>
    (str "New name: " <+> renderEditor (state ^. appEditor))
    ]


eventHandler :: AppState -> Event -> EventM (Next AppState)
eventHandler state ev =
    case ev of
        EvKey (KChar 'c') [MCtrl] ->
            halt (state & appStatus .~ Terminated)
        EvKey KEsc [] ->
            halt (state & appStatus .~ Canceled)
        EvKey (KChar '\t') [] -> do
            next <- liftIO (setPath state <$> completeFile (getPath state))
            object <- liftIO (objectAt (getPath next))
            continue (next & appWarning .~ (object /= DoesNotExist))
        EvKey KEnter [] ->
            if state ^. appWarning then
                continue state
            else
                halt (state & appStatus .~ Confirmed (getPath state))
        _ -> do
            next <- handleEventLensed state appEditor ev
            object <- liftIO (objectAt (getPath next))
            continue (next & appWarning .~ (object /= DoesNotExist))
    where
        getPath :: AppState -> FilePath
        getPath state =
            concat (getEditContents (state ^. appEditor))

        setPath :: AppState -> FilePath -> AppState
        setPath state path =
            state
                & appEditor
                . editContentsL
                .~ gotoEOL (stringZipper [path] (Just 1))

