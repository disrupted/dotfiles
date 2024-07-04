;; extends

;; Pydocs: inject ReStructuredText

; module docstring
; (module . (expression_statement (string) @string.documentation))

; class docstring
(class_definition
  body: (block .
    (expression_statement
      (string
        (string_content) @injection.content (#set! injection.language "rst")
      )
    )
  )
)

; function/method docstring
(function_definition
  body: (block .
    (expression_statement
      (string
        (string_content) @injection.content (#set! injection.language "rst")
      )
    )
  )
)

; attribute docstring
; ((expression_statement (assignment)) . (expression_statement (string) @string.documentation))
