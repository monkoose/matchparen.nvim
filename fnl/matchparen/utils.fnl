(module matchparen.utils
  {autoload {a matchparen.aniseed.core
             nvim matchparen.aniseed.nvim}})

(def- f vim.fn)

(defn inside-closed-fold? [line-nr]
  "True if `line` is inside closed fold."
  (not= -1 (f.foldclosed (a.inc line-nr))))

(defn insert-mode? []
  "True in insert or Replace modes."
  (let [mode (. (nvim.get_mode) :mode)]
    (or (= mode "i")
        (= mode "R"))))

(defn string-contains? [str pattern]
  "True when `str` contains `pattern`."
  (not= (str:find pattern 1 true)
        nil))

(defn get-cursor-pos []
  "Return line and column of the cursor position."
  (let [[line col] (nvim.win_get_cursor 0)]
    (values (a.dec line) col)))

;; TODO: make it find pattern under the cursor
(defn find-forward [text pattern init]
  "Return first index of the match if any, also
  if `pattern` in a capture return it too"
  (let [(index _ capture)
        (string.find text pattern
                     (if init (a.inc init)))]
    (values index capture)))

(defn find-backward [reversed-text pattern init]
  "Return last index of the match of reversed text if any,
  also if `pattern` in a capture return it too"
  (let [len (a.inc (length reversed-text))
        (index capture) (find-forward
                          reversed-text
                          pattern
                          (if init
                            (- len init)))]
    (if index
      (values (- len index) capture))))

(defn get-line [line]
  "Return text of the `line` in a current buffer."
  (let [[text] (nvim.buf_get_lines 0 line (a.inc line) false)]
    text))

(defn get-reversed-line [line]
  "Return reversed text of the `line` in a current buffer."
  (let [text (get-line line)]
    (if text
      (string.reverse text))))
