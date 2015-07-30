#lang racket/base
(require racket/list)

(struct la (ins cont) #:transparent)
(struct fn (name ins) #:transparent) 
; `fn' is the lowest level. always confirmed simplest form.
; these functions cannot be partially applied at top-level.
(struct exp (h t) #:transparent) ; LISP-style s-expression. (lambda . args-list)
(struct v (val type) #:transparent)

(define c (current-output-port))
  
(define (push stk elt) (append stk (list elt)))
(define (pop stk) (car (reverse stk)))
(define (ret-pop stk) (reverse (cdr (reverse stk))))
(define (strcar str) (car (string->list str)))

(define test (exp (la (list "x" "y") (list (exp (fn "-" 2) (list "x" "y")) (exp (fn "+" 2) (list "x" "y")))) '(1 2)))
(define test2 (exp (fn "-" 2) (list (exp (fn "+" 2) '()))))
(define test3 (exp (fn "-" 2) (list (exp (la (list "x") (exp (fn "+" 2) '(1 "x"))) '()))))
(define test4 "+:(+ -):(1 2)") (define test5 "rev:((+ -):(1 2))")
(define test6 "def:(super-+ +:(+:()))") (define test7 "la:((x y) +:(x y))")
(define test8 "def:(++- +:((+ -):()))") (define test9 "def:(la+ la:((x y) +:(x y)))")

(define pfuns (list (fn "+" 2) (fn "-" 2) (fn "*" 2)
                    (fn "rev" 1) (fn "def" 2)
                    (fn "la" 2)))
(define spec (list "def" "la"))
#;(define funs (list (list "+" 2)))

(define (ins q) (if (fn? q) (fn-ins q) (length (la-ins q))))

; test to see if arg `e' is in simplest form. 
(define (app? e) (if (not (exp? e)) #f (= (length (la-ins (exp-h e))) (length (exp-t e)))))
(define (args-needed e) (if (not (exp? e)) 0 (- ((if (fn? (exp-h e)) fn-ins (λ (x) (length (la-ins x)))) (exp-h e)) (length (exp-t e)))))
          #;(map (λ (x) (cond [(fn? (exp-h e)) (- (fn-ins (exp-h e)) (map args-needed (exp-t e)))]
                            [(exp? (exp-h e)) (- (la-ins ()))])))

; (fork (list (fn "+" 2) (fn "-" 2)))
(define (fork t) (let ([z (mk-args (ins (car t)))])
  (la z (map (λ (x) (exp x z)) t))))
; fork!

#;(define (exp->la e) (la '() (e->l (la-cont (exp-h e)) (map (λ (x y) (list x y)) (la-ins (exp-h e)) (exp-t e)))))
#;(define (e->l c vs)
  (cond [(exp? c) (exp (exp-h c) (map (λ (x) (e->l x vs)) (exp-t c)))]
        [(v? c) c]
        [else (second (findf (λ (x) (equal? (car x) c)) vs))]))

(define (expr-args e) ; (+ (+)) -> ([x y z] -> (+ (+ x y) z))
                   ; ((fn + 2) ((fn + 2)))
                   ; make lambda out of functions.
  (if (exp? e) (foldr + (args-needed e) (map expr-args (exp-t e))) 0))
(define (mk-args n) (for/list ([i n]) (list->string (list #\a (integer->char (+ i 48))))))
(define (exp->la e) (let ([x (mk-args (expr-args e))])
  (la x (exp (exp-h e) (app-args (exp-t e) x '())))))
(define (app-args t x n)
  (cond [(empty? t) (append n x)]
        [(and (exp? (car t)) (or (la? (exp-h (car t))) (fn? (exp-h (car t)))))
         (begin (displayln "yes")
         (app-args (cdr t) (drop x (args-needed (car t))) 
                   (push n (exp (exp-h (car t)) (append (exp-t (car t)) (take x (args-needed (car t))))))))]
        [else (app-args (cdr t) x (push n (car t)))]))

(define (app-la e) (al (la-cont (exp-h e)) (map (λ (x y) (list x y)) (la-ins (exp-h e)) (exp-t e))))
(define (al l y)
  (cond [(exp? l) (exp (exp-h l) (map (λ (x) (al x y)) (exp-t l)))]
        [(list? l) (map (λ (x) (al x y)) l)]
        [(member l (map car y)) (second (findf (λ (x) (equal? l (car x))) y))]
        [else l]))

(define (write-spec ls) 
  (if (list? ls) (begin (display "(") (map write-spec ls) (display ")"))
      (cond [(v? ls) (begin (display "(v ") (write-spec (v-val ls)) (write-spec (v-type ls)) (display ")"))] 
            [(exp? ls) (begin (display "(f ") (write-spec (exp-h ls)) (write-spec (exp-t ls)) (display ")"))]
            [else (write ls)])))

(define (string-split-spec str) (map list->string (filter (λ (x) (not (empty? x))) (splt (string->list str) '(())))))
(define (splt str n) (let ([q (if (empty? str) #f (member (car str) (list #\( #\) #\{ #\} #\[ #\] #\:)))])
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
  (cond [(or (and (not (equal? l "-")) (equal? (strcar l) #\-)) (char-numeric? (strcar l))) (v l "Int")]
        [(member (strcar l) (list #\} #\) #\])) (v l "$close")]
        [(equal? (strcar l) #\") (v l "String")]
        [else (v l "Sym")]))
(define (check-parens stk) (map rem-plist (cp stk '())))
#;(define (cp stk n) (displayln stk)
  (cond [(empty? stk) n]
        [(equal? (v-type (car stk)) "$close") (let* ([c (case (v-val (car stk)) [("}") "{"] [("]") "["] [(")") "("] [else '()])]
                                                     [l (λ (x) (and (v? x) (not (equal? (v-val x) c))))])
           (cp (cdr stk) (push (ret-pop (reverse (dropf (reverse n) l))) (reverse (takef (reverse n) l)))))]
        [else (cp (cdr stk) (push n (car stk)))]))
(define (cp stk n)
  (cond [(empty? stk) n]
        [(equal? (v-type (car stk)) "$close") (let* ([c (case (v-val (car stk)) [("}") "{"] [("]") "["] [(")") "("] [else '()])]
                                                     [l (λ (x) (not (equal? (v-val x) c)))])
           (cp (cdr stk) (push (ret-pop (reverse (dropf (reverse n) l))) (v (reverse (takef (reverse n) l))
                                                                            (case c [("{") "Union"] [("[") "List"] [("(") "PList"] [else '()])))))]
        [else (cp (cdr stk) (push n (car stk)))]))
(define (rem-plist a) (if (equal? (v-type a) "PList") (map rem-plist (v-val a)) a))

(define (app-spec e)
  (case (fn-name (exp-h e))
    [("def") (let ([x (if (la? (second (exp-t e))) (second (exp-t e)) (exp->la (second (exp-t e))))])
               (set! pfuns (push pfuns (fn (car (exp-t e)) (length (la-ins x))))) 
               (out-f (car (exp-t e)) x c) '())]
    [("la") (la (car (exp-t e)) (second (exp-t e)))]
    [else e]))

(define (mk-exprs lst) (if (list? lst) (me (reverse lst) '()) lst))
(define (me lst n)
  (cond [(empty? lst) (reverse n)]
        [(list? (car lst)) (me (cdr lst) (push n (mk-exprs (car lst))))]
        [#;(and (v? (car lst)) (equal? (v-val (car lst)) ":"))
         (equal? (car lst) ":")
         (me (cddr lst) (push (ret-pop n) (let ([e (exp (let ([x (mk-exprs (cadr lst))])
                                                           (if (list? x) (fork x) x)) (pop n))])
                          (if (la? (exp-h e)) (app-la e) 
                              (if (member (fn-name (exp-h e)) spec) (app-spec e) e)))))]
        [else (me (cdr lst) (push n (car lst)))]))

(define (sym->fun l)
  (cond [(and (v? l) (equal? (v-type l) "Sym")) (s->f l)]
        [(list? l) (map sym->fun l)] [else l]))
(define (s->f s)
 (let ([x (findf (λ (y) (equal? (fn-name y) (v-val s))) pfuns)]) (if x x (v-val s))))

(define (out-f n e o)
  (fprintf o "def ~a(" n)
  (map (λ (x) (fprintf o "~a," x)) (ret-pop (la-ins e)))
  (fprintf o "~a) {~n" (pop (la-ins e))) (out-pseu (la-cont e) o) (fprintf o "; }~n"))
(define (out-la l o)
  (fprintf o "(~a -> " (la-ins l)) (out-pseu (la-cont l) o) (fprintf o ")"))
(define (out-expr e o)
  (if (fn? (exp-h e)) (fprintf o "~a(" (fn-name (exp-h e)))
      (begin (out-la (exp-h e) o) (fprintf o "(")))
  (map (λ (x) (begin (out-pseu x o) (fprintf o ","))) (ret-pop (exp-t e)))
  (out-pseu (pop (exp-t e)) o) (fprintf o ")"))
(define (out-pseu e p)
  (cond [(list? e) (begin (fprintf p "{") #;(map (λ (x) (out-pseu x p)) e)
                          (map (λ (x) (begin (out-pseu x p) (fprintf p ","))) (ret-pop e))
                          (out-pseu (pop e) p) (fprintf p "}"))]
        [(exp? e) (out-expr e p)]
        [else (if (v? e) (fprintf p "~a" (v-val e)) (fprintf p "~a" e))]))

(define (parse str) (mk-exprs (map sym->fun (check-parens (map lex (string-split-spec str))))))

(define (main)
  (display "> ") (let ([x (parse (read-line))])
    (if (empty? (filter (λ (y) (not (empty? y))) x)) (displayln "EMPTY") (out-pseu x c)) (displayln "") (main)))
(main)