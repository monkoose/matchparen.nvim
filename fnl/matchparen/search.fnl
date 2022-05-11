(module matchparen.search
  {autoload {a matchparen.aniseed.core
             nvim matchparen.nvim
             opts matchparen.defaults
             utils matchparen.utils}})

(defn- forward-matches [pattern line col count]
  (local lines (utils.get-lines line count))
  (var i 1)
  (var text (. lines i))
  (var index (a.inc col))
  (var capture nil)
  (fn []
    (while text
      (set (index capture) (utils.find-forward text pattern index))
      (if index
          (let [match-line (a.dec (+ line i))]
            (values match-line (a.dec index) capture))
          (do
            (set i (a.inc i))
            (set text (. lines i)))))))

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
