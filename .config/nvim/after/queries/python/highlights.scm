;; extends

;; Decorators (old)

 ; ((decorator "@" @function)
 ;  (#set! "priority" 101))

; (decorator) @function
;  ((decorator (attribute (identifier) @function))
;   (#match? @function "^([A-Z])@!.*$"))
;  (decorator) @function
;  ((decorator (identifier) @function)
;   (#match? @function "^([A-Z])@!.*$"))

;; Decorators (new)

((decorator "@" @function)
 (#set! "priority" 101))

(decorator
  (identifier) @function)
(decorator
  (attribute
    attribute: (identifier) @function))
(decorator
  (call (identifier) @function))
(decorator
  (call (attribute
          attribute: (identifier) @function)))

((decorator
  (identifier) @function.builtin)
 (#any-of? @function.builtin "classmethod" "staticmethod" "property"))
