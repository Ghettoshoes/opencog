;
; July 2018 version.
;
; Ad Hoc script to compute word-similarities in four different
; ways. These are:
;
; * cosines between words, using disjuncts as the vector-basis.
; * cosines between words, using cross-connectors as the vector basis.
; * symmetric MI, for each of the above two.
;
; The hypothesis is that the symmetric MI is superior. It seems to be
; a bit slower to compute. It should be additive, in the way that the
; cosines are not.
;
; Just for the hell of it, we'll do the top 2K words, so that's
; 4M additional atoms. A lot but not overwhelming.
;
; So, here we go:
; ALTER DATABASE en_dj_ptwo RENAME TO en_dj_two_sim;
;

(sql-open "postgres:///en_dj_two_sim?user=linas&password=asdf")

; -------------
; Cosines between words, using dj's
(define pca (make-pseudo-cset-api))
(define psa (add-pair-stars pca))
(define pta (add-transpose-api psa))

(define pco (add-pair-cosine-compute pta))
(define bco
	(batch-similarity pta #f "pseudo-cset Cosine-*" 0.0
		(lambda (wa wb) (pco 'right-cosine wa wb))))

(pco 'right-cosine (Word "other") (Word "same")) ; 0.5866011982435116
(bco 'compute-similarity (Word "other") (Word "same"))

(bco 'batch-compute 12)
; Done 10/12 frac=100.0% Time: 2201 Done: 98.5% rate=0.030 prs/sec
; Done 70/72 frac=97.42% Time: 23066 Done: 100.0% rate=0.108 prs/sec

; -------------
; FMI between words, using dj's -- below works
(define pmi (add-symmetric-mi-compute psa))
(define bmi
	(batch-similarity pta #f "pseudo-cset MI-*" -999.0
		(lambda (wa wb) (pmi 'mmt-fmi wa wb))))

(pmi 'mmt-fmi (Word "other") (Word "same")) ; 4.123194356470049
(bmi 'compute-similarity (Word "other") (Word "same"))

(bmi 'batch-compute 12)
; Done 10/12 frac=100.0% Time: 1299 Done: 98.5% rate=0.050 prs/sec
; Done 70/72 frac=97.42% Time: 13926 Done: 100.0% rate=0.179 prs/sec

; ============================================
; Cosines between words, using crosses
(define cra (make-connector-vec-api))
(define crs (add-pair-stars cra))
(define crt (add-transpose-api crs))

(define cco (add-pair-cosine-compute crt))
(define bcr
	(batch-similarity crt #f "Cross Cosine-*" 0.0
		(lambda (wa wb) (cco 'right-cosine wa wb))))

(cco 'right-cosine (Word "other") (Word "same")) ; 0.5853349406547999
(bcr 'compute-similarity (Word "other") (Word "same"))

(bcr 'batch-compute 12)
; Done 10/14 Frac=11.76% Time: 4591 Done: 93.4% Rate=0.002 prs/sec (459.1 sec/pr)

; -------------
; FMI between words, using crossovers -- below works
(define cmi (add-symmetric-mi-compute crs))
(define bci
	(batch-similarity crt #f "Cross MI-*" -999.0
		(lambda (wa wb) (cmi 'mmt-fmi wa wb))))

(cmi 'mmt-fmi (Word "other") (Word "same")) ; 3.2194667964612314
(bci 'compute-similarity (Word "other") (Word "same")) ;

(bci 'batch-compute 12)
; Done 10/12 frac=95.38% Time: 20314 Done: 98.5% rate=-0.00 prs/sec

; -------------
(cog-count-atoms 'SimilarityLink)

(cog-map-type (lambda (atm) (store-atom atm) #f) 'SimilarityLink)
