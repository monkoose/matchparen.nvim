(module matchparen.utils-test
  {autoload {nvim matchparen.nvim
             utils matchparen.utils}})

; (def- f vim.fn)
(def- win nvim.win)
(vim.cmd "edit test/test.lua")

(deftest inside-closed-fold
  (t.ok? (not (utils.inside-closed-fold? (vim.fn.line ".")))
         "should be false when not in a fold")
  (vim.cmd "normal! zfj")
  (t.ok? (utils.inside-closed-fold? (vim.fn.line "."))
         "should be true when in a fold")
  (vim.cmd "normal! zd"))

(deftest insert-mode?
  (local get-mode nvim.get_mode)
  (set nvim.get_mode #{:mode "i"})
  (t.ok? (utils.insert-mode?)
         "should be true in insert mode")
  (set nvim.get_mode #{:mode "R"})
  (t.ok? (utils.insert-mode?)
         "should be true in Replace mode")
  (set nvim.get_mode get-mode)
  (t.ok? (not (utils.insert-mode?))
         "should be false when not in insert or Replace mode"))

(deftest string-contains?
  (local text "hello, world!")
  (t.ok? (utils.string-contains? text "ello"))
  (t.ok? (utils.string-contains? text "w"))
  (t.ok? (utils.string-contains? "hello(" "("))
  (t.ok? (not (utils.string-contains? "hello(" "[")))
  (t.ok? (not (utils.string-contains? text "illo"))))

(deftest string-contains-any?
  (local text "hello, world!")
  (t.ok? (utils.string-contains-any? text ["next"
                                           "previous"
                                           "hello"]))
  (t.ok? (utils.string-contains-any? text ["next"
                                           "previous"
                                           "!"]))
  (t.ok? (not (utils.string-contains-any? text ["next"
                                                "previous"
                                                "line"]))))

(deftest get-cursor-pos
  ;; nvim_win_set_cursor line is 1-based
  (win.set_cursor 0 [2 2])
  (t.pr= [1 2] (utils.get-cursor-pos)))

(deftest find-forward-backward
  (local text "hello( brave( world!")
  (local reversed-text (string.reverse text))
  (t.= 2 (utils.find-forward text "e"))
  (t.= nil (utils.find-forward text "([[])"))
  (t.= 13 (utils.find-forward text "([(])" 6))
  (t.= (values 6 "(") (utils.find-forward text "([(])"))
  (t.= 4 (utils.find-backward (string.reverse "hello") "l"))
  (t.= (values 13 "(") (utils.find-backward reversed-text "([(])"))
  (t.= nil (utils.find-backward text "([[])")))

(deftest get-lines
  (t.pr= ["-- Testing file"
          "-- test get-line"] (utils.get-lines 0 2))
  (t.pr= ["-- test get-line"] (utils.get-lines 1 1)
       "should return correct lines.")
  (t.pr= ["-- last line"] (utils.get-lines 11 10)))
