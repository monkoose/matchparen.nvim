(module matchparen.treesitter
  {autoload {a matchparen.aniseed.core
             nvim matchparen.nvim
             opts matchparen.defaults
             utils matchparen.utils}})

(def- cache {:trees {}
             :skip-nodes {}})
(def- ts-skip ["string"
               "comment"])
(def highlighter nil)

(defn- in-node-range? [node pos]
  "True when `pos` position in the `node` range."
  (local (startline startcol endline endcol) (node:range))
  (if (<= startline pos.line endline)
      (if (= pos.line startline endline) (and (<= startcol pos.col)
                                              (< pos.col endcol))
          (= pos.line startline) (<= startcol pos.col)
          (= pos.line endline) (< pos.col endcol)
          true)
      false))

(defn- line-nodes [tree line]
  (tree.query:iter_captures tree.root
                            highlighter.bufnr
                            line
                            (a.inc line)))

(defn- cache-nodes [line]
  "Caches `line` skip nodes."
  (tset cache.skip-nodes line [])
  (each [_ tree (ipairs cache.trees)]
    (icollect [id node (line-nodes tree line)
               :into (. cache.skip-nodes line)]
      (let [capture (. tree.query.captures id)]
        (when (vim.tbl_contains ts-skip capture)
          node)))))

(defn- get-skip-node [pos]
  "Returns treesitter node at `pos` position
  if it is in `ts-skip` captures list."
  (when (not (. cache.skip-nodes pos.line))
    (pcall cache-nodes pos.line))
  (a.some #(in-node-range? $ pos)
          (. cache.skip-nodes pos.line)))

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

(defn- in-skip-region? [pos]
  (if (utils.inside-closed-fold pos.line)
      false
      (not= nil (get-skip-node pos))))

(defn- get-sibling-position [backward?]
  (if backward?
      "prev_sibling"
      "next_sibling"))

(defn- get-sibling-node [node sibling-pos]
  (let [get-sibling (. node sibling-pos)]
    (get-sibling node)))

(defn- skip-by-node [node backward?]
  (local get-sibling (if backward?
                         "prev_sibling"
                         "next_sibling"))
  (fn [l c]
    (if (not c)
      0
      (while node))))

(defn- fix-string-range? [node pos]
  "Returns true when fix to highlight is required."
  ;; upstream bug that happens in insert mode, causing
  ;; treesitter node:type() return 'string' right after the string
  (if (and node
           (string-node? node)
           (utils.insert-mode?)
           (not (in-node-range? node {:line pos.line
                                      :col (a.inc pos.col)})))
      false
      true))

(defn get-highlighter []
  "Return highlighter for a current buffer."
  (->> (nvim.get_current_buf)
       (. vim.treesitter.highlighter.active)))

(defn skip-by-region [pos backward?]
  "Return skip function accepted by `search.match-pos`."
  (set cache.trees (get-trees))
  (set cache.skip-nodes {})
  (let [skip-node (get-skip-node pos)
        fix (fix-string-range? skip-node pos)]
    (if (and skip-node fix) ; inside string or comment
        (skip-by-node skip-node backward?)
        #(if (in-skip-region? $) 1 0))))
