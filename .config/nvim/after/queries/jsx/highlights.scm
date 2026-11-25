;; extends

; function bodies inside JSX expressions are JS, not markup
((statement_block) @_block
  (#set! @_block bo.commentstring "// %s"))
