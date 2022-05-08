(module matchparen.treesitter
  {autoload {a matchparen.aniseed.core
             nvim matchparen.aniseed.nvim
             opts matchparen.defaults
             utils matchparen.utils}})

(def- cache {:trees {}
             :skip-nodes {}})
(def- ts-skip ["string"
               "comment"])
(def highlighter nil)

(defn- in-node-range? [node line col]
  "True when `line` and `col` position in the `node` range."
  (local (startline startcol endline endcol) (node:range))
  (if (<= startline line endline)
      (if (= line startline endline) (and (<= startcol col)
                                          (< col endcol))
          (= line startline) (<= startcol col)
          (= line endline) (< col endcol)
          true)
      false))

(defn- cache-nodes [line]
  "Caches `line` skip nodes."
  (tset cache.skip-nodes line [])
  (each [_ tree (ipairs cache.trees)]
    (local iter (tree.query:iter_captures tree.root
                                          highlighter.bufnr
                                          line
                                          (a.inc line)))
    (each [id node iter]
      (when (vim.tbl_contains ts-skip (. tree.query.captures id))
        (table.insert (. cache.skip-nodes line) node)))))

(defn- get-skip-node [line col parent]
  (when (not (. cache.skip-nodes line))
    (pcall cache-nodes line))
  (var skip-node nil)
  (each [_ node (ipairs (. cache.skip-nodes line))
         :until skip-node]
    (when (in-node-range? node line col)
      (set skip-node node)))
  skip-node)

(defn- get-trees []
  "Returns all compliant treesitter trees."
  (local trees {})
  (highlighter.tree:for_each_tree
    (fn [tstree tree]
      (when tstree
        ;; Some injected language may not have highlight queries
        (local query (-> cache.highlighter
                         (: :get_query (tree:lang))
                         (: :query)))
        (when query
          (table.insert trees {:root (tstree:root)
                               :query query}))))
    true)
  trees)

(defn- string-node? [node]
  "True when `node` is of type string."
  (utils.string-contains? (node:type) "string"))

(defn- comment-node? [node]
  "True when `node` is of type comment."
  (utils.string-contains? (node:type) "comment"))

(defn- in-skip-region? [line col parent]
  (if (utils.inside-closed-fold line)
      false
      (not= nil (get-skip-node line col))))

(defn- get-sibling-position [backward?]
  (if backward?
      "prev_sibling"
      "next_sibling"))

(defn- get-sibling-node [node sibling-pos]
  ((. node sibling-pos) node))

(defn- skip-by-node? [node backward]
  (local get-sibling (if backward?
                         "prev_sibling"
                         "next_sibling"))
  (fn [l c]
    (if (not c)
      0
      (while node))))


(defn- limit-by-node [node backward?]
  (fn [line col]
    (if (not col)
      false
      (let [sibling-pos (get-sibling-position
                          backward?)]
        (stop-search? node line col sibling-pos)))))

(defn get-highlighter []
  "Return highlighter for a current buffer."
  (->> (nvim.get_current_buf)
       (. vim.treesitter.highlighter.active)))

;; TODO: skip-and-stop
