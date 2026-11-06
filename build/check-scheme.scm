;; build/check-scheme.scm: read every Scheme file given, the way Guix will, to catch unbalanced
;; brackets and stray characters without needing Guix here.  guile build/check-scheme.scm FILE...
(for-each (lambda (c)
            (read-hash-extend c (lambda (ch port) (list 'hash-extended ch (read port)))))
          '(#\~ #\$))
(define ok #t)
(for-each
 (lambda (file)
   (catch #t
     (lambda ()
       (call-with-input-file file
         (lambda (port)
           (set-port-encoding! port "UTF-8")
           (let loop ((x (read port)) (n 0))
             (if (eof-object? x)
                 (format #t "ok    ~a (~a forms)~%" file n)
                 (loop (read port) (+ n 1)))))))
     (lambda (key . args)
       (set! ok #f)
       (format #t "FAIL  ~a: ~a ~s~%" file key args))))
 (cdr (command-line)))
(exit (if ok 0 1))
