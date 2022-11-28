;; extends

;; Decorators

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
 (#any-of? @function.builtin "classmethod" "staticmethod" "property")
 (#set! "priority" 120)) ; set higher priority than semantic tokens so that it doesn't get overwritten as `class`
