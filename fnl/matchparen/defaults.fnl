(module matchparen.defaults)

(def options
  {:on_startup true
   :hl_group "MatchParen"
   :augroup_name "matchparen"
   :syntax_skip_groups ["string"
                        "comment"
                        "character"
                        "singlequoute"
                        "escape"
                        "symbol"]
   :ts_skip_groups ["string"
                    "comment"]})

(defn update [new-options]
  (each [option value (pairs new-options)]
    (when (. options option)
      (tset options option value))))
