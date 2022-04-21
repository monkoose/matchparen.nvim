(module matchparen.search
  {autoload {a matchparen.aniseed.core
             nvim matchparen.aniseed.nvim
             utils matchparen.utils}})

(def- opts
  (. (require "matchparen.defaults") :options))

(defn- *match-forward [lines pattern line col]
  (var i 1)
  (local get-text (fn [] (. lines i)))
  (var text (get-text))
  (var index col)
  (var capture nil)
  (fn []
    (while text
      (set (index capture)
           (utils.find-forward text
                               pattern
                               index))
      (if index
        (let [match_line (+ line
                            (a.dec i))
              match_col (a.dec index)]
          (lua "return match_line, match_col, capture"))
        (do
          (set i (a.inc i))
          (set text (get-text)))))))

(defn- find-match [pattern line col skip?]
  (let [col+1 (a.inc col)
        skip? (or skip? #false)
        max-lines (nvim.win_get_height 0)
        lines (utils.get-lines line max-lines)]
    (each [l c cap
           (*match-forward lines pattern line col+1)]
      (if (not (skip? l c cap))
        (lua "return {l, c, cap}")))))

(time (find-match "([(])" (a.dec (vim.fn.line ".")) (a.dec (vim.fn.col "."))))
