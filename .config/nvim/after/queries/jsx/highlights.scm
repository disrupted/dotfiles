;; extends

; JS nested in JSX, drafted for upstream nvim-treesitter
((statement_block) @_statement_block
  (#set! @_statement_block bo.commentstring "// %s"))

((arguments) @_arguments
  (#set! @_arguments bo.commentstring "// %s"))
