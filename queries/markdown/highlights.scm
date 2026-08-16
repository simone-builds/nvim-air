; extends

; Keep the spell checker out of code blocks. `(inline) @spell`
; in the core queries only adds prose to the checker, it does
; not exclude anything, and the language injected into a fence
; carries no spell capture of its own.
(fenced_code_block) @nospell
(indented_code_block) @nospell
