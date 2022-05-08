(module matchparen.syntax
  {autoload {a matchparen.aniseed.core
             opts matchparen.defaults
             utils matchparen.utils}})

; (def- opts (. (require "matchparen.options") :options))
(def- f vim.fn)

(def- syntax-skip
  ["string"
   "comment"
   "character"
   "singlequoute"
   "escape"
   "symbol"])

(defn- syntax-on? []
  "Returns true when built in syntax is on and
  current buffer has syntax for it's filetype."
  (and (= vim.g.syntax_on 1)
       (not= vim.bo.syntax "")))

(defn- get-synname [syn-id]
  "Returns name of the syntax id group."
  (string.lower (f.synIDattr syn-id "name")))

(defn- last-three-synnames [line col]
  "Returns iterator with last three syntax group names
  under the `line` and `col` in the current buffer."
  ;; last three synnames should be more than enough
  ;; to determine syntax group
  (let [syn-ids (f.synstack (a.inc line)
                            (a.inc col))
        len (length syn-ids)
        last-three [(. syn-ids len)
                    (. syn-ids (- len 1))
                    (. syn-ids (- len 2))]]
    (var index 0)
    (fn []
      (set index (a.inc index))
      (if (<= index (length last-three))
          (get-synname (. last-three index))))))

(defn- in-syntax-skip? [line col]
  "Returns true when `line`, `col` position is inside
  any of `syntax-skip` groups."
  (var result false)
  (each [synname (last-three-synnames line col) :until result]
    (set result (utils.string-contains-any? synname syntax-skip)))
  result)

(defn- in-skip-region? [line col]
  "Returns true when `line`, `col` position is inside skip region."
  (if (utils.inside-closed-fold?)
      false
      (in-syntax-skip? line col)))

(defn skip-by-region [line col]
  "Return skip function accepted by `search.match-pos`."
  (when syntax-on?
    (if (in-skip-region? line col)
        #(if (in-skip-region? $1 $2) 0 1)
        #(if (skip-region? $1 $2) 1 0))))
