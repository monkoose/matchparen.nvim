(module matchparen
  {autoload {nvim matchparen.aniseed.nvim
             a matchparen.aniseed.core
             opts matchparen.defaults
             hl matchparen.highlight}})

(def- f vim.fn)

(defn- augroup-exists [name]
  "True when augroup with `name` exists."
  (not= 0 (f.exists (.. "#" name))))

(defn- command-exists [name]
  "True when command with `name` exists."
  (not= 0 (f.exists (.. ":" name))))

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
    (each [left right (pairs (split-matchpairs))]
      (tset opts.matchpairs left  {: left : right :backward false})
      (tset opts.matchpairs right {: left : right :backward true}))))

(defn- create-autocmds []
  "Creates augroup and contained autocmds which are
  ruquired for the plugin to work."
  (when (not (augroup-exists opts.augroup_name))
    (local group (nvim.create_augroup opts.augroup_name {}))
    ;; autocmd function
    (fn autocmd [events callback conf]
      (local options {: group : callback})
      (when conf
        (a.merge! options conf)))
    ;; autocmds
    (autocmd :InsertEnter #(hl.update true))
    (autocmd [:VimEnter :WinEnter] #(hl.update))
    (autocmd [:CursorMoved :CursorMovedI] #(hl.update))
    (autocmd [:TextChanged :TextChangedI] #(hl.update-on-tick))
    (autocmd [:WinLeave :BufLeave] #(hl.hide))
    (autocmd [:WinEnter :BufWinEnter :FileType] #(update-matchpairs))
    (autocmd :OptionSet #(update-matchpairs) {:pattern "matchpairs"})
    (autocmd [:BufDelete :BufUnload] #(hl.clear-extmarks $1.buf))))

(defn- delete-autocmds []
  "Deletes plugin's augroup and clears all it's autocmds."
  (when (augroup-exists opts.augroup_name)
    (nvim.del_augroup_by_name opts.augroup_name)))

(defn- disable-builtin []
  "Disables builtin matchparen plugin."
  (set vim.g.loaded_matchparen 1)
  (when (command-exists "NoMatchParen")
    (nvim.command "NoMatchParen")))

(defn- enable []
  "Enables the plugin."
  (create-autocmds)
  (update-matchpairs)
  (hl.update))

(defn- disable []
  "Disables the plugin."
  (delete-autocmds)
  (hl.hide))

(defn- create-namespace []
  "Creates namespace used by the plugin."
  (tset opts :namespace
        (nvim.create_namespace opts.augroup_name)))

(defn- create-commands []
  "Create plugin's custom commands."
  (nvim.create_user_command "MatchParenEnable" enable {})
  (nvim.create_user_command "MatchParenDisable" disable {}))

(defn setup [config]
  "Initializes the plugin."
  (disable-builtin)
  (a.merge! opts config)
  (create-namespace)
  (update-matchpairs)
  (create-commands)
  (when opts.on_startup
    (create-autocmds)))
