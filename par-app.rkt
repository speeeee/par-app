#lang racket/base
(require racket/list)

(struct la (ins cont) #:transparent)
(struct fn (name ins) #:transparent) 
; `fn' is the lowest level. always confirmed simplest form.
; these functions cannot be partially applied at top-level.
(struct exp (h t) #:transparent) ; LISP-style s-expression. (lambda . args-list)
(struct v (val type) #:transparent)
  
(define (push stk elt) (append stk (list elt)))
(define (pop stk) (car (reverse stk)))
(define (ret-pop stk) (reverse (cdr (reverse stk))))
(define (strcar str) (car (string->list str)))

(define test (exp (la (list "x" "y") (exp (fn "plus" 2) (list "x" "y"))) '(1 2)))
(define test2 (exp (fn "-" 2) (list (exp (fn "+" 2) '()))))

(define pfuns (list (fn "plus" 2)))
#;(define funs (list (list "+" 2)))

; test to see if arg `e' is in simplest form. 
(define (app? e) (if (not (exp? e)) #f (= (length (la-ins (exp-h e))) (length (exp-t e)))))
(define (args-needed e) (if (not (exp? e)) 0 (- ((if (fn? (exp-h e)) fn-ins (λ (x) (length (la-ins x)))) (exp-h e)) (length (exp-t e)))))
          #;(map (λ (x) (cond [(fn? (exp-h e)) (- (fn-ins (exp-h e)) (map args-needed (exp-t e)))]
                            [(exp? (exp-h e)) (- (la-ins ()))])))

#;(define (exp->la e) (la '() (e->l (la-cont (exp-h e)) (map (λ (x y) (list x y)) (la-ins (exp-h e)) (exp-t e)))))
#;(define (e->l c vs)
  (cond [(exp? c) (exp (exp-h c) (map (λ (x) (e->l x vs)) (exp-t c)))]
        [(v? c) c]
        [else (second (findf (λ (x) (equal? (car x) c)) vs))]))

(define (expr-args e) ; (+ (+)) -> ([x y z] -> (+ (+ x y) z))
                   ; ((fn + 2) ((fn + 2)))
                   ; make lambda out of functions.
  (foldr + (args-needed e) (map expr-args (exp-t e))))
(define (exp->la e) (let ([x (for/list ([i (expr-args e)]) (list->string (list #\a (integer->char (+ i 48)))))])
  (la x (exp (exp-h e) (app-args (exp-t e) x '())))))
(define (app-args t x n)
  (cond [(empty? t) (append n x)]
        [(and (exp? (car t)) (or (la? (exp-h (car t))) (fn? (exp-h (car t)))))
         (begin (displayln "yes")
         (app-args (cdr t) (drop x (args-needed (car t))) 
                   (push n (exp (exp-h (car t)) (append (exp-t (car t)) (take x (args-needed (car t))))))))]
        [else (app-args (cdr t) x n)]))

; returns false if simplest form is not achievable.
#;(define (app-la h t) (simplify (la-cont h) (map (λ (x y) (list x y)) (la-ins h) t)))
#;(define (simplify c v)
  (cond [(exp? c) (map simplify (exp-t c))]))

(define (write-spec ls) 
  (if (list? ls) (begin (display "(") (map write-spec ls) (display ")"))
      (cond [(v? ls) (begin (display "(v ") (write-spec (v-val ls)) (write-spec (v-type ls)) (display ")"))] 
            [(exp? ls) (begin (display "(f ") (write-spec (exp-h ls)) (write-spec (exp-t ls)) (display ")"))]
            [else (write ls)])))

(define (string-split-spec str) (map list->string (filter (λ (x) (not (empty? x))) (splt (string->list str) '(())))))
(define (splt str n) (let ([q (if (empty? str) #f (member (car str) (list #\( #\) #\{ #\} #\[ #\] #\! #\; #\,)))])
  (cond [(empty? str) n] ;[(empty? n) (splt (cdr str) (if (char-whitespace? (car str)) n (push n (car str))))]
        [(empty? (pop n)) (splt (cdr str) (if (char-whitespace? (car str)) 
                                              n (if q (append n (list (list (car str)) '())) (push (ret-pop n) (push (pop n) (car str))))))]
        [(char=? (car str) #\") (if (char=? (car (pop n)) #\") 
                                    (splt (cdr str) (append (ret-pop n) (list (push (pop n) #\") '()))) 
                                    (splt (cdr str) (push n (list #\"))))]
        [(char=? (car (pop n)) #\") (splt (cdr str) (push (ret-pop n) (push (pop n) (car str))))]
        [(char-whitespace? (car str)) (splt (cdr str) (push n '()))]
        [q (splt (cdr str) (append n (list (list (car str)) '())))]
        [else (splt (cdr str) (push (ret-pop n) (push (pop n) (car str))))])))

(define (lex l)
  (cond [(or (equal? (strcar l) #\-) (char-numeric? (strcar l))) (v l "Int")]
        [(member (strcar l) (list #\} #\) #\])) (v l "$close")]
        [(equal? (strcar l) #\") (v l "String")]
        [else (v l "Sym")]))
(define (check-parens stk) (cp stk '()))
(define (cp stk n)
  (cond [(empty? stk) n]
        [(equal? (v-type (car stk)) "$close") (let* ([c (case (v-val (car stk)) [("}") "{"] [("]") "["] [(")") "("] [else '()])]
                                                     [l (λ (x) (not (equal? (v-val x) c)))])
           (cp (cdr stk) (push (ret-pop (reverse (dropf (reverse n) l))) (v (reverse (takef (reverse n) l))
                                                                            (case c [("{") "Union"] [("[") "List"] [("(") "PList"] [else '()])))))]
        [else (cp (cdr stk) (push n (car stk)))]))

(define (main)
  (let* ([e (check-parens (map lex (string-split-spec (read-line))))])
    (write-spec e)))