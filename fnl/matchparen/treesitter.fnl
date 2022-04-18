(module matchparen.treesitter
  {autoload {a matchparen.aniseed.core
             nvim matchparen.aniseed.nvim
             utils matchparen.utils}})

(def- options
  (. (require "matchparen.defaults") :options))
(def- cache {:trees {}
             :root nil
             :highlighter {}
             :skip-nodes {}})

(defn- in-node-range? [node line col]
  "True when `line` and `col` position in the `node` range."
  (local (startline startcol endline endcol)
    (node:range))
  (if (<= startline line endline)
    (if (= line startline endline)
      (and (<= startcol col)
           (< col endcol))
      (= line startline) ;; elseif
      (<= startcol col)
      (= line endline) ;; elseif
      (< col endcol)
      true) ;; else
    false))

(defn- node-at-pos [line col]
  "Return treesitter node at `line` and `col` position."
  (cache.root:descendant_for_range line col
                                   line (a.inc col)))

(defn- cache-nodes [line tree iter]
  (each [id node [iter]]
    (when (vim.tbl_contains options.ts_skip_groups
                            (. tree.query.captures id))
      (table.insert (. cache.skip-nodes line) node))))

(defn- get-skip-node [line col parent]
  (if (and parent
           (not= parent
                 (: (node-at-pos line col)
                    :parent)))
    true
    (do
      (when (not (. cache.skip-nodes line))
        (tset cache.skip-nodes line {})
        (each [_ tree (ipairs cache.trees)]
          (let [iter (tree.query:iter_captures
                       tree.root
                       cache.highlighter.bufnr
                       line
                       (a.inc line))]
            (cache-nodes line tree iter))))
      (var skip-node nil)
      (each [_ node (ipairs (. cache.skip-nodes line))
             :until skip-node]
        (when (in-node-range? node line col)
          (set skip-node node)))
      skip-node)))

(defn- get-trees []
  "Return all compliant treesitter trees."
  (local trees {})
  (cache.highlighter.tree:for_each_tree
    (fn [tstree tree]
      (when tstree
        ;; Some injected language may not have highlight queries
        (local query (-> cache.highlighter
                         (: :get_query (tree:lang))
                         (: :query)))
        (when query
          (table.insert trees
                        {:root (tstree:root)
                         :query query}))))
    true)
  trees)

(defn- comment-node? [node]
  "True when `node` is of type comment."
  (utils.string-contains? (node:type) "comment"))

(defn- get-tree-root []
  "Return treesitter tree root"
  (-> (vim.treesitter.get_parser)
      (: :parse)
      (. 1)
      (: :root)))

(defn- skip-region? [line col parent]
  (if (utils.inside-closed-fold line)
    false
    (not= nil (get-skip-node line col parent))))

(defn- get-sibling-position [backward?]
  (if backward?
    "prev_sibling"
    "next_sibling"))

(defn- get-sibling-node [node sibling-pos]
  ((. node sibling-pos) node))

(defn- stop-search? [node line col sibling-pos]
  "Return true when search should stop further processing."
  (if (in-node-range? node line col)
    false ;; do not stop if position in a node range
    (if (not (comment-node? node))
      true ;; stop if not in a node range and node isn't comment
      (let [sibling (get-sibling-node node
                                      sibling-pos)]
        (if (not (and sibling
                      (comment-node? sibling)))
          true ;; stop when no sibling or sibling isn't comment
          (stop-search? sibling line col sibling-pos))))))

(defn- limit-by-node [node backward?]
  (fn [line col]
    (if (not col)
      false
      (let [sibling-pos (get-sibling-position
                          backward?)]
        (stop-search? node line col sibling-pos)))))

(defn get-highlighter []
  "Return highlighter for a current buffer."
  (local bufnr (nvim.get_current_buf))
  (. vim.treesitter.highlighter.active bufnr))

;; TODO: skip-and-stop
