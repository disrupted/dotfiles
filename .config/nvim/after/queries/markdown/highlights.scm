;; extends

; GitHub issue/PR number
(paragraph (inline "#") @_inline (#match? @_inline "^([cC]lose[sd]?|[fF]ix(e[sd])?|[rR]esolve[sd]?|[rR]elate[sd] to) #[0-9]+")) @keyword
