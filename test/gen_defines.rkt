#lang racket/base

(require racket/file)
(require racket/string)
(require racket/path)

(define cwd (find-system-path 'orig-dir))

(define gsses
  (find-files (λ (path) (string-suffix? (path->string (file-name-from-path path)) ".gss.txt"))
              (build-path cwd "gss" "define")))

(define rel-paths (map (λ (path) (find-relative-path cwd path)) gsses))
(define execs (apply append (map (λ (path) `(gsx/exec(,(string-append "/" (string-replace (path->string path) "\\" "/"))))) rel-paths)))

(define o (open-output-string))
(write execs o)
(define execs-str (get-output-string o))

(define content (substring execs-str 1 (- (string-length execs-str) 1)))

(with-output-to-file (build-path "gss" "define.gss.txt") #:exists 'replace #:mode 'text
  (lambda () (printf content)))
