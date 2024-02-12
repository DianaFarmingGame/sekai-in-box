#lang racket/base

(require racket/file)
(require racket/string)
(require racket/path)

(define cwd (find-system-path 'orig-dir))

(define gsses
  (find-files (λ (path) (or (string-suffix? (path->string (file-name-from-path path)) ".gss.txt")
                            (string-suffix? (path->string (file-name-from-path path)) ".gsm.gd")))
              (build-path cwd "define")))

(define rel-paths (map (λ (path) (find-relative-path cwd path)) gsses))

(set! rel-paths (sort rel-paths (λ (a b) (< (length (explode-path a)) (length (explode-path b))))))

(for-each (λ (path) (printf "found: ~a/\n" (path->string path))) rel-paths)

(define execs (apply append (map (λ (path) `(sekai/exec(,(string-replace (path->string path) "\\" "/")))) rel-paths)))

(define o (open-output-string))
(write execs o)
(define execs-str (get-output-string o))

(define content (substring execs-str 1 (- (string-length execs-str) 1)))

(with-output-to-file (build-path ".define.gss.txt") #:exists 'replace #:mode 'text
  (lambda () (printf content)))

(printf "all complete!")
