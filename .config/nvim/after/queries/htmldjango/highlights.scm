;; extends

; otherwise the injected html commentstring wins, which keeps the template tags active
((template) @_template
  (#set! @_template bo.commentstring "{# %s #}"))
