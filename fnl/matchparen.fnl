(module matchparen
  {autoload {nvim matchparen.aniseed.nvim
             opts matchparen.defaults
             hl matchparen.highlight}})

(def- f vim.fn)
(def- options opts.options)

(defn- create-commands []
  (nvim.add_user_command
    "MatchParenEnable"
    "lua require('matchparen.matchpairs').enable()"
    {})
  (nvim.add_user_command
    "MatchParenDisable"
    "lua require('matchparen.matchpairs').disable()"
    {}))

(defn- disable-builtin []
  (set vim.g.loaded_matchparen 1)
  (when (not= (f.exists ":NoMatchParen") 0)
    (nvim.command "NoMatchParen")))

(defn- create-namespace []
  (tset options :namespace
        (nvim.create_namespace
          options.augroup_name)))

(defn- augroup-exists [name]
  (not= 0 (f.exists (.. "#" name))))

(defn- create-autocmds []
  (when (not (augroup-exists options.augroup_name))
    (local group
      (nvim.create_augroup options.augroup_name {}))
    (nvim.create_autocmd [:CursorMoved :CursorMovedI :WinEnter]
                         {: group
                          :callback #(hl.pcall-update)})
    (nvim.create_autocmd :InsertEnter
                         {: group
                          :callback #(hl.pcall-update true)})
    (nvim.create_autocmd [:TextChanged :TextChangedI]
                         {: group
                          :callback #(hl.update-on-tick)})
    (nvim.create_autocmd [:WinLeave :BufLeave]
                         {: group
                          :callback #(hl.remove)})
    (nvim.create_autocmd [:WinEnter :BufWinEnter
                          :FileType :VimEnter]
                         {: group
                          :callback update-matchpairs})
    (nvim.create_autocmd :OptionSet
                         {: group
                          :pattern "matchpairs"
                          :callback update-matchpairs})
    ))

(defn- delete-autocmds []
  (when (augroup-exists options.augroup_name)
    (nvim.del_augroup_by_name options.augroup_name)))

(defn- split-matchpairs []
  (collect [_ pair (ipairs (vim.opt.matchpairs:get))]
    (let [(left right) (pair:match "(.+):(.+)")]
      (values left right))))

(defn- update-matchpairs []
  (when (not= options.cached-matchpairs
              vim.o.matchpairs)
    (tset options :cached-matchpairs vim.o.matchpairs)
    (tset options :matchpairs {})
    (each [l r (pairs (split-matchpairs))]
      (tset options.matchpairs l
            {:left l :right r :backward false})
      (tset options.matchpairs r
            {:left l :right r :backward true}))))

(defn- enable []
  (create-autocmds)
  (update-matchpairs)
  (hl.pcall-update))

(defn- disable []
  (delete-autocmds)
  (hl.remove))

(defn setup [config]
  (disable-builtin)
  (opts.update config)
  (create-commands)
  (create-namespace)
  (tset config :extmarks {:current 0
                          :match 0})
  (when opts.on_startup
    (create-autocmds)))
