module Components.Container
  ( containerComponent
  , State
  , Action
  ) where

import Prelude
import Components.TodoList as TodoList
import Carpenter (Render, spec', Update)
import Carpenter.Cedar (watchAndCapture')
import Components.Task (Task)
import Components.TodoList (todoListComponent)
import Components.TodoList.Storage (uidKey, tasksKey)
import Control.Monad.Eff.Class (liftEff)
import DOM (DOM)
import DOM.WebStorage (setItem, getItem, getLocalStorage, STORAGE)
import Data.Maybe (fromMaybe)
import React (createClass, ReactClass)

data Action
  = Load
  | TodoListAction TodoList.Action TodoList.TodoList

type State =
  { tasks :: Array Task
  , uid :: Int
  }

containerComponent :: ∀ props. ReactClass props
containerComponent = createClass $ spec' { tasks: [], uid: 0 } Load update render

update :: ∀ props eff. Update State props Action (dom :: DOM, storage :: STORAGE | eff)
update yield _ action _ state = case action of
  Load -> do
    state <- liftEff (do
      localStorage <- getLocalStorage
      tasks <- getItem localStorage tasksKey
      uid <- getItem localStorage uidKey
      pure { tasks: fromMaybe [] tasks, uid: fromMaybe 0 uid }
    )
    yield $ const state

  TodoListAction tlaction todoList -> case tlaction of
    TodoList.Save -> do
      liftEff (do
        localStorage <- getLocalStorage
        setItem localStorage tasksKey todoList.tasks
        setItem localStorage uidKey todoList.uid
      )
      pure state
    _ ->
      pure state

render :: ∀ props. Render State props Action
render dispatch _ state _ =
  watchAndCapture'
    todoListComponent
    (\a s -> dispatch $ TodoListAction a s)
    (TodoList.init state.tasks state.uid)
