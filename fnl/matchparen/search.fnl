(module matchparen.search
  {autoload {a matchparen.aniseed.core
             nvim matchparen.nvim
             opts matchparen.defaults
             utils matchparen.utils}})

(defn- forward-matches [pattern pos count]
  (local lines (utils.get-lines pos.line count))
  (var i 1)
  (local get-text #(. lines i))
  (var text (get-text))
  (var index (a.inc pos.col))
  (var capture nil)
  (fn []
    (while text
      (set (index capture) (utils.find-forward text
                                               pattern
                                               index))
      (if index
          (let [match-line (a.dec (+ pos.line i))
                match-col (a.dec index)
                match-pos {:line match-line :col match-col}]
            (values match-pos capture))
          (do
            (set i (a.inc i))
            (set text (get-text)))))))

(defn- backward-matches [pattern pos count]
  (local start (math.max 0 (- pos.line count)))
  (local lines (utils.get-line start
                               (a.inc (- pos.line start))))
  (var i (length lines))
  (local get-text #(. lines i))
  (var test (get-text))
  (var index (a.inc pos.col))
  (var capture nil)
  (fn []
    (while text
      (set (index capture) (utils.find-backward (string.reverse text)
                                                pattern
                                                index))
      (if index
          (let [match-line (+ i (- pos.line
                                   (length lines)))
                match-col (a.dec index)
                match-pos {:line match-line :col match-col}]
            (values match-pos capture))
          (do
            (set i (a.dec i))
            (set text (get-text)))))))

(defn find [pattern pos backward? count skip]
  (let [skip (or skip #())
        matches (if backward?
                    backward-matches
                    forward-matches)]))
