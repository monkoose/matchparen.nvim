(module matchparen.highlight
  {autoload {nvim matchparen.aniseed.nvim
             utils matchparen.utils
             search matchparen.search}})

(def- options
  (. (require "matchparen.defaults") :options))

(defn- delete-extmark [id]
  (nvim.buf_del_extmark 0 options.namespace id))

(defn- hide-extmark [id])

(defn pcall-update [])

(defn remove [])

(defn update-on-tick [])
