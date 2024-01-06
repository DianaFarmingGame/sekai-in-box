#lang racket/base

(require racket/file)
(require racket/string)
(require racket/path)

(define cwd (find-system-path 'orig-dir))

(define gsses
  (find-files (λ (path) (string-suffix? (path->string (file-name-from-path path)) ".gss.txt"))
              (build-path cwd "gss" "define")))

(define rel-paths (map (λ (path) (find-relative-path cwd path)) gsses))
(define execs (map (λ (path) `(gss/exec ,(string-replace (path->string path) "\\" "/"))) rel-paths))
(define content `(block ,@execs))

(write-to-file content (build-path "gss" "define.gss.txt") #:exists 'replace #:mode 'text)