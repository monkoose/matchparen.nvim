(module matchparen.syntax
  {autoload {a matchparen.aniseed.core
             opts matchparen.defaults
             utils matchparen.utils}})

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

(defn- last-three-synids [pos]
  "Returns array with last 3 syntax ids
  under the `line` and `col` position."
  (let [synids (f.synstack (a.inc pos.line)
                           (a.inc pos.col))
        len (length synids)]
    [(. synids len)
     (. synids (- len 1))
     (. synids (- len 2))]))

(defn- synname [synid]
  "Returns name of the syntax id group."
  (-> synid
      (f.synIDattr "name")
      (string.lower)))

(defn- belong-to-skip? [synid]
  "Returns true when synid's name contained in `syntax-skip`."
  (-> synid
      (synname)
      (utils.string-contains-any? syntax-skip)))

(defn- in-syntax-skip? [pos]
  "Returns true when `line`, `col` position is inside
  any of `syntax-skip` groups."
  (-> pos
      (last-three-synids)
      (a.some belong-to-skip?)))

(defn- in-skip-region? [pos]
  "Returns true when `line`, `col` position is inside skip region."
  (if (utils.inside-closed-fold?)
      false
      (in-syntax-skip? pos)))

(defn skip-by-region [pos]
  "Return skip function accepted by `search.match-pos`."
  (when syntax-on?
    (if (in-skip-region? pos)
        #(if (in-skip-region? $) 0 1)
        #(if (in-skip-region? $) 1 0))))
