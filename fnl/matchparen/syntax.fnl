(module matchparen.syntax
  {autoload {a matchparen.aniseed.core
             utils matchparen.utils}})

(def f vim.fn)
(def g vim.g)
(def o vim.o)
(def- options
  (. (require "matchparen.defaults") :options))

(defn- syntax-on? []
  (and (= g.syntax_on 1)
       (not= o.syntax "")))

(defn- get-synname [syn-id]
  (string.lower (f.synIDattr syn-id "name")))

(defn- last-three-synnames [line col]
  "Return iterator with last three syntax group names
  under the `line` and `col` in a current buffer."
  (let [syn-ids (f.synstack (a.inc line)
                             (a.inc col))
        len (length syn-ids)
        last-three [(. syn-ids len)
                    (. syn-ids (- len 1))
                    (. syn-ids (- len 2))]
        len (length last-three)]
    (var index 0)
    (fn []
      (set index (a.inc index))
      (if (<= index len)
        (get-synname (. last-three index))))))

(defn- in-syntax-skip-region? [line col]
  (var result false)
  (each [synname (last-three-synnames line col)
         :until result]
    (set result
         (utils.string-contains-any?
           synname options.syntax_skip_groups)))
  result)

(defn- skip-region? [line col]
  (if (utils.inside-closed-fold line)
    false
    (in-syntax-skip-region? line col)))

(defn skip-by-region [line col]
  "Return skip function accepted by `search.match-pos`."
  (when syntax-on?
    (if (skip-region? line col)
      #(not (skip-region? $1 $2))
      #(skip-region? $1 $2))))
