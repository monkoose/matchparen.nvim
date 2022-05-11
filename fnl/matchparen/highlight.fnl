(module matchparen.highlight
  {autoload {utils matchparen.utils
             a matchparen.aniseed.core
             opts matchparen.defaults
             nvim matchparen.nvim
             search matchparen.search}})

(def- buf nvim.buf)

(defn- set-extmark [line col opts]
  "Wrapper for nvim_buf_set_extmark()."
  (buf.set_extmark 0 opts.namespace
                   line col opts))

(defn- create-extmark []
  "Creates extmark and returns it's id."
  (set-extmark 0 0 {}))

(def- extmarks
  ;; Creates extmarks for each buffer
  (setmetatable
    {:hidden true}
    {:__index (fn [t k]
                (let [bufnr {:cursor (create-extmark)
                             :match (create-extmark)}]
                  (rawset t k bufnr)
                  bufnr))}))

(defn- move-extmark [line col id]
  "Move extmark with `id` to a `line`, `col` position."
  (buf.set_extmark line col
                   {:end_col (a.inc col)
                    :hl_group opts.hl_group
                    :id id}))

(defn- hide-extmark [id]
  "Hides extmark with `id`."
  (set-extmark 0 0 {:id id}))

(defn- highlight-brackets [cur mat]
  "Highlights brackets."
  (when extmarks.hidden
    (tset extmarks :hidden false))
  (let [bufnr (nvim.get_current_buf)]
    (move-extmark cur.line
                  cur.col
                  (. extmarks bufnr :cursor))
    (move-extmark mat.line
                  mat.col
                  (. extmarks bufnr :match))))

(defn- get-bracket [col insert?]
  "Returns matched bracket and it's column."
  (let [text (nvim.get_current_line)
        insert? (or insert? utils.insert-mode?)]
    (if (and (< 0 col) insert?)
      nil)))

(defn clear-extmarks [bufnr]
  "Removes `bufnr` key from `extmarks` table."
  (tset extmarks bufnr nil))

(defn hide []
  "Unhighlights brackets."
  (when (not extmarks.hidden)
    (tset extmarks :hidden true)
    (let [bufnr (nvim.get_current_buf)]
      (hide-extmark (. extmarks bufnr :cursor))
      (hide-extmark (. extmarks bufnr :match)))))

(defn update [insert?]
  "Highlight brackets pair when cursor is on one of them,
  otherwise hide previous highlight."
  (set vim.g.matchparen_tick (buf.get_changedtick 0))
  (var hide? true)
  (local [line col] (utils.get-cursor-pos))
  (when (not (utils.inside-closed-fold? line))
    (local [match-bracket col] (get-bracket col insert?))
    (when match-bracket
      (local (m-line m-col) (search.match-pos match-bracket line col))
      (when m-line
        (set hide? false)
        (highlight-brackets {:line line :col col}
                            {:line m-line :col m-col}))))
  (when hide?
    (hide)))

(defn update-on-tick []
  "Updates highlighting only if changedtick doesn't match
  cached changedtick."
  (when (not= vim.g.matchparen_tick
              (buf.get_changedtick 0))
    (update)))
