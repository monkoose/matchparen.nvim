(module matchparen.utils
  {autoload {a matchparen.aniseed.core
             nvim matchparen.nvim}})

(def- f vim.fn)
(def- buf nvim.buf)
(def- win nvim.win)

(defn inside-closed-fold? [line]
  "True if `line` is inside closed fold."
  (not= -1 (f.foldclosed (a.inc line))))

(defn insert-mode? []
  "True in insert or Replace modes."
  (let [mode (. (nvim.get_mode) :mode)]
    (or (= mode "i")
        (= mode "R"))))

(defn string-contains? [str pattern]
  "True when `str` contains `pattern`."
  (not= (str:find pattern 1 true)
        nil))

(defn string-contains-any? [str table-of-strings]
  "True when `str` contains any pattern from the `table-of-strings`."
  (a.some #(string-contains? str $) table-of-strings))

(defn get-cursor-pos []
  "Return seq table with line and column of the cursor position."
  (let [[line col] (win.get_cursor 0)]
    {:line (a.dec line)
     :col col}))

;; TODO: make it find pattern under the cursor
(defn find-forward [text pattern init]
  "Returns first index of the match if any, also
  if `pattern` in a capture return it too"
  (let [i (if init (a.inc init))
        (index _ capture) (string.find text pattern i)]
    (values index capture)))

(defn find-backward [reversed-text pattern init]
  "Returns last index of the match of reversed text if any,
  also if `pattern` in a capture return it too"
  (let [len (a.inc (length reversed-text))
        i (if init (- len init))
        (index capture) (find-forward reversed-text pattern i)]
    (if index
      (values (- len index) capture))))

(defn get-lines [line count]
  "Returns array of `count` lines of text
  from the current buffer beginning from `start`."
  (buf.get_lines 0 line (+ line count) false))
