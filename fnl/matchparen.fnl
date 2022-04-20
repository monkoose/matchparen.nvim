(module matchparen
  {autoload {nvim matchparen.aniseed.nvim
             defaults matchparen.defaults
             hl matchparen.highlight}})

(def- f vim.fn)
(def- opts defaults.options)

(defn- disable-builtin []
  "Disables builtin matchparen plugin."
  (set vim.g.loaded_matchparen 1)
  (when (not= (f.exists ":NoMatchParen") 0)
    (nvim.command "NoMatchParen")))

(defn- create-namespace []
  "Creates namespace used by the plugin."
  (tset opts :namespace
        (nvim.create_namespace
          opts.augroup_name)))

(defn- augroup-exists [name]
  "True when augroup with `name` exists."
  (not= 0 (f.exists (.. "#" name))))

(defn- split-matchpairs []
  "Creates table with opening brackets as keys
  and closing brackets as values."
  (collect [_ pair (ipairs (vim.opt.matchpairs:get))]
    (let [(left right) (pair:match "(.+):(.+)")]
      (values left right))))

(defn- update-matchpairs []
  "Sets new value of table of matchpairs only when required."
  (when (not= opts.cached-matchpairs
              vim.o.matchpairs)
    (tset opts :cached-matchpairs vim.o.matchpairs)
    (tset opts :matchpairs {})
    (each [l r (pairs (split-matchpairs))]
      (tset opts.matchpairs l
            {:left l :right r :backward false})
      (tset opts.matchpairs r
            {:left l :right r :backward true}))))

(defn- create-autocmds []
  "Creates augroup and contained autocmds which are
  ruquired for proper work of the plugin."
  (when (not (augroup-exists opts.augroup_name))
    (local group
      (nvim.create_augroup opts.augroup_name {}))
    (fn autocmd [events callback adds]
      (var options {: group : callback})
      (when adds
        (set options
             (vim.tbl_extend "error" options adds))))
    (autocmd [:CursorMoved :CursorMovedI :WinEnter]
             #(hl.pcall-update))
    (autocmd :InsertEnter
             #(hl.pcall-update true))
    (autocmd [:TextChanged :TextChangedI]
             #(hl.update-on-tick))
    (autocmd [:WinLeave :BufLeave]
             #(hl.remove))
    (autocmd [:WinEnter :BufWinEnter :FileType]
             update-matchpairs)
    (autocmd :OptionSet
             update-matchpairs
             {:pattern "matchpairs"})
    ))

(defn- delete-autocmds []
  "Deletes plugin's augroup and clears all it's autocmds."
  (when (augroup-exists opts.augroup_name)
    (nvim.del_augroup_by_name opts.augroup_name)))

(defn- enable []
  "Enables the plugin."
  (create-autocmds)
  (update-matchpairs)
  (hl.pcall-update))

(defn- disable []
  "Disables the plugin."
  (delete-autocmds)
  (hl.remove))

(defn- create-commands []
  "Create plugin's custom commands."
  (nvim.add_user_command
    "MatchParenEnable"
    enable
    {})
  (nvim.add_user_command
    "MatchParenDisable"
    disable
    {}))

(defn setup [config]
  "Initializes the plugin."
  (disable-builtin)
  (defaults.update config)
  (create-commands)
  (create-namespace)
  (update-matchpairs)
  (tset config :extmarks {:current 0
                          :match 0})
  (when opts.on_startup
    (create-autocmds)))
