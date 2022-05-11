(fn index [prefix]
  {:__index
   (fn [t k]
     (local func (. vim.api (.. prefix k)))
     (when func (rawset t k func))
     func)})

(setmetatable
  {:buf (setmetatable {} (index "nvim_buf_"))
   :win (setmetatable {} (index "nvim_win_"))
   :tab (setmetatable {} (index "nvim_tabpage_"))}
  (index "nvim_"))
