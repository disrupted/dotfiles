;; extends

; otherwise the injected yaml commentstring wins over the ftplugin
((template) @_template
  (#set! @_template bo.commentstring "{{/* %s */}}"))
