;;; prologue-1.asm
;;; The first part of the standard prologue for compiled programs
;;;
;;; Programmer: Mayer Goldberg, 2023

%define T_void 				0
%define T_nil 				1
%define T_char 				2
%define T_string 			3
%define T_closure 			4
%define T_undefined			5
%define T_boolean 			8
%define T_boolean_false 		(T_boolean | 1)
%define T_boolean_true 			(T_boolean | 2)
%define T_number 			16
%define T_integer			(T_number | 1)
%define T_fraction 			(T_number | 2)
%define T_real 				(T_number | 3)
%define T_collection 			32
%define T_pair 				(T_collection | 1)
%define T_vector 			(T_collection | 2)
%define T_symbol 			64
%define T_interned_symbol		(T_symbol | 1)
%define T_uninterned_symbol		(T_symbol | 2)

%define SOB_CHAR_VALUE(reg) 		byte [reg + 1]
%define SOB_PAIR_CAR(reg)		qword [reg + 1]
%define SOB_PAIR_CDR(reg)		qword [reg + 1 + 8]
%define SOB_STRING_LENGTH(reg)		qword [reg + 1]
%define SOB_VECTOR_LENGTH(reg)		qword [reg + 1]
%define SOB_CLOSURE_ENV(reg)		qword [reg + 1]
%define SOB_CLOSURE_CODE(reg)		qword [reg + 1 + 8]

%define OLD_RBP 			qword [rbp]
%define RET_ADDR 			qword [rbp + 8 * 1]
%define ENV 				qword [rbp + 8 * 2]
%define COUNT 				qword [rbp + 8 * 3]
%define PARAM(n) 			qword [rbp + 8 * (4 + n)]
%define AND_KILL_FRAME(n)		(8 * (2 + n))

%define MAGIC				496351

%macro ENTER 0
	enter 0, 0
	and rsp, ~15
%endmacro

%macro LEAVE 0
	leave
%endmacro

%macro assert_type 2
        cmp byte [%1], %2
        jne L_error_incorrect_type
%endmacro

%define assert_void(reg)		assert_type reg, T_void
%define assert_nil(reg)			assert_type reg, T_nil
%define assert_char(reg)		assert_type reg, T_char
%define assert_string(reg)		assert_type reg, T_string
%define assert_symbol(reg)		assert_type reg, T_symbol
%define assert_interned_symbol(reg)	assert_type reg, T_interned_symbol
%define assert_uninterned_symbol(reg)	assert_type reg, T_uninterned_symbol
%define assert_closure(reg)		assert_type reg, T_closure
%define assert_boolean(reg)		assert_type reg, T_boolean
%define assert_integer(reg)		assert_type reg, T_integer
%define assert_fraction(reg)		assert_type reg, T_fraction
%define assert_real(reg)		assert_type reg, T_real
%define assert_pair(reg)		assert_type reg, T_pair
%define assert_vector(reg)		assert_type reg, T_vector

%define sob_void			(L_constants + 0)
%define sob_nil				(L_constants + 1)
%define sob_boolean_false		(L_constants + 2)
%define sob_boolean_true		(L_constants + 3)
%define sob_char_nul			(L_constants + 4)

%define bytes(n)			(n)
%define kbytes(n) 			(bytes(n) << 10)
%define mbytes(n) 			(kbytes(n) << 10)
%define gbytes(n) 			(mbytes(n) << 10)

section .data
L_constants:
	; L_constants + 0:
	db T_void
	; L_constants + 1:
	db T_nil
	; L_constants + 2:
	db T_boolean_false
	; L_constants + 3:
	db T_boolean_true
	; L_constants + 4:
	db T_char, 0x00	; #\nul
	; L_constants + 6:
	db T_string	; "null?"
	dq 5
	db 0x6E, 0x75, 0x6C, 0x6C, 0x3F
	; L_constants + 20:
	db T_string	; "pair?"
	dq 5
	db 0x70, 0x61, 0x69, 0x72, 0x3F
	; L_constants + 34:
	db T_string	; "void?"
	dq 5
	db 0x76, 0x6F, 0x69, 0x64, 0x3F
	; L_constants + 48:
	db T_string	; "char?"
	dq 5
	db 0x63, 0x68, 0x61, 0x72, 0x3F
	; L_constants + 62:
	db T_string	; "string?"
	dq 7
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3F
	; L_constants + 78:
	db T_string	; "interned-symbol?"
	dq 16
	db 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E, 0x65, 0x64
	db 0x2D, 0x73, 0x79, 0x6D, 0x62, 0x6F, 0x6C, 0x3F
	; L_constants + 103:
	db T_string	; "vector?"
	dq 7
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x3F
	; L_constants + 119:
	db T_string	; "procedure?"
	dq 10
	db 0x70, 0x72, 0x6F, 0x63, 0x65, 0x64, 0x75, 0x72
	db 0x65, 0x3F
	; L_constants + 138:
	db T_string	; "real?"
	dq 5
	db 0x72, 0x65, 0x61, 0x6C, 0x3F
	; L_constants + 152:
	db T_string	; "fraction?"
	dq 9
	db 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F, 0x6E
	db 0x3F
	; L_constants + 170:
	db T_string	; "boolean?"
	dq 8
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x3F
	; L_constants + 187:
	db T_string	; "number?"
	dq 7
	db 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x3F
	; L_constants + 203:
	db T_string	; "collection?"
	dq 11
	db 0x63, 0x6F, 0x6C, 0x6C, 0x65, 0x63, 0x74, 0x69
	db 0x6F, 0x6E, 0x3F
	; L_constants + 223:
	db T_string	; "cons"
	dq 4
	db 0x63, 0x6F, 0x6E, 0x73
	; L_constants + 236:
	db T_string	; "display-sexpr"
	dq 13
	db 0x64, 0x69, 0x73, 0x70, 0x6C, 0x61, 0x79, 0x2D
	db 0x73, 0x65, 0x78, 0x70, 0x72
	; L_constants + 258:
	db T_string	; "write-char"
	dq 10
	db 0x77, 0x72, 0x69, 0x74, 0x65, 0x2D, 0x63, 0x68
	db 0x61, 0x72
	; L_constants + 277:
	db T_string	; "car"
	dq 3
	db 0x63, 0x61, 0x72
	; L_constants + 289:
	db T_string	; "cdr"
	dq 3
	db 0x63, 0x64, 0x72
	; L_constants + 301:
	db T_string	; "string-length"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x6C
	db 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 323:
	db T_string	; "vector-length"
	dq 13
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x6C
	db 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 345:
	db T_string	; "real->integer"
	dq 13
	db 0x72, 0x65, 0x61, 0x6C, 0x2D, 0x3E, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72
	; L_constants + 367:
	db T_string	; "exit"
	dq 4
	db 0x65, 0x78, 0x69, 0x74
	; L_constants + 380:
	db T_string	; "integer->real"
	dq 13
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x2D
	db 0x3E, 0x72, 0x65, 0x61, 0x6C
	; L_constants + 402:
	db T_string	; "fraction->real"
	dq 14
	db 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F, 0x6E
	db 0x2D, 0x3E, 0x72, 0x65, 0x61, 0x6C
	; L_constants + 425:
	db T_string	; "char->integer"
	dq 13
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x3E, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72
	; L_constants + 447:
	db T_string	; "integer->char"
	dq 13
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x2D
	db 0x3E, 0x63, 0x68, 0x61, 0x72
	; L_constants + 469:
	db T_string	; "trng"
	dq 4
	db 0x74, 0x72, 0x6E, 0x67
	; L_constants + 482:
	db T_string	; "zero?"
	dq 5
	db 0x7A, 0x65, 0x72, 0x6F, 0x3F
	; L_constants + 496:
	db T_string	; "integer?"
	dq 8
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x3F
	; L_constants + 513:
	db T_string	; "__bin-apply"
	dq 11
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x70
	db 0x70, 0x6C, 0x79
	; L_constants + 533:
	db T_string	; "__bin-add-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x72, 0x72
	; L_constants + 554:
	db T_string	; "__bin-sub-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x72, 0x72
	; L_constants + 575:
	db T_string	; "__bin-mul-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x72, 0x72
	; L_constants + 596:
	db T_string	; "__bin-div-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x72, 0x72
	; L_constants + 617:
	db T_string	; "__bin-add-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x71, 0x71
	; L_constants + 638:
	db T_string	; "__bin-sub-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x71, 0x71
	; L_constants + 659:
	db T_string	; "__bin-mul-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x71, 0x71
	; L_constants + 680:
	db T_string	; "__bin-div-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x71, 0x71
	; L_constants + 701:
	db T_string	; "__bin-add-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x7A, 0x7A
	; L_constants + 722:
	db T_string	; "__bin-sub-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x7A, 0x7A
	; L_constants + 743:
	db T_string	; "__bin-mul-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x7A, 0x7A
	; L_constants + 764:
	db T_string	; "__bin-div-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x7A, 0x7A
	; L_constants + 785:
	db T_string	; "error"
	dq 5
	db 0x65, 0x72, 0x72, 0x6F, 0x72
	; L_constants + 799:
	db T_string	; "__bin-less-than-rr"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x72, 0x72
	; L_constants + 826:
	db T_string	; "__bin-less-than-qq"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x71, 0x71
	; L_constants + 853:
	db T_string	; "__bin-less-than-zz"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x7A, 0x7A
	; L_constants + 880:
	db T_string	; "__bin-equal-rr"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x72, 0x72
	; L_constants + 903:
	db T_string	; "__bin-equal-qq"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x71, 0x71
	; L_constants + 926:
	db T_string	; "__bin-equal-zz"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x7A, 0x7A
	; L_constants + 949:
	db T_string	; "quotient"
	dq 8
	db 0x71, 0x75, 0x6F, 0x74, 0x69, 0x65, 0x6E, 0x74
	; L_constants + 966:
	db T_string	; "remainder"
	dq 9
	db 0x72, 0x65, 0x6D, 0x61, 0x69, 0x6E, 0x64, 0x65
	db 0x72
	; L_constants + 984:
	db T_string	; "set-car!"
	dq 8
	db 0x73, 0x65, 0x74, 0x2D, 0x63, 0x61, 0x72, 0x21
	; L_constants + 1001:
	db T_string	; "set-cdr!"
	dq 8
	db 0x73, 0x65, 0x74, 0x2D, 0x63, 0x64, 0x72, 0x21
	; L_constants + 1018:
	db T_string	; "string-ref"
	dq 10
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x66
	; L_constants + 1037:
	db T_string	; "vector-ref"
	dq 10
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x66
	; L_constants + 1056:
	db T_string	; "vector-set!"
	dq 11
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x73
	db 0x65, 0x74, 0x21
	; L_constants + 1076:
	db T_string	; "string-set!"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x73
	db 0x65, 0x74, 0x21
	; L_constants + 1096:
	db T_string	; "make-vector"
	dq 11
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72
	; L_constants + 1116:
	db T_string	; "make-string"
	dq 11
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67
	; L_constants + 1136:
	db T_string	; "numerator"
	dq 9
	db 0x6E, 0x75, 0x6D, 0x65, 0x72, 0x61, 0x74, 0x6F
	db 0x72
	; L_constants + 1154:
	db T_string	; "denominator"
	dq 11
	db 0x64, 0x65, 0x6E, 0x6F, 0x6D, 0x69, 0x6E, 0x61
	db 0x74, 0x6F, 0x72
	; L_constants + 1174:
	db T_string	; "eq?"
	dq 3
	db 0x65, 0x71, 0x3F
	; L_constants + 1186:
	db T_string	; "__integer-to-fracti...
	dq 21
	db 0x5F, 0x5F, 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65
	db 0x72, 0x2D, 0x74, 0x6F, 0x2D, 0x66, 0x72, 0x61
	db 0x63, 0x74, 0x69, 0x6F, 0x6E
	; L_constants + 1216:
	db T_string	; "logand"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x61, 0x6E, 0x64
	; L_constants + 1231:
	db T_string	; "logor"
	dq 5
	db 0x6C, 0x6F, 0x67, 0x6F, 0x72
	; L_constants + 1245:
	db T_string	; "logxor"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x78, 0x6F, 0x72
	; L_constants + 1260:
	db T_string	; "lognot"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x6E, 0x6F, 0x74
	; L_constants + 1275:
	db T_string	; "ash"
	dq 3
	db 0x61, 0x73, 0x68
	; L_constants + 1287:
	db T_string	; "symbol?"
	dq 7
	db 0x73, 0x79, 0x6D, 0x62, 0x6F, 0x6C, 0x3F
	; L_constants + 1303:
	db T_string	; "uninterned-symbol?"
	dq 18
	db 0x75, 0x6E, 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E
	db 0x65, 0x64, 0x2D, 0x73, 0x79, 0x6D, 0x62, 0x6F
	db 0x6C, 0x3F
	; L_constants + 1330:
	db T_string	; "gensym?"
	dq 7
	db 0x67, 0x65, 0x6E, 0x73, 0x79, 0x6D, 0x3F
	; L_constants + 1346:
	db T_string	; "gensym"
	dq 6
	db 0x67, 0x65, 0x6E, 0x73, 0x79, 0x6D
	; L_constants + 1361:
	db T_string	; "frame"
	dq 5
	db 0x66, 0x72, 0x61, 0x6D, 0x65
	; L_constants + 1375:
	db T_string	; "break"
	dq 5
	db 0x62, 0x72, 0x65, 0x61, 0x6B
	; L_constants + 1389:
	db T_string	; "boolean-false?"
	dq 14
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x2D
	db 0x66, 0x61, 0x6C, 0x73, 0x65, 0x3F
	; L_constants + 1412:
	db T_string	; "boolean-true?"
	dq 13
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x2D
	db 0x74, 0x72, 0x75, 0x65, 0x3F
	; L_constants + 1434:
	db T_string	; "primitive?"
	dq 10
	db 0x70, 0x72, 0x69, 0x6D, 0x69, 0x74, 0x69, 0x76
	db 0x65, 0x3F
	; L_constants + 1453:
	db T_string	; "length"
	dq 6
	db 0x6C, 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 1468:
	db T_string	; "make-list"
	dq 9
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74
	; L_constants + 1486:
	db T_string	; "return"
	dq 6
	db 0x72, 0x65, 0x74, 0x75, 0x72, 0x6E
	; L_constants + 1501:
	db T_string	; "caar"
	dq 4
	db 0x63, 0x61, 0x61, 0x72
	; L_constants + 1514:
	db T_string	; "cadr"
	dq 4
	db 0x63, 0x61, 0x64, 0x72
	; L_constants + 1527:
	db T_string	; "cdar"
	dq 4
	db 0x63, 0x64, 0x61, 0x72
	; L_constants + 1540:
	db T_string	; "cddr"
	dq 4
	db 0x63, 0x64, 0x64, 0x72
	; L_constants + 1553:
	db T_string	; "caaar"
	dq 5
	db 0x63, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1567:
	db T_string	; "caadr"
	dq 5
	db 0x63, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1581:
	db T_string	; "cadar"
	dq 5
	db 0x63, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1595:
	db T_string	; "caddr"
	dq 5
	db 0x63, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1609:
	db T_string	; "cdaar"
	dq 5
	db 0x63, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1623:
	db T_string	; "cdadr"
	dq 5
	db 0x63, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1637:
	db T_string	; "cddar"
	dq 5
	db 0x63, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1651:
	db T_string	; "cdddr"
	dq 5
	db 0x63, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1665:
	db T_string	; "caaaar"
	dq 6
	db 0x63, 0x61, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1680:
	db T_string	; "caaadr"
	dq 6
	db 0x63, 0x61, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1695:
	db T_string	; "caadar"
	dq 6
	db 0x63, 0x61, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1710:
	db T_string	; "caaddr"
	dq 6
	db 0x63, 0x61, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1725:
	db T_string	; "cadaar"
	dq 6
	db 0x63, 0x61, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1740:
	db T_string	; "cadadr"
	dq 6
	db 0x63, 0x61, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1755:
	db T_string	; "caddar"
	dq 6
	db 0x63, 0x61, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1770:
	db T_string	; "cadddr"
	dq 6
	db 0x63, 0x61, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1785:
	db T_string	; "cdaaar"
	dq 6
	db 0x63, 0x64, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1800:
	db T_string	; "cdaadr"
	dq 6
	db 0x63, 0x64, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1815:
	db T_string	; "cdadar"
	dq 6
	db 0x63, 0x64, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1830:
	db T_string	; "cdaddr"
	dq 6
	db 0x63, 0x64, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1845:
	db T_string	; "cddaar"
	dq 6
	db 0x63, 0x64, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1860:
	db T_string	; "cddadr"
	dq 6
	db 0x63, 0x64, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1875:
	db T_string	; "cdddar"
	dq 6
	db 0x63, 0x64, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1890:
	db T_string	; "cddddr"
	dq 6
	db 0x63, 0x64, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1905:
	db T_string	; "list?"
	dq 5
	db 0x6C, 0x69, 0x73, 0x74, 0x3F
	; L_constants + 1919:
	db T_string	; "list"
	dq 4
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 1932:
	db T_string	; "not"
	dq 3
	db 0x6E, 0x6F, 0x74
	; L_constants + 1944:
	db T_string	; "rational?"
	dq 9
	db 0x72, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x61, 0x6C
	db 0x3F
	; L_constants + 1962:
	db T_string	; "list*"
	dq 5
	db 0x6C, 0x69, 0x73, 0x74, 0x2A
	; L_constants + 1976:
	db T_string	; "whatever"
	dq 8
	db 0x77, 0x68, 0x61, 0x74, 0x65, 0x76, 0x65, 0x72
	; L_constants + 1993:
	db T_interned_symbol	; whatever
	dq L_constants + 1976
	; L_constants + 2002:
	db T_string	; "apply"
	dq 5
	db 0x61, 0x70, 0x70, 0x6C, 0x79
	; L_constants + 2016:
	db T_string	; "ormap"
	dq 5
	db 0x6F, 0x72, 0x6D, 0x61, 0x70
	; L_constants + 2030:
	db T_string	; "map"
	dq 3
	db 0x6D, 0x61, 0x70
	; L_constants + 2042:
	db T_string	; "andmap"
	dq 6
	db 0x61, 0x6E, 0x64, 0x6D, 0x61, 0x70
	; L_constants + 2057:
	db T_string	; "reverse"
	dq 7
	db 0x72, 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 2073:
	db T_string	; "fold-left"
	dq 9
	db 0x66, 0x6F, 0x6C, 0x64, 0x2D, 0x6C, 0x65, 0x66
	db 0x74
	; L_constants + 2091:
	db T_string	; "append"
	dq 6
	db 0x61, 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 2106:
	db T_string	; "fold-right"
	dq 10
	db 0x66, 0x6F, 0x6C, 0x64, 0x2D, 0x72, 0x69, 0x67
	db 0x68, 0x74
	; L_constants + 2125:
	db T_string	; "+"
	dq 1
	db 0x2B
	; L_constants + 2135:
	db T_integer	; 0
	dq 0
	; L_constants + 2144:
	db T_string	; "__bin_integer_to_fr...
	dq 25
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x5F, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72, 0x5F, 0x74, 0x6F
	db 0x5F, 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F
	db 0x6E
	; L_constants + 2178:
	db T_interned_symbol	; +
	dq L_constants + 2125
	; L_constants + 2187:
	db T_string	; "all arguments need ...
	dq 32
	db 0x61, 0x6C, 0x6C, 0x20, 0x61, 0x72, 0x67, 0x75
	db 0x6D, 0x65, 0x6E, 0x74, 0x73, 0x20, 0x6E, 0x65
	db 0x65, 0x64, 0x20, 0x74, 0x6F, 0x20, 0x62, 0x65
	db 0x20, 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x73
	; L_constants + 2228:
	db T_string	; "-"
	dq 1
	db 0x2D
	; L_constants + 2238:
	db T_string	; "real"
	dq 4
	db 0x72, 0x65, 0x61, 0x6C
	; L_constants + 2251:
	db T_interned_symbol	; -
	dq L_constants + 2228
	; L_constants + 2260:
	db T_string	; "*"
	dq 1
	db 0x2A
	; L_constants + 2270:
	db T_integer	; 1
	dq 1
	; L_constants + 2279:
	db T_interned_symbol	; *
	dq L_constants + 2260
	; L_constants + 2288:
	db T_string	; "/"
	dq 1
	db 0x2F
	; L_constants + 2298:
	db T_interned_symbol	; /
	dq L_constants + 2288
	; L_constants + 2307:
	db T_string	; "fact"
	dq 4
	db 0x66, 0x61, 0x63, 0x74
	; L_constants + 2320:
	db T_string	; "<"
	dq 1
	db 0x3C
	; L_constants + 2330:
	db T_string	; "<="
	dq 2
	db 0x3C, 0x3D
	; L_constants + 2341:
	db T_string	; ">"
	dq 1
	db 0x3E
	; L_constants + 2351:
	db T_string	; ">="
	dq 2
	db 0x3E, 0x3D
	; L_constants + 2362:
	db T_string	; "="
	dq 1
	db 0x3D
	; L_constants + 2372:
	db T_string	; "generic-comparator"
	dq 18
	db 0x67, 0x65, 0x6E, 0x65, 0x72, 0x69, 0x63, 0x2D
	db 0x63, 0x6F, 0x6D, 0x70, 0x61, 0x72, 0x61, 0x74
	db 0x6F, 0x72
	; L_constants + 2399:
	db T_interned_symbol	; generic-comparator
	dq L_constants + 2372
	; L_constants + 2408:
	db T_string	; "all the arguments m...
	dq 33
	db 0x61, 0x6C, 0x6C, 0x20, 0x74, 0x68, 0x65, 0x20
	db 0x61, 0x72, 0x67, 0x75, 0x6D, 0x65, 0x6E, 0x74
	db 0x73, 0x20, 0x6D, 0x75, 0x73, 0x74, 0x20, 0x62
	db 0x65, 0x20, 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72
	db 0x73
	; L_constants + 2450:
	db T_string	; "char<?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3C, 0x3F
	; L_constants + 2465:
	db T_string	; "char<=?"
	dq 7
	db 0x63, 0x68, 0x61, 0x72, 0x3C, 0x3D, 0x3F
	; L_constants + 2481:
	db T_string	; "char=?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3D, 0x3F
	; L_constants + 2496:
	db T_string	; "char>?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3E, 0x3F
	; L_constants + 2511:
	db T_string	; "char>=?"
	dq 7
	db 0x63, 0x68, 0x61, 0x72, 0x3E, 0x3D, 0x3F
	; L_constants + 2527:
	db T_string	; "char-downcase"
	dq 13
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x64, 0x6F, 0x77
	db 0x6E, 0x63, 0x61, 0x73, 0x65
	; L_constants + 2549:
	db T_string	; "char-upcase"
	dq 11
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x75, 0x70, 0x63
	db 0x61, 0x73, 0x65
	; L_constants + 2569:
	db T_char, 0x41	; #\A
	; L_constants + 2571:
	db T_char, 0x5A	; #\Z
	; L_constants + 2573:
	db T_char, 0x61	; #\a
	; L_constants + 2575:
	db T_char, 0x7A	; #\z
	; L_constants + 2577:
	db T_string	; "char-ci<?"
	dq 9
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3C
	db 0x3F
	; L_constants + 2595:
	db T_string	; "char-ci<=?"
	dq 10
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3C
	db 0x3D, 0x3F
	; L_constants + 2614:
	db T_string	; "char-ci=?"
	dq 9
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3D
	db 0x3F
	; L_constants + 2632:
	db T_string	; "char-ci>?"
	dq 9
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3E
	db 0x3F
	; L_constants + 2650:
	db T_string	; "char-ci>=?"
	dq 10
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3E
	db 0x3D, 0x3F
	; L_constants + 2669:
	db T_string	; "string-downcase"
	dq 15
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x64
	db 0x6F, 0x77, 0x6E, 0x63, 0x61, 0x73, 0x65
	; L_constants + 2693:
	db T_string	; "string-upcase"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x75
	db 0x70, 0x63, 0x61, 0x73, 0x65
	; L_constants + 2715:
	db T_string	; "list->string"
	dq 12
	db 0x6C, 0x69, 0x73, 0x74, 0x2D, 0x3E, 0x73, 0x74
	db 0x72, 0x69, 0x6E, 0x67
	; L_constants + 2736:
	db T_string	; "string->list"
	dq 12
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x3E
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 2757:
	db T_string	; "string<?"
	dq 8
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3C, 0x3F
	; L_constants + 2774:
	db T_string	; "string<=?"
	dq 9
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3C, 0x3D
	db 0x3F
	; L_constants + 2792:
	db T_string	; "string=?"
	dq 8
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3D, 0x3F
	; L_constants + 2809:
	db T_string	; "string>=?"
	dq 9
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3E, 0x3D
	db 0x3F
	; L_constants + 2827:
	db T_string	; "string>?"
	dq 8
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3E, 0x3F
	; L_constants + 2844:
	db T_string	; "string-ci<?"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3C, 0x3F
	; L_constants + 2864:
	db T_string	; "string-ci<=?"
	dq 12
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3C, 0x3D, 0x3F
	; L_constants + 2885:
	db T_string	; "string-ci=?"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3D, 0x3F
	; L_constants + 2905:
	db T_string	; "string-ci>=?"
	dq 12
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3E, 0x3D, 0x3F
	; L_constants + 2926:
	db T_string	; "string-ci>?"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3E, 0x3F
	; L_constants + 2946:
	db T_interned_symbol	; make-vector
	dq L_constants + 1096
	; L_constants + 2955:
	db T_string	; "Usage: (make-vector...
	dq 43
	db 0x55, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x20, 0x28
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72, 0x20, 0x73, 0x69, 0x7A, 0x65
	db 0x20, 0x3F, 0x6F, 0x70, 0x74, 0x69, 0x6F, 0x6E
	db 0x61, 0x6C, 0x2D, 0x64, 0x65, 0x66, 0x61, 0x75
	db 0x6C, 0x74, 0x29
	; L_constants + 3007:
	db T_interned_symbol	; make-string
	dq L_constants + 1116
	; L_constants + 3016:
	db T_string	; "Usage: (make-string...
	dq 43
	db 0x55, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x20, 0x28
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67, 0x20, 0x73, 0x69, 0x7A, 0x65
	db 0x20, 0x3F, 0x6F, 0x70, 0x74, 0x69, 0x6F, 0x6E
	db 0x61, 0x6C, 0x2D, 0x64, 0x65, 0x66, 0x61, 0x75
	db 0x6C, 0x74, 0x29
	; L_constants + 3068:
	db T_string	; "list->vector"
	dq 12
	db 0x6C, 0x69, 0x73, 0x74, 0x2D, 0x3E, 0x76, 0x65
	db 0x63, 0x74, 0x6F, 0x72
	; L_constants + 3089:
	db T_string	; "vector"
	dq 6
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72
	; L_constants + 3104:
	db T_string	; "vector->list"
	dq 12
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x3E
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 3125:
	db T_string	; "random"
	dq 6
	db 0x72, 0x61, 0x6E, 0x64, 0x6F, 0x6D
	; L_constants + 3140:
	db T_string	; "positive?"
	dq 9
	db 0x70, 0x6F, 0x73, 0x69, 0x74, 0x69, 0x76, 0x65
	db 0x3F
	; L_constants + 3158:
	db T_string	; "negative?"
	dq 9
	db 0x6E, 0x65, 0x67, 0x61, 0x74, 0x69, 0x76, 0x65
	db 0x3F
	; L_constants + 3176:
	db T_string	; "even?"
	dq 5
	db 0x65, 0x76, 0x65, 0x6E, 0x3F
	; L_constants + 3190:
	db T_integer	; 2
	dq 2
	; L_constants + 3199:
	db T_string	; "odd?"
	dq 4
	db 0x6F, 0x64, 0x64, 0x3F
	; L_constants + 3212:
	db T_string	; "abs"
	dq 3
	db 0x61, 0x62, 0x73
	; L_constants + 3224:
	db T_string	; "equal?"
	dq 6
	db 0x65, 0x71, 0x75, 0x61, 0x6C, 0x3F
	; L_constants + 3239:
	db T_string	; "assoc"
	dq 5
	db 0x61, 0x73, 0x73, 0x6F, 0x63
	; L_constants + 3253:
	db T_string	; "string-append"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x61
	db 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 3275:
	db T_string	; "vector-append"
	dq 13
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x61
	db 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 3297:
	db T_string	; "string-reverse"
	dq 14
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 3320:
	db T_string	; "vector-reverse"
	dq 14
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 3343:
	db T_string	; "string-reverse!"
	dq 15
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65, 0x21
	; L_constants + 3367:
	db T_string	; "vector-reverse!"
	dq 15
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65, 0x21
	; L_constants + 3391:
	db T_string	; "make-list-thunk"
	dq 15
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74, 0x2D, 0x74, 0x68, 0x75, 0x6E, 0x6B
	; L_constants + 3415:
	db T_string	; "make-string-thunk"
	dq 17
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67, 0x2D, 0x74, 0x68, 0x75, 0x6E
	db 0x6B
	; L_constants + 3441:
	db T_string	; "make-vector-thunk"
	dq 17
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72, 0x2D, 0x74, 0x68, 0x75, 0x6E
	db 0x6B
	; L_constants + 3467:
	db T_string	; "logarithm"
	dq 9
	db 0x6C, 0x6F, 0x67, 0x61, 0x72, 0x69, 0x74, 0x68
	db 0x6D
	; L_constants + 3485:
	db T_real	; 1.000000
	dq 1.000000
	; L_constants + 3494:
	db T_string	; "newline"
	dq 7
	db 0x6E, 0x65, 0x77, 0x6C, 0x69, 0x6E, 0x65
	; L_constants + 3510:
	db T_char, 0x0A	; #\newline
	; L_constants + 3512:
	db T_string	; "void"
	dq 4
	db 0x76, 0x6F, 0x69, 0x64
	; L_constants + 3525:
	db T_string	; "with"
	dq 4
	db 0x77, 0x69, 0x74, 0x68
	; L_constants + 3538:
	db T_string	; "crazy-ack"
	dq 9
	db 0x63, 0x72, 0x61, 0x7A, 0x79, 0x2D, 0x61, 0x63
	db 0x6B
	; L_constants + 3556:
	db T_integer	; 7
	dq 7
	; L_constants + 3565:
	db T_integer	; 61
	dq 61
	; L_constants + 3574:
	db T_integer	; 3
	dq 3
	; L_constants + 3583:
	db T_integer	; 316
	dq 316
	; L_constants + 3592:
	db T_integer	; 5
	dq 5
	; L_constants + 3601:
	db T_integer	; 636
	dq 636
free_var_0:	; location of *
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2260

free_var_1:	; location of +
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2125

free_var_2:	; location of -
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2228

free_var_3:	; location of /
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2288

free_var_4:	; location of <
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2320

free_var_5:	; location of <=
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2330

free_var_6:	; location of =
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2362

free_var_7:	; location of >
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2341

free_var_8:	; location of >=
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2351

free_var_9:	; location of __bin-add-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 617

free_var_10:	; location of __bin-add-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 533

free_var_11:	; location of __bin-add-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 701

free_var_12:	; location of __bin-apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 513

free_var_13:	; location of __bin-div-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 680

free_var_14:	; location of __bin-div-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 596

free_var_15:	; location of __bin-div-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 764

free_var_16:	; location of __bin-equal-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 903

free_var_17:	; location of __bin-equal-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 880

free_var_18:	; location of __bin-equal-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 926

free_var_19:	; location of __bin-less-than-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 826

free_var_20:	; location of __bin-less-than-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 799

free_var_21:	; location of __bin-less-than-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 853

free_var_22:	; location of __bin-mul-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 659

free_var_23:	; location of __bin-mul-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 575

free_var_24:	; location of __bin-mul-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 743

free_var_25:	; location of __bin-sub-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 638

free_var_26:	; location of __bin-sub-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 554

free_var_27:	; location of __bin-sub-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 722

free_var_28:	; location of __bin_integer_to_fraction
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2144

free_var_29:	; location of __integer-to-fraction
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1186

free_var_30:	; location of abs
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3212

free_var_31:	; location of andmap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2042

free_var_32:	; location of append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2091

free_var_33:	; location of apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2002

free_var_34:	; location of assoc
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3239

free_var_35:	; location of caaaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1665

free_var_36:	; location of caaadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1680

free_var_37:	; location of caaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1553

free_var_38:	; location of caadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1695

free_var_39:	; location of caaddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1710

free_var_40:	; location of caadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1567

free_var_41:	; location of caar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1501

free_var_42:	; location of cadaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1725

free_var_43:	; location of cadadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1740

free_var_44:	; location of cadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1581

free_var_45:	; location of caddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1755

free_var_46:	; location of cadddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1770

free_var_47:	; location of caddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1595

free_var_48:	; location of cadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1514

free_var_49:	; location of car
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 277

free_var_50:	; location of cdaaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1785

free_var_51:	; location of cdaadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1800

free_var_52:	; location of cdaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1609

free_var_53:	; location of cdadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1815

free_var_54:	; location of cdaddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1830

free_var_55:	; location of cdadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1623

free_var_56:	; location of cdar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1527

free_var_57:	; location of cddaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1845

free_var_58:	; location of cddadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1860

free_var_59:	; location of cddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1637

free_var_60:	; location of cdddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1875

free_var_61:	; location of cddddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1890

free_var_62:	; location of cdddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1651

free_var_63:	; location of cddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1540

free_var_64:	; location of cdr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 289

free_var_65:	; location of char->integer
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 425

free_var_66:	; location of char-ci<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2595

free_var_67:	; location of char-ci<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2577

free_var_68:	; location of char-ci=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2614

free_var_69:	; location of char-ci>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2650

free_var_70:	; location of char-ci>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2632

free_var_71:	; location of char-downcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2527

free_var_72:	; location of char-upcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2549

free_var_73:	; location of char<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2465

free_var_74:	; location of char<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2450

free_var_75:	; location of char=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2481

free_var_76:	; location of char>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2511

free_var_77:	; location of char>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2496

free_var_78:	; location of char?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 48

free_var_79:	; location of cons
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 223

free_var_80:	; location of crazy-ack
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3538

free_var_81:	; location of eq?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1174

free_var_82:	; location of equal?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3224

free_var_83:	; location of error
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 785

free_var_84:	; location of even?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3176

free_var_85:	; location of fact
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2307

free_var_86:	; location of fold-left
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2073

free_var_87:	; location of fold-right
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2106

free_var_88:	; location of fraction->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 402

free_var_89:	; location of fraction?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 152

free_var_90:	; location of integer->char
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 447

free_var_91:	; location of integer->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 380

free_var_92:	; location of integer?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 496

free_var_93:	; location of list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1919

free_var_94:	; location of list*
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1962

free_var_95:	; location of list->string
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2715

free_var_96:	; location of list->vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3068

free_var_97:	; location of list?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1905

free_var_98:	; location of logarithm
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3467

free_var_99:	; location of make-list-thunk
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3391

free_var_100:	; location of make-string
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1116

free_var_101:	; location of make-string-thunk
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3415

free_var_102:	; location of make-vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1096

free_var_103:	; location of make-vector-thunk
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3441

free_var_104:	; location of map
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2030

free_var_105:	; location of negative?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3158

free_var_106:	; location of newline
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3494

free_var_107:	; location of not
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1932

free_var_108:	; location of null?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 6

free_var_109:	; location of number?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 187

free_var_110:	; location of odd?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3199

free_var_111:	; location of ormap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2016

free_var_112:	; location of pair?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 20

free_var_113:	; location of positive?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3140

free_var_114:	; location of random
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3125

free_var_115:	; location of rational?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1944

free_var_116:	; location of real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2238

free_var_117:	; location of real?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 138

free_var_118:	; location of remainder
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 966

free_var_119:	; location of reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2057

free_var_120:	; location of string->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2736

free_var_121:	; location of string-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3253

free_var_122:	; location of string-ci<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2864

free_var_123:	; location of string-ci<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2844

free_var_124:	; location of string-ci=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2885

free_var_125:	; location of string-ci>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2905

free_var_126:	; location of string-ci>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2926

free_var_127:	; location of string-downcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2669

free_var_128:	; location of string-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 301

free_var_129:	; location of string-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1018

free_var_130:	; location of string-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3297

free_var_131:	; location of string-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3343

free_var_132:	; location of string-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1076

free_var_133:	; location of string-upcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2693

free_var_134:	; location of string<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2774

free_var_135:	; location of string<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2757

free_var_136:	; location of string=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2792

free_var_137:	; location of string>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2809

free_var_138:	; location of string>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2827

free_var_139:	; location of string?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 62

free_var_140:	; location of trng
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 469

free_var_141:	; location of vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3089

free_var_142:	; location of vector->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3104

free_var_143:	; location of vector-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3275

free_var_144:	; location of vector-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 323

free_var_145:	; location of vector-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1037

free_var_146:	; location of vector-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3320

free_var_147:	; location of vector-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3367

free_var_148:	; location of vector-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1056

free_var_149:	; location of vector?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 103

free_var_150:	; location of void
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3512

free_var_151:	; location of with
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3525

free_var_152:	; location of write-char
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 258

free_var_153:	; location of zero?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 482


extern printf, fprintf, stdout, stderr, fwrite, exit, putchar, getchar
global main
section .text
main:
        enter 0, 0
        push 0
        push 0
        push Lend
        enter 0, 0
	; building closure for null?
	mov rdi, free_var_108
	mov rsi, L_code_ptr_is_null
	call bind_primitive

	; building closure for pair?
	mov rdi, free_var_112
	mov rsi, L_code_ptr_is_pair
	call bind_primitive

	; building closure for char?
	mov rdi, free_var_78
	mov rsi, L_code_ptr_is_char
	call bind_primitive

	; building closure for string?
	mov rdi, free_var_139
	mov rsi, L_code_ptr_is_string
	call bind_primitive

	; building closure for vector?
	mov rdi, free_var_149
	mov rsi, L_code_ptr_is_vector
	call bind_primitive

	; building closure for real?
	mov rdi, free_var_117
	mov rsi, L_code_ptr_is_real
	call bind_primitive

	; building closure for fraction?
	mov rdi, free_var_89
	mov rsi, L_code_ptr_is_fraction
	call bind_primitive

	; building closure for number?
	mov rdi, free_var_109
	mov rsi, L_code_ptr_is_number
	call bind_primitive

	; building closure for cons
	mov rdi, free_var_79
	mov rsi, L_code_ptr_cons
	call bind_primitive

	; building closure for write-char
	mov rdi, free_var_152
	mov rsi, L_code_ptr_write_char
	call bind_primitive

	; building closure for car
	mov rdi, free_var_49
	mov rsi, L_code_ptr_car
	call bind_primitive

	; building closure for cdr
	mov rdi, free_var_64
	mov rsi, L_code_ptr_cdr
	call bind_primitive

	; building closure for string-length
	mov rdi, free_var_128
	mov rsi, L_code_ptr_string_length
	call bind_primitive

	; building closure for vector-length
	mov rdi, free_var_144
	mov rsi, L_code_ptr_vector_length
	call bind_primitive

	; building closure for integer->real
	mov rdi, free_var_91
	mov rsi, L_code_ptr_integer_to_real
	call bind_primitive

	; building closure for fraction->real
	mov rdi, free_var_88
	mov rsi, L_code_ptr_fraction_to_real
	call bind_primitive

	; building closure for char->integer
	mov rdi, free_var_65
	mov rsi, L_code_ptr_char_to_integer
	call bind_primitive

	; building closure for integer->char
	mov rdi, free_var_90
	mov rsi, L_code_ptr_integer_to_char
	call bind_primitive

	; building closure for trng
	mov rdi, free_var_140
	mov rsi, L_code_ptr_trng
	call bind_primitive

	; building closure for zero?
	mov rdi, free_var_153
	mov rsi, L_code_ptr_is_zero
	call bind_primitive

	; building closure for integer?
	mov rdi, free_var_92
	mov rsi, L_code_ptr_is_integer
	call bind_primitive

	; building closure for __bin-apply
	mov rdi, free_var_12
	mov rsi, L_code_ptr_bin_apply
	call bind_primitive

	; building closure for __bin-add-rr
	mov rdi, free_var_10
	mov rsi, L_code_ptr_raw_bin_add_rr
	call bind_primitive

	; building closure for __bin-sub-rr
	mov rdi, free_var_26
	mov rsi, L_code_ptr_raw_bin_sub_rr
	call bind_primitive

	; building closure for __bin-mul-rr
	mov rdi, free_var_23
	mov rsi, L_code_ptr_raw_bin_mul_rr
	call bind_primitive

	; building closure for __bin-div-rr
	mov rdi, free_var_14
	mov rsi, L_code_ptr_raw_bin_div_rr
	call bind_primitive

	; building closure for __bin-add-qq
	mov rdi, free_var_9
	mov rsi, L_code_ptr_raw_bin_add_qq
	call bind_primitive

	; building closure for __bin-sub-qq
	mov rdi, free_var_25
	mov rsi, L_code_ptr_raw_bin_sub_qq
	call bind_primitive

	; building closure for __bin-mul-qq
	mov rdi, free_var_22
	mov rsi, L_code_ptr_raw_bin_mul_qq
	call bind_primitive

	; building closure for __bin-div-qq
	mov rdi, free_var_13
	mov rsi, L_code_ptr_raw_bin_div_qq
	call bind_primitive

	; building closure for __bin-add-zz
	mov rdi, free_var_11
	mov rsi, L_code_ptr_raw_bin_add_zz
	call bind_primitive

	; building closure for __bin-sub-zz
	mov rdi, free_var_27
	mov rsi, L_code_ptr_raw_bin_sub_zz
	call bind_primitive

	; building closure for __bin-mul-zz
	mov rdi, free_var_24
	mov rsi, L_code_ptr_raw_bin_mul_zz
	call bind_primitive

	; building closure for __bin-div-zz
	mov rdi, free_var_15
	mov rsi, L_code_ptr_raw_bin_div_zz
	call bind_primitive

	; building closure for error
	mov rdi, free_var_83
	mov rsi, L_code_ptr_error
	call bind_primitive

	; building closure for __bin-less-than-rr
	mov rdi, free_var_20
	mov rsi, L_code_ptr_raw_less_than_rr
	call bind_primitive

	; building closure for __bin-less-than-qq
	mov rdi, free_var_19
	mov rsi, L_code_ptr_raw_less_than_qq
	call bind_primitive

	; building closure for __bin-less-than-zz
	mov rdi, free_var_21
	mov rsi, L_code_ptr_raw_less_than_zz
	call bind_primitive

	; building closure for __bin-equal-rr
	mov rdi, free_var_17
	mov rsi, L_code_ptr_raw_equal_rr
	call bind_primitive

	; building closure for __bin-equal-qq
	mov rdi, free_var_16
	mov rsi, L_code_ptr_raw_equal_qq
	call bind_primitive

	; building closure for __bin-equal-zz
	mov rdi, free_var_18
	mov rsi, L_code_ptr_raw_equal_zz
	call bind_primitive

	; building closure for remainder
	mov rdi, free_var_118
	mov rsi, L_code_ptr_remainder
	call bind_primitive

	; building closure for string-ref
	mov rdi, free_var_129
	mov rsi, L_code_ptr_string_ref
	call bind_primitive

	; building closure for vector-ref
	mov rdi, free_var_145
	mov rsi, L_code_ptr_vector_ref
	call bind_primitive

	; building closure for vector-set!
	mov rdi, free_var_148
	mov rsi, L_code_ptr_vector_set
	call bind_primitive

	; building closure for string-set!
	mov rdi, free_var_132
	mov rsi, L_code_ptr_string_set
	call bind_primitive

	; building closure for make-vector
	mov rdi, free_var_102
	mov rsi, L_code_ptr_make_vector
	call bind_primitive

	; building closure for make-string
	mov rdi, free_var_100
	mov rsi, L_code_ptr_make_string
	call bind_primitive

	; building closure for eq?
	mov rdi, free_var_81
	mov rsi, L_code_ptr_is_eq
	call bind_primitive

	; building closure for __integer-to-fraction
	mov rdi, free_var_29
	mov rsi, L_code_ptr_integer_to_fraction
	call bind_primitive

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0244:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0244
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0244
.L_lambda_simple_env_end_0244:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0244:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0244
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0244
.L_lambda_simple_params_end_0244:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0244
	jmp .L_lambda_simple_end_0244
.L_lambda_simple_code_0244:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0244
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0244:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0304:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0304
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0304
.L_tc_recycle_frame_done_0304:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0244:	; new closure is in rax
	mov qword [free_var_41], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0245:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0245
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0245
.L_lambda_simple_env_end_0245:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0245:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0245
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0245
.L_lambda_simple_params_end_0245:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0245
	jmp .L_lambda_simple_end_0245
.L_lambda_simple_code_0245:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0245
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0245:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0305:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0305
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0305
.L_tc_recycle_frame_done_0305:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0245:	; new closure is in rax
	mov qword [free_var_48], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0246:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0246
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0246
.L_lambda_simple_env_end_0246:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0246:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0246
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0246
.L_lambda_simple_params_end_0246:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0246
	jmp .L_lambda_simple_end_0246
.L_lambda_simple_code_0246:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0246
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0246:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0306:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0306
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0306
.L_tc_recycle_frame_done_0306:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0246:	; new closure is in rax
	mov qword [free_var_56], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0247:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0247
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0247
.L_lambda_simple_env_end_0247:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0247:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0247
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0247
.L_lambda_simple_params_end_0247:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0247
	jmp .L_lambda_simple_end_0247
.L_lambda_simple_code_0247:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0247
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0247:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0307:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0307
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0307
.L_tc_recycle_frame_done_0307:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0247:	; new closure is in rax
	mov qword [free_var_63], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0248:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0248
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0248
.L_lambda_simple_env_end_0248:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0248:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0248
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0248
.L_lambda_simple_params_end_0248:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0248
	jmp .L_lambda_simple_end_0248
.L_lambda_simple_code_0248:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0248
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0248:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0308:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0308
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0308
.L_tc_recycle_frame_done_0308:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0248:	; new closure is in rax
	mov qword [free_var_37], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0249:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0249
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0249
.L_lambda_simple_env_end_0249:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0249:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0249
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0249
.L_lambda_simple_params_end_0249:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0249
	jmp .L_lambda_simple_end_0249
.L_lambda_simple_code_0249:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0249
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0249:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0309:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0309
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0309
.L_tc_recycle_frame_done_0309:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0249:	; new closure is in rax
	mov qword [free_var_40], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_024a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_024a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_024a
.L_lambda_simple_env_end_024a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_024a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_024a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_024a
.L_lambda_simple_params_end_024a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_024a
	jmp .L_lambda_simple_end_024a
.L_lambda_simple_code_024a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_024a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_024a:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_030a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_030a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_030a
.L_tc_recycle_frame_done_030a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_024a:	; new closure is in rax
	mov qword [free_var_44], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_024b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_024b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_024b
.L_lambda_simple_env_end_024b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_024b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_024b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_024b
.L_lambda_simple_params_end_024b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_024b
	jmp .L_lambda_simple_end_024b
.L_lambda_simple_code_024b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_024b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_024b:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_030b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_030b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_030b
.L_tc_recycle_frame_done_030b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_024b:	; new closure is in rax
	mov qword [free_var_47], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_024c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_024c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_024c
.L_lambda_simple_env_end_024c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_024c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_024c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_024c
.L_lambda_simple_params_end_024c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_024c
	jmp .L_lambda_simple_end_024c
.L_lambda_simple_code_024c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_024c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_024c:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_030c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_030c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_030c
.L_tc_recycle_frame_done_030c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_024c:	; new closure is in rax
	mov qword [free_var_52], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_024d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_024d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_024d
.L_lambda_simple_env_end_024d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_024d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_024d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_024d
.L_lambda_simple_params_end_024d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_024d
	jmp .L_lambda_simple_end_024d
.L_lambda_simple_code_024d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_024d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_024d:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_030d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_030d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_030d
.L_tc_recycle_frame_done_030d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_024d:	; new closure is in rax
	mov qword [free_var_55], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_024e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_024e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_024e
.L_lambda_simple_env_end_024e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_024e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_024e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_024e
.L_lambda_simple_params_end_024e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_024e
	jmp .L_lambda_simple_end_024e
.L_lambda_simple_code_024e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_024e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_024e:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_030e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_030e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_030e
.L_tc_recycle_frame_done_030e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_024e:	; new closure is in rax
	mov qword [free_var_59], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_024f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_024f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_024f
.L_lambda_simple_env_end_024f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_024f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_024f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_024f
.L_lambda_simple_params_end_024f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_024f
	jmp .L_lambda_simple_end_024f
.L_lambda_simple_code_024f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_024f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_024f:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_030f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_030f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_030f
.L_tc_recycle_frame_done_030f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_024f:	; new closure is in rax
	mov qword [free_var_62], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0250:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0250
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0250
.L_lambda_simple_env_end_0250:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0250:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0250
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0250
.L_lambda_simple_params_end_0250:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0250
	jmp .L_lambda_simple_end_0250
.L_lambda_simple_code_0250:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0250
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0250:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0310:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0310
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0310
.L_tc_recycle_frame_done_0310:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0250:	; new closure is in rax
	mov qword [free_var_35], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0251:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0251
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0251
.L_lambda_simple_env_end_0251:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0251:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0251
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0251
.L_lambda_simple_params_end_0251:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0251
	jmp .L_lambda_simple_end_0251
.L_lambda_simple_code_0251:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0251
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0251:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0311:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0311
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0311
.L_tc_recycle_frame_done_0311:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0251:	; new closure is in rax
	mov qword [free_var_36], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0252:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0252
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0252
.L_lambda_simple_env_end_0252:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0252:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0252
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0252
.L_lambda_simple_params_end_0252:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0252
	jmp .L_lambda_simple_end_0252
.L_lambda_simple_code_0252:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0252
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0252:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0312:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0312
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0312
.L_tc_recycle_frame_done_0312:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0252:	; new closure is in rax
	mov qword [free_var_38], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0253:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0253
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0253
.L_lambda_simple_env_end_0253:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0253:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0253
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0253
.L_lambda_simple_params_end_0253:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0253
	jmp .L_lambda_simple_end_0253
.L_lambda_simple_code_0253:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0253
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0253:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0313:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0313
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0313
.L_tc_recycle_frame_done_0313:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0253:	; new closure is in rax
	mov qword [free_var_39], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0254:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0254
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0254
.L_lambda_simple_env_end_0254:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0254:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0254
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0254
.L_lambda_simple_params_end_0254:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0254
	jmp .L_lambda_simple_end_0254
.L_lambda_simple_code_0254:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0254
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0254:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0314:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0314
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0314
.L_tc_recycle_frame_done_0314:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0254:	; new closure is in rax
	mov qword [free_var_42], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0255:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0255
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0255
.L_lambda_simple_env_end_0255:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0255:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0255
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0255
.L_lambda_simple_params_end_0255:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0255
	jmp .L_lambda_simple_end_0255
.L_lambda_simple_code_0255:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0255
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0255:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0315:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0315
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0315
.L_tc_recycle_frame_done_0315:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0255:	; new closure is in rax
	mov qword [free_var_43], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0256:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0256
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0256
.L_lambda_simple_env_end_0256:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0256:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0256
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0256
.L_lambda_simple_params_end_0256:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0256
	jmp .L_lambda_simple_end_0256
.L_lambda_simple_code_0256:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0256
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0256:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0316:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0316
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0316
.L_tc_recycle_frame_done_0316:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0256:	; new closure is in rax
	mov qword [free_var_45], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0257:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0257
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0257
.L_lambda_simple_env_end_0257:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0257:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0257
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0257
.L_lambda_simple_params_end_0257:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0257
	jmp .L_lambda_simple_end_0257
.L_lambda_simple_code_0257:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0257
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0257:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0317:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0317
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0317
.L_tc_recycle_frame_done_0317:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0257:	; new closure is in rax
	mov qword [free_var_46], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0258:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0258
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0258
.L_lambda_simple_env_end_0258:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0258:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0258
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0258
.L_lambda_simple_params_end_0258:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0258
	jmp .L_lambda_simple_end_0258
.L_lambda_simple_code_0258:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0258
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0258:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0318:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0318
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0318
.L_tc_recycle_frame_done_0318:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0258:	; new closure is in rax
	mov qword [free_var_50], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0259:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0259
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0259
.L_lambda_simple_env_end_0259:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0259:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0259
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0259
.L_lambda_simple_params_end_0259:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0259
	jmp .L_lambda_simple_end_0259
.L_lambda_simple_code_0259:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0259
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0259:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0319:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0319
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0319
.L_tc_recycle_frame_done_0319:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0259:	; new closure is in rax
	mov qword [free_var_51], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_025a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_025a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_025a
.L_lambda_simple_env_end_025a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_025a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_025a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_025a
.L_lambda_simple_params_end_025a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_025a
	jmp .L_lambda_simple_end_025a
.L_lambda_simple_code_025a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_025a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_025a:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_031a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_031a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_031a
.L_tc_recycle_frame_done_031a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_025a:	; new closure is in rax
	mov qword [free_var_53], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_025b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_025b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_025b
.L_lambda_simple_env_end_025b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_025b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_025b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_025b
.L_lambda_simple_params_end_025b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_025b
	jmp .L_lambda_simple_end_025b
.L_lambda_simple_code_025b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_025b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_025b:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_031b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_031b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_031b
.L_tc_recycle_frame_done_031b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_025b:	; new closure is in rax
	mov qword [free_var_54], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_025c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_025c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_025c
.L_lambda_simple_env_end_025c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_025c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_025c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_025c
.L_lambda_simple_params_end_025c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_025c
	jmp .L_lambda_simple_end_025c
.L_lambda_simple_code_025c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_025c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_025c:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_031c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_031c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_031c
.L_tc_recycle_frame_done_031c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_025c:	; new closure is in rax
	mov qword [free_var_57], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_025d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_025d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_025d
.L_lambda_simple_env_end_025d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_025d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_025d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_025d
.L_lambda_simple_params_end_025d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_025d
	jmp .L_lambda_simple_end_025d
.L_lambda_simple_code_025d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_025d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_025d:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_031d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_031d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_031d
.L_tc_recycle_frame_done_031d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_025d:	; new closure is in rax
	mov qword [free_var_58], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_025e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_025e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_025e
.L_lambda_simple_env_end_025e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_025e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_025e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_025e
.L_lambda_simple_params_end_025e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_025e
	jmp .L_lambda_simple_end_025e
.L_lambda_simple_code_025e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_025e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_025e:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_031e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_031e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_031e
.L_tc_recycle_frame_done_031e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_025e:	; new closure is in rax
	mov qword [free_var_60], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_025f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_025f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_025f
.L_lambda_simple_env_end_025f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_025f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_025f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_025f
.L_lambda_simple_params_end_025f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_025f
	jmp .L_lambda_simple_end_025f
.L_lambda_simple_code_025f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_025f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_025f:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_031f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_031f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_031f
.L_tc_recycle_frame_done_031f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_025f:	; new closure is in rax
	mov qword [free_var_61], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0260:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0260
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0260
.L_lambda_simple_env_end_0260:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0260:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0260
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0260
.L_lambda_simple_params_end_0260:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0260
	jmp .L_lambda_simple_end_0260
.L_lambda_simple_code_0260:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0260
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0260:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_002b
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1
	mov rax, qword [free_var_112]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01bd
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var list?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0320:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0320
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0320
.L_tc_recycle_frame_done_0320:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01bd
.L_if_else_01bd:
	mov rax, L_constants + 2
.L_if_end_01bd:
.L_or_end_002b:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0260:	; new closure is in rax
	mov qword [free_var_97], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 0
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_0052:
	cmp rsi, 0
	je .L_lambda_opt_env_end_0052
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0052
.L_lambda_opt_env_end_0052:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0052:	; copying parameters
	cmp rsi, 0
	je .L_lambda_opt_params_end_0052
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0052
.L_lambda_opt_params_end_0052:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0052
	jmp .L_lambda_opt_end_0052
.L_lambda_opt_code_0052:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_0052
	ja .L_lambda_opt_arity_check_more_0052
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0052:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_00f5:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_00f5
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_00f5
.L_lambda_opt_stack_shrink_loop_exit_00f5:
	lea r10, [rsp + 8 * 0 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_00f6:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_00f6
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_00f6
.L_lambda_opt_stack_shrink_loop_exit_00f6:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0052
.L_lambda_opt_arity_check_exact_0052:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_00f4:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_00f4
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_00f4
.L_lambda_opt_stack_shrink_loop_exit_00f4:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0052:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	mov rax, PARAM(0)	; param args
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_0052:
	mov qword [free_var_93], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0261:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0261
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0261
.L_lambda_simple_env_end_0261:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0261:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0261
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0261
.L_lambda_simple_params_end_0261:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0261
	jmp .L_lambda_simple_end_0261
.L_lambda_simple_code_0261:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0261
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0261:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	cmp rax, sob_boolean_false
	je .L_if_else_01be
	mov rax, L_constants + 2
	jmp .L_if_end_01be
.L_if_else_01be:
	mov rax, L_constants + 3
.L_if_end_01be:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0261:	; new closure is in rax
	mov qword [free_var_107], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0262:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0262
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0262
.L_lambda_simple_env_end_0262:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0262:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0262
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0262
.L_lambda_simple_params_end_0262:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0262
	jmp .L_lambda_simple_end_0262
.L_lambda_simple_code_0262:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0262
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0262:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param q
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_002c
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param q
	push rax
	push 1	; arg count
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0321:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0321
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0321
.L_tc_recycle_frame_done_0321:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_002c:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0262:	; new closure is in rax
	mov qword [free_var_115], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0263:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0263
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0263
.L_lambda_simple_env_end_0263:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0263:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0263
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0263
.L_lambda_simple_params_end_0263:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0263
	jmp .L_lambda_simple_end_0263
.L_lambda_simple_code_0263:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0263
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0263:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0264:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0264
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0264
.L_lambda_simple_env_end_0264:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0264:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0264
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0264
.L_lambda_simple_params_end_0264:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0264
	jmp .L_lambda_simple_end_0264
.L_lambda_simple_code_0264:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0264
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0264:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01bf
	mov rax, PARAM(0)	; param a
	jmp .L_if_end_01bf
.L_if_else_01bf:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0322:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0322
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0322
.L_tc_recycle_frame_done_0322:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01bf:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0264:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_0053:
	cmp rsi, 1
	je .L_lambda_opt_env_end_0053
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0053
.L_lambda_opt_env_end_0053:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0053:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_0053
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0053
.L_lambda_opt_params_end_0053:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0053
	jmp .L_lambda_opt_end_0053
.L_lambda_opt_code_0053:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0053
	ja .L_lambda_opt_arity_check_more_0053
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0053:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_00f8:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_00f8
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_00f8
.L_lambda_opt_stack_shrink_loop_exit_00f8:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_00f9:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_00f9
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_00f9
.L_lambda_opt_stack_shrink_loop_exit_00f9:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0053
.L_lambda_opt_arity_check_exact_0053:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_00f7:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_00f7
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_00f7
.L_lambda_opt_stack_shrink_loop_exit_00f7:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0053:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0323:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0323
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0323
.L_tc_recycle_frame_done_0323:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0053:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0263:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_94], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0265:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0265
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0265
.L_lambda_simple_env_end_0265:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0265:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0265
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0265
.L_lambda_simple_params_end_0265:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0265
	jmp .L_lambda_simple_end_0265
.L_lambda_simple_code_0265:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0265
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0265:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0266:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0266
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0266
.L_lambda_simple_env_end_0266:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0266:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0266
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0266
.L_lambda_simple_params_end_0266:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0266
	jmp .L_lambda_simple_end_0266
.L_lambda_simple_code_0266:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0266
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0266:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_112]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01c0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0324:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0324
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0324
.L_tc_recycle_frame_done_0324:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01c0
.L_if_else_01c0:
	mov rax, PARAM(0)	; param a
.L_if_end_01c0:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0266:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_0054:
	cmp rsi, 1
	je .L_lambda_opt_env_end_0054
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0054
.L_lambda_opt_env_end_0054:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0054:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_0054
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0054
.L_lambda_opt_params_end_0054:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0054
	jmp .L_lambda_opt_end_0054
.L_lambda_opt_code_0054:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0054
	ja .L_lambda_opt_arity_check_more_0054
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0054:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_00fb:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_00fb
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_00fb
.L_lambda_opt_stack_shrink_loop_exit_00fb:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_00fc:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_00fc
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_00fc
.L_lambda_opt_stack_shrink_loop_exit_00fc:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0054
.L_lambda_opt_arity_check_exact_0054:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_00fa:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_00fa
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_00fa
.L_lambda_opt_stack_shrink_loop_exit_00fa:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0054:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_12]	; free var __bin-apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0325:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0325
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0325
.L_tc_recycle_frame_done_0325:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0054:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0265:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_33], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 0
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_0055:
	cmp rsi, 0
	je .L_lambda_opt_env_end_0055
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0055
.L_lambda_opt_env_end_0055:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0055:	; copying parameters
	cmp rsi, 0
	je .L_lambda_opt_params_end_0055
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0055
.L_lambda_opt_params_end_0055:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0055
	jmp .L_lambda_opt_end_0055
.L_lambda_opt_code_0055:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0055
	ja .L_lambda_opt_arity_check_more_0055
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0055:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_00fe:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_00fe
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_00fe
.L_lambda_opt_stack_shrink_loop_exit_00fe:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_00ff:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_00ff
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_00ff
.L_lambda_opt_stack_shrink_loop_exit_00ff:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0055
.L_lambda_opt_arity_check_exact_0055:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_00fd:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_00fd
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_00fd
.L_lambda_opt_stack_shrink_loop_exit_00fd:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0055:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0267:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0267
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0267
.L_lambda_simple_env_end_0267:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0267:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0267
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0267
.L_lambda_simple_params_end_0267:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0267
	jmp .L_lambda_simple_end_0267
.L_lambda_simple_code_0267:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0267
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0267:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0268:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0268
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0268
.L_lambda_simple_env_end_0268:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0268:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0268
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0268
.L_lambda_simple_params_end_0268:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0268
	jmp .L_lambda_simple_end_0268
.L_lambda_simple_code_0268:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0268
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0268:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_112]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01c1
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_104]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	push 2
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_002d
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_104]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0327:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0327
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0327
.L_tc_recycle_frame_done_0327:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_002d:
	jmp .L_if_end_01c1
.L_if_else_01c1:
	mov rax, L_constants + 2
.L_if_end_01c1:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0268:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param loop
	pop qword [rax]
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1
	mov rax, qword [free_var_112]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01c2
	;debug: preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0328:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0328
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0328
.L_tc_recycle_frame_done_0328:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01c2
.L_if_else_01c2:
	mov rax, L_constants + 2
.L_if_end_01c2:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0267:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0326:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0326
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0326
.L_tc_recycle_frame_done_0326:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0055:
	mov qword [free_var_111], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 0
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_0056:
	cmp rsi, 0
	je .L_lambda_opt_env_end_0056
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0056
.L_lambda_opt_env_end_0056:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0056:	; copying parameters
	cmp rsi, 0
	je .L_lambda_opt_params_end_0056
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0056
.L_lambda_opt_params_end_0056:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0056
	jmp .L_lambda_opt_end_0056
.L_lambda_opt_code_0056:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0056
	ja .L_lambda_opt_arity_check_more_0056
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0056:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0101:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0101
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0101
.L_lambda_opt_stack_shrink_loop_exit_0101:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_0102:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0102
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0102
.L_lambda_opt_stack_shrink_loop_exit_0102:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0056
.L_lambda_opt_arity_check_exact_0056:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0100:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0100
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0100
.L_lambda_opt_stack_shrink_loop_exit_0100:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0056:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0269:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0269
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0269
.L_lambda_simple_env_end_0269:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0269:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0269
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0269
.L_lambda_simple_params_end_0269:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0269
	jmp .L_lambda_simple_end_0269
.L_lambda_simple_code_0269:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0269
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0269:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_026a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_026a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_026a
.L_lambda_simple_env_end_026a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_026a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_026a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_026a
.L_lambda_simple_params_end_026a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_026a
	jmp .L_lambda_simple_end_026a
.L_lambda_simple_code_026a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_026a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_026a:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_002e
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_104]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	push 2
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01c3
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_104]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_032a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_032a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_032a
.L_tc_recycle_frame_done_032a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01c3
.L_if_else_01c3:
	mov rax, L_constants + 2
.L_if_end_01c3:
.L_or_end_002e:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_026a:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param loop
	pop qword [rax]
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_002f
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1
	mov rax, qword [free_var_112]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01c4
	;debug: preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_032b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_032b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_032b
.L_tc_recycle_frame_done_032b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01c4
.L_if_else_01c4:
	mov rax, L_constants + 2
.L_if_end_01c4:
.L_or_end_002f:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0269:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0329:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0329
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0329
.L_tc_recycle_frame_done_0329:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0056:
	mov qword [free_var_31], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_026b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_026b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_026b
.L_lambda_simple_env_end_026b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_026b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_026b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_026b
.L_lambda_simple_params_end_026b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_026b
	jmp .L_lambda_simple_end_026b
.L_lambda_simple_code_026b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_026b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_026b:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(1)
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_026c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_026c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_026c
.L_lambda_simple_env_end_026c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_026c:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_026c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_026c
.L_lambda_simple_params_end_026c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_026c
	jmp .L_lambda_simple_end_026c
.L_lambda_simple_code_026c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_026c
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_026c:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01c5
	mov rax, L_constants + 1
	jmp .L_if_end_01c5
.L_if_else_01c5:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, PARAM(0)	; param f
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_032c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_032c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_032c
.L_tc_recycle_frame_done_032c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01c5:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_026c:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param map1
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_026d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_026d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_026d
.L_lambda_simple_env_end_026d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_026d:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_026d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_026d
.L_lambda_simple_params_end_026d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_026d
	jmp .L_lambda_simple_end_026d
.L_lambda_simple_code_026d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_026d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_026d:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01c6
	mov rax, L_constants + 1
	jmp .L_if_end_01c6
.L_if_else_01c6:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_032d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_032d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_032d
.L_tc_recycle_frame_done_032d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01c6:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_026d:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param map-list
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_0057:
	cmp rsi, 1
	je .L_lambda_opt_env_end_0057
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0057
.L_lambda_opt_env_end_0057:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0057:	; copying parameters
	cmp rsi, 2
	je .L_lambda_opt_params_end_0057
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0057
.L_lambda_opt_params_end_0057:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0057
	jmp .L_lambda_opt_end_0057
.L_lambda_opt_code_0057:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0057
	ja .L_lambda_opt_arity_check_more_0057
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0057:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0104:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0104
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0104
.L_lambda_opt_stack_shrink_loop_exit_0104:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_0105:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0105
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0105
.L_lambda_opt_stack_shrink_loop_exit_0105:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0057
.L_lambda_opt_arity_check_exact_0057:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0103:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0103
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0103
.L_lambda_opt_stack_shrink_loop_exit_0103:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0057:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01c7
	mov rax, L_constants + 1
	jmp .L_if_end_01c7
.L_if_else_01c7:
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_032e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_032e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_032e
.L_tc_recycle_frame_done_032e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01c7:
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0057:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_026b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_104], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_026e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_026e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_026e
.L_lambda_simple_env_end_026e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_026e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_026e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_026e
.L_lambda_simple_params_end_026e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_026e
	jmp .L_lambda_simple_end_026e
.L_lambda_simple_code_026e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_026e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_026e:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 1
	push rax
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_026f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_026f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_026f
.L_lambda_simple_env_end_026f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_026f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_026f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_026f
.L_lambda_simple_params_end_026f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_026f
	jmp .L_lambda_simple_end_026f
.L_lambda_simple_code_026f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_026f
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_026f:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param r
	push rax
	mov rax, PARAM(1)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0330:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0330
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0330
.L_tc_recycle_frame_done_0330:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_026f:	; new closure is in rax
	push rax
	push 3	; arg count
	mov rax, qword [free_var_86]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_032f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_032f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_032f
.L_tc_recycle_frame_done_032f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_026e:	; new closure is in rax
	mov qword [free_var_119], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0270:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0270
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0270
.L_lambda_simple_env_end_0270:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0270:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0270
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0270
.L_lambda_simple_params_end_0270:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0270
	jmp .L_lambda_simple_end_0270
.L_lambda_simple_code_0270:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0270
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0270:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(1)
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0271:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0271
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0271
.L_lambda_simple_env_end_0271:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0271:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0271
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0271
.L_lambda_simple_params_end_0271:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0271
	jmp .L_lambda_simple_end_0271
.L_lambda_simple_code_0271:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0271
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0271:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01c8
	mov rax, PARAM(0)	; param s1
	jmp .L_if_end_01c8
.L_if_else_01c8:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param s1
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var run-2
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0331:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0331
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0331
.L_tc_recycle_frame_done_0331:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01c8:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0271:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run-1
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0272:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0272
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0272
.L_lambda_simple_env_end_0272:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0272:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0272
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0272
.L_lambda_simple_params_end_0272:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0272
	jmp .L_lambda_simple_end_0272
.L_lambda_simple_code_0272:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0272
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0272:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s1
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01c9
	mov rax, PARAM(1)	; param s2
	jmp .L_if_end_01c9
.L_if_else_01c9:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s2
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s1
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var run-2
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s1
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0332:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0332
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0332
.L_tc_recycle_frame_done_0332:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01c9:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0272:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param run-2
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_0058:
	cmp rsi, 1
	je .L_lambda_opt_env_end_0058
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0058
.L_lambda_opt_env_end_0058:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0058:	; copying parameters
	cmp rsi, 2
	je .L_lambda_opt_params_end_0058
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0058
.L_lambda_opt_params_end_0058:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0058
	jmp .L_lambda_opt_end_0058
.L_lambda_opt_code_0058:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_0058
	ja .L_lambda_opt_arity_check_more_0058
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0058:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0107:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0107
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0107
.L_lambda_opt_stack_shrink_loop_exit_0107:
	lea r10, [rsp + 8 * 0 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_0108:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0108
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0108
.L_lambda_opt_stack_shrink_loop_exit_0108:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0058
.L_lambda_opt_arity_check_exact_0058:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0106:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0106
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0106
.L_lambda_opt_stack_shrink_loop_exit_0106:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0058:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01ca
	mov rax, L_constants + 1
	jmp .L_if_end_01ca
.L_if_else_01ca:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0333:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0333
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0333
.L_tc_recycle_frame_done_0333:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01ca:
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_0058:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0270:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_32], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0273:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0273
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0273
.L_lambda_simple_env_end_0273:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0273:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0273
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0273
.L_lambda_simple_params_end_0273:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0273
	jmp .L_lambda_simple_end_0273
.L_lambda_simple_code_0273:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0273
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0273:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0274:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0274
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0274
.L_lambda_simple_env_end_0274:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0274:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0274
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0274
.L_lambda_simple_params_end_0274:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0274
	jmp .L_lambda_simple_end_0274
.L_lambda_simple_code_0274:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0274
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0274:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_111]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01cb
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_01cb
.L_if_else_01cb:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_104]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_104]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0334:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0334
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0334
.L_tc_recycle_frame_done_0334:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01cb:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0274:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_0059:
	cmp rsi, 1
	je .L_lambda_opt_env_end_0059
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0059
.L_lambda_opt_env_end_0059:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0059:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_0059
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0059
.L_lambda_opt_params_end_0059:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0059
	jmp .L_lambda_opt_end_0059
.L_lambda_opt_code_0059:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 3
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_arity_check_exact_0059
	ja .L_lambda_opt_arity_check_more_0059
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0059:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_010a:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_010a
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_010a
.L_lambda_opt_stack_shrink_loop_exit_010a:
	lea r10, [rsp + 8 * 2 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 5
	mov rcx, 4 + 2
.L_lambda_opt_stack_shrink_loop_010b:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_010b
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_010b
.L_lambda_opt_stack_shrink_loop_exit_010b:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0059
.L_lambda_opt_arity_check_exact_0059:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0109:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0109
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0109
.L_lambda_opt_stack_shrink_loop_exit_0109:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0059:
	mov qword [rsp + 8*2], 3
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0335:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0335
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0335
.L_tc_recycle_frame_done_0335:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 3)
.L_lambda_opt_end_0059:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0273:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_86], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0275:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0275
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0275
.L_lambda_simple_env_end_0275:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0275:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0275
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0275
.L_lambda_simple_params_end_0275:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0275
	jmp .L_lambda_simple_end_0275
.L_lambda_simple_code_0275:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0275
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0275:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0276:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0276
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0276
.L_lambda_simple_env_end_0276:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0276:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0276
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0276
.L_lambda_simple_params_end_0276:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0276
	jmp .L_lambda_simple_end_0276
.L_lambda_simple_code_0276:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0276
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0276:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_111]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01cc
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_01cc
.L_if_else_01cc:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 1
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_104]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_104]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_32]	; free var append
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0336:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0336
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0336
.L_tc_recycle_frame_done_0336:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01cc:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0276:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_005a:
	cmp rsi, 1
	je .L_lambda_opt_env_end_005a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_005a
.L_lambda_opt_env_end_005a:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_005a:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_005a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_005a
.L_lambda_opt_params_end_005a:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_005a
	jmp .L_lambda_opt_end_005a
.L_lambda_opt_code_005a:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 3
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_arity_check_exact_005a
	ja .L_lambda_opt_arity_check_more_005a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_005a:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_010d:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_010d
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_010d
.L_lambda_opt_stack_shrink_loop_exit_010d:
	lea r10, [rsp + 8 * 2 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 5
	mov rcx, 4 + 2
.L_lambda_opt_stack_shrink_loop_010e:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_010e
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_010e
.L_lambda_opt_stack_shrink_loop_exit_010e:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_005a
.L_lambda_opt_arity_check_exact_005a:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_010c:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_010c
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_010c
.L_lambda_opt_stack_shrink_loop_exit_010c:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_005a:
	mov qword [rsp + 8*2], 3
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0337:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0337
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0337
.L_tc_recycle_frame_done_0337:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 3)
.L_lambda_opt_end_005a:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0275:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_87], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0277:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0277
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0277
.L_lambda_simple_env_end_0277:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0277:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0277
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0277
.L_lambda_simple_params_end_0277:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0277
	jmp .L_lambda_simple_end_0277
.L_lambda_simple_code_0277:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0277
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0277:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 2187
	push rax
	mov rax, L_constants + 2178
	push rax
	push 2	; arg count
	mov rax, qword [free_var_83]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0338:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0338
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0338
.L_tc_recycle_frame_done_0338:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0277:	; new closure is in rax
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0278:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0278
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0278
.L_lambda_simple_env_end_0278:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0278:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0278
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0278
.L_lambda_simple_params_end_0278:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0278
	jmp .L_lambda_simple_end_0278
.L_lambda_simple_code_0278:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0278
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0278:
	enter 0, 0
	;debug: preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0279:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0279
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0279
.L_lambda_simple_env_end_0279:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0279:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0279
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0279
.L_lambda_simple_params_end_0279:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0279
	jmp .L_lambda_simple_end_0279
.L_lambda_simple_code_0279:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0279
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0279:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01d8
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01cf
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_11]	; free var __bin-add-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_033a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_033a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_033a
.L_tc_recycle_frame_done_033a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01cf
.L_if_else_01cf:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01ce
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_9]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_033b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_033b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_033b
.L_tc_recycle_frame_done_033b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01ce
.L_if_else_01ce:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01cd
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_033c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_033c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_033c
.L_tc_recycle_frame_done_033c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01cd
.L_if_else_01cd:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_033d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_033d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_033d
.L_tc_recycle_frame_done_033d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01cd:
.L_if_end_01ce:
.L_if_end_01cf:
	jmp .L_if_end_01d8
.L_if_else_01d8:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01d7
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01d2
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_28]	; free var __bin_integer_to_fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_9]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_033e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_033e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_033e
.L_tc_recycle_frame_done_033e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01d2
.L_if_else_01d2:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01d1
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_9]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_033f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_033f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_033f
.L_tc_recycle_frame_done_033f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01d1
.L_if_else_01d1:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01d0
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0340:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0340
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0340
.L_tc_recycle_frame_done_0340:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01d0
.L_if_else_01d0:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0341:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0341
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0341
.L_tc_recycle_frame_done_0341:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01d0:
.L_if_end_01d1:
.L_if_end_01d2:
	jmp .L_if_end_01d7
.L_if_else_01d7:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01d6
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01d5
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0342:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0342
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0342
.L_tc_recycle_frame_done_0342:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01d5
.L_if_else_01d5:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01d4
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0343:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0343
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0343
.L_tc_recycle_frame_done_0343:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01d4
.L_if_else_01d4:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01d3
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0344:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0344
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0344
.L_tc_recycle_frame_done_0344:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01d3
.L_if_else_01d3:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0345:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0345
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0345
.L_tc_recycle_frame_done_0345:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01d3:
.L_if_end_01d4:
.L_if_end_01d5:
	jmp .L_if_end_01d6
.L_if_else_01d6:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0346:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0346
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0346
.L_tc_recycle_frame_done_0346:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01d6:
.L_if_end_01d7:
.L_if_end_01d8:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0279:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_027a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_027a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_027a
.L_lambda_simple_env_end_027a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_027a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_027a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_027a
.L_lambda_simple_params_end_027a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_027a
	jmp .L_lambda_simple_end_027a
.L_lambda_simple_code_027a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_027a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_027a:
	enter 0, 0
	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	push rax
	mov rdi, 8 * 3
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_005b:
	cmp rsi, 2
	je .L_lambda_opt_env_end_005b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_005b
.L_lambda_opt_env_end_005b:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_005b:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_005b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_005b
.L_lambda_opt_params_end_005b:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_005b
	jmp .L_lambda_opt_end_005b
.L_lambda_opt_code_005b:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_005b
	ja .L_lambda_opt_arity_check_more_005b
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_005b:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0110:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0110
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0110
.L_lambda_opt_stack_shrink_loop_exit_0110:
	lea r10, [rsp + 8 * 0 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_0111:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0111
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0111
.L_lambda_opt_stack_shrink_loop_exit_0111:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_005b
.L_lambda_opt_arity_check_exact_005b:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_010f:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_010f
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_010f
.L_lambda_opt_stack_shrink_loop_exit_010f:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_005b:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2135
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin+
	push rax
	push 3	; arg count
	mov rax, qword [free_var_86]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0347:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0347
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0347
.L_tc_recycle_frame_done_0347:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_005b:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_027a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0339:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0339
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0339
.L_tc_recycle_frame_done_0339:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0278:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_1], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_027b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_027b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_027b
.L_lambda_simple_env_end_027b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_027b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_027b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_027b
.L_lambda_simple_params_end_027b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_027b
	jmp .L_lambda_simple_end_027b
.L_lambda_simple_code_027b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_027b
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_027b:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 2187
	push rax
	mov rax, L_constants + 2251
	push rax
	push 2	; arg count
	mov rax, qword [free_var_83]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0348:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0348
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0348
.L_tc_recycle_frame_done_0348:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_027b:	; new closure is in rax
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_027c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_027c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_027c
.L_lambda_simple_env_end_027c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_027c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_027c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_027c
.L_lambda_simple_params_end_027c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_027c
	jmp .L_lambda_simple_end_027c
.L_lambda_simple_code_027c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_027c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_027c:
	enter 0, 0
	;debug: preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_027d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_027d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_027d
.L_lambda_simple_env_end_027d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_027d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_027d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_027d
.L_lambda_simple_params_end_027d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_027d
	jmp .L_lambda_simple_end_027d
.L_lambda_simple_code_027d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_027d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_027d:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01e4
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01db
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_27]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_034a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_034a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_034a
.L_tc_recycle_frame_done_034a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01db
.L_if_else_01db:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01da
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_25]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_034b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_034b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_034b
.L_tc_recycle_frame_done_034b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01da
.L_if_else_01da:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01d9
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_034c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_034c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_034c
.L_tc_recycle_frame_done_034c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01d9
.L_if_else_01d9:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_034d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_034d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_034d
.L_tc_recycle_frame_done_034d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01d9:
.L_if_end_01da:
.L_if_end_01db:
	jmp .L_if_end_01e4
.L_if_else_01e4:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01e3
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01de
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_25]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_034e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_034e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_034e
.L_tc_recycle_frame_done_034e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01de
.L_if_else_01de:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01dd
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_25]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_034f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_034f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_034f
.L_tc_recycle_frame_done_034f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01dd
.L_if_else_01dd:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01dc
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0350:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0350
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0350
.L_tc_recycle_frame_done_0350:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01dc
.L_if_else_01dc:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0351:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0351
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0351
.L_tc_recycle_frame_done_0351:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01dc:
.L_if_end_01dd:
.L_if_end_01de:
	jmp .L_if_end_01e3
.L_if_else_01e3:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01e2
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01e1
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0352:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0352
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0352
.L_tc_recycle_frame_done_0352:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01e1
.L_if_else_01e1:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01e0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0353:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0353
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0353
.L_tc_recycle_frame_done_0353:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01e0
.L_if_else_01e0:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01df
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0354:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0354
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0354
.L_tc_recycle_frame_done_0354:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01df
.L_if_else_01df:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0355:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0355
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0355
.L_tc_recycle_frame_done_0355:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01df:
.L_if_end_01e0:
.L_if_end_01e1:
	jmp .L_if_end_01e2
.L_if_else_01e2:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0356:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0356
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0356
.L_tc_recycle_frame_done_0356:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01e2:
.L_if_end_01e3:
.L_if_end_01e4:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_027d:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_027e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_027e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_027e
.L_lambda_simple_env_end_027e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_027e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_027e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_027e
.L_lambda_simple_params_end_027e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_027e
	jmp .L_lambda_simple_end_027e
.L_lambda_simple_code_027e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_027e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_027e:
	enter 0, 0
	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	push rax
	mov rdi, 8 * 3
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_005c:
	cmp rsi, 2
	je .L_lambda_opt_env_end_005c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_005c
.L_lambda_opt_env_end_005c:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_005c:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_005c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_005c
.L_lambda_opt_params_end_005c:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_005c
	jmp .L_lambda_opt_end_005c
.L_lambda_opt_code_005c:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_005c
	ja .L_lambda_opt_arity_check_more_005c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_005c:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0113:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0113
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0113
.L_lambda_opt_stack_shrink_loop_exit_0113:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_0114:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0114
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0114
.L_lambda_opt_stack_shrink_loop_exit_0114:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_005c
.L_lambda_opt_arity_check_exact_005c:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0112:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0112
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0112
.L_lambda_opt_stack_shrink_loop_exit_0112:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_005c:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01e5
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, L_constants + 2135
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin-
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0357:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0357
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0357
.L_tc_recycle_frame_done_0357:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01e5
.L_if_else_01e5:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, L_constants + 2135
	push rax
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3
	mov rax, qword [free_var_86]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_027f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_027f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_027f
.L_lambda_simple_env_end_027f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_027f:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_027f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_027f
.L_lambda_simple_params_end_027f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_027f
	jmp .L_lambda_simple_end_027f
.L_lambda_simple_code_027f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_027f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_027f:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin-
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0359:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0359
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0359
.L_tc_recycle_frame_done_0359:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_027f:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0358:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0358
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0358
.L_tc_recycle_frame_done_0358:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01e5:
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_005c:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_027e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0349:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0349
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0349
.L_tc_recycle_frame_done_0349:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_027c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_2], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0280:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0280
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0280
.L_lambda_simple_env_end_0280:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0280:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0280
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0280
.L_lambda_simple_params_end_0280:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0280
	jmp .L_lambda_simple_end_0280
.L_lambda_simple_code_0280:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0280
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0280:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 2187
	push rax
	mov rax, L_constants + 2279
	push rax
	push 2	; arg count
	mov rax, qword [free_var_83]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_035a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_035a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_035a
.L_tc_recycle_frame_done_035a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0280:	; new closure is in rax
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0281:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0281
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0281
.L_lambda_simple_env_end_0281:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0281:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0281
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0281
.L_lambda_simple_params_end_0281:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0281
	jmp .L_lambda_simple_end_0281
.L_lambda_simple_code_0281:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0281
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0281:
	enter 0, 0
	;debug: preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0282:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0282
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0282
.L_lambda_simple_env_end_0282:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0282:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0282
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0282
.L_lambda_simple_params_end_0282:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0282
	jmp .L_lambda_simple_end_0282
.L_lambda_simple_code_0282:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0282
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0282:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01f1
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01e8
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_24]	; free var __bin-mul-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_035c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_035c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_035c
.L_tc_recycle_frame_done_035c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01e8
.L_if_else_01e8:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01e7
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_22]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_035d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_035d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_035d
.L_tc_recycle_frame_done_035d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01e7
.L_if_else_01e7:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01e6
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_035e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_035e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_035e
.L_tc_recycle_frame_done_035e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01e6
.L_if_else_01e6:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_035f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_035f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_035f
.L_tc_recycle_frame_done_035f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01e6:
.L_if_end_01e7:
.L_if_end_01e8:
	jmp .L_if_end_01f1
.L_if_else_01f1:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01f0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01eb
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_22]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0360:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0360
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0360
.L_tc_recycle_frame_done_0360:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01eb
.L_if_else_01eb:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01ea
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_22]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0361:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0361
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0361
.L_tc_recycle_frame_done_0361:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01ea
.L_if_else_01ea:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01e9
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0362:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0362
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0362
.L_tc_recycle_frame_done_0362:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01e9
.L_if_else_01e9:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0363:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0363
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0363
.L_tc_recycle_frame_done_0363:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01e9:
.L_if_end_01ea:
.L_if_end_01eb:
	jmp .L_if_end_01f0
.L_if_else_01f0:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01ef
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01ee
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0364:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0364
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0364
.L_tc_recycle_frame_done_0364:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01ee
.L_if_else_01ee:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01ed
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0365:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0365
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0365
.L_tc_recycle_frame_done_0365:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01ed
.L_if_else_01ed:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01ec
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0366:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0366
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0366
.L_tc_recycle_frame_done_0366:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01ec
.L_if_else_01ec:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0367:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0367
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0367
.L_tc_recycle_frame_done_0367:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01ec:
.L_if_end_01ed:
.L_if_end_01ee:
	jmp .L_if_end_01ef
.L_if_else_01ef:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0368:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0368
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0368
.L_tc_recycle_frame_done_0368:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01ef:
.L_if_end_01f0:
.L_if_end_01f1:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0282:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0283:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0283
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0283
.L_lambda_simple_env_end_0283:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0283:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0283
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0283
.L_lambda_simple_params_end_0283:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0283
	jmp .L_lambda_simple_end_0283
.L_lambda_simple_code_0283:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0283
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0283:
	enter 0, 0
	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	push rax
	mov rdi, 8 * 3
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_005d:
	cmp rsi, 2
	je .L_lambda_opt_env_end_005d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_005d
.L_lambda_opt_env_end_005d:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_005d:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_005d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_005d
.L_lambda_opt_params_end_005d:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_005d
	jmp .L_lambda_opt_end_005d
.L_lambda_opt_code_005d:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_005d
	ja .L_lambda_opt_arity_check_more_005d
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_005d:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0116:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0116
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0116
.L_lambda_opt_stack_shrink_loop_exit_0116:
	lea r10, [rsp + 8 * 0 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_0117:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0117
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0117
.L_lambda_opt_stack_shrink_loop_exit_0117:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_005d
.L_lambda_opt_arity_check_exact_005d:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0115:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0115
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0115
.L_lambda_opt_stack_shrink_loop_exit_0115:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_005d:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2270
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin*
	push rax
	push 3	; arg count
	mov rax, qword [free_var_86]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0369:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0369
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0369
.L_tc_recycle_frame_done_0369:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_005d:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0283:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_035b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_035b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_035b
.L_tc_recycle_frame_done_035b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0281:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_0], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0284:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0284
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0284
.L_lambda_simple_env_end_0284:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0284:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0284
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0284
.L_lambda_simple_params_end_0284:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0284
	jmp .L_lambda_simple_end_0284
.L_lambda_simple_code_0284:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0284
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0284:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 2187
	push rax
	mov rax, L_constants + 2298
	push rax
	push 2	; arg count
	mov rax, qword [free_var_83]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_036a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_036a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_036a
.L_tc_recycle_frame_done_036a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0284:	; new closure is in rax
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0285:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0285
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0285
.L_lambda_simple_env_end_0285:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0285:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0285
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0285
.L_lambda_simple_params_end_0285:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0285
	jmp .L_lambda_simple_end_0285
.L_lambda_simple_code_0285:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0285
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0285:
	enter 0, 0
	;debug: preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0286:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0286
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0286
.L_lambda_simple_env_end_0286:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0286:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0286
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0286
.L_lambda_simple_params_end_0286:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0286
	jmp .L_lambda_simple_end_0286
.L_lambda_simple_code_0286:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0286
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0286:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01fd
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01f4
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_15]	; free var __bin-div-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_036c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_036c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_036c
.L_tc_recycle_frame_done_036c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01f4
.L_if_else_01f4:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01f3
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_036d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_036d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_036d
.L_tc_recycle_frame_done_036d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01f3
.L_if_else_01f3:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01f2
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_036e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_036e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_036e
.L_tc_recycle_frame_done_036e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01f2
.L_if_else_01f2:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_036f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_036f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_036f
.L_tc_recycle_frame_done_036f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01f2:
.L_if_end_01f3:
.L_if_end_01f4:
	jmp .L_if_end_01fd
.L_if_else_01fd:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01fc
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01f7
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0370:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0370
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0370
.L_tc_recycle_frame_done_0370:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01f7
.L_if_else_01f7:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01f6
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0371:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0371
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0371
.L_tc_recycle_frame_done_0371:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01f6
.L_if_else_01f6:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01f5
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0372:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0372
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0372
.L_tc_recycle_frame_done_0372:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01f5
.L_if_else_01f5:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0373:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0373
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0373
.L_tc_recycle_frame_done_0373:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01f5:
.L_if_end_01f6:
.L_if_end_01f7:
	jmp .L_if_end_01fc
.L_if_else_01fc:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01fb
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01fa
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0374:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0374
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0374
.L_tc_recycle_frame_done_0374:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01fa
.L_if_else_01fa:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01f9
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0375:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0375
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0375
.L_tc_recycle_frame_done_0375:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01f9
.L_if_else_01f9:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01f8
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0376:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0376
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0376
.L_tc_recycle_frame_done_0376:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01f8
.L_if_else_01f8:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0377:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0377
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0377
.L_tc_recycle_frame_done_0377:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01f8:
.L_if_end_01f9:
.L_if_end_01fa:
	jmp .L_if_end_01fb
.L_if_else_01fb:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0378:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0378
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0378
.L_tc_recycle_frame_done_0378:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01fb:
.L_if_end_01fc:
.L_if_end_01fd:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0286:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0287:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0287
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0287
.L_lambda_simple_env_end_0287:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0287:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0287
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0287
.L_lambda_simple_params_end_0287:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0287
	jmp .L_lambda_simple_end_0287
.L_lambda_simple_code_0287:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0287
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0287:
	enter 0, 0
	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	push rax
	mov rdi, 8 * 3
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_005e:
	cmp rsi, 2
	je .L_lambda_opt_env_end_005e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_005e
.L_lambda_opt_env_end_005e:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_005e:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_005e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_005e
.L_lambda_opt_params_end_005e:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_005e
	jmp .L_lambda_opt_end_005e
.L_lambda_opt_code_005e:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_005e
	ja .L_lambda_opt_arity_check_more_005e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_005e:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0119:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0119
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0119
.L_lambda_opt_stack_shrink_loop_exit_0119:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_011a:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_011a
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_011a
.L_lambda_opt_stack_shrink_loop_exit_011a:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_005e
.L_lambda_opt_arity_check_exact_005e:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0118:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0118
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0118
.L_lambda_opt_stack_shrink_loop_exit_0118:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_005e:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01fe
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, L_constants + 2270
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin/
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0379:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0379
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0379
.L_tc_recycle_frame_done_0379:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_01fe
.L_if_else_01fe:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, L_constants + 2270
	push rax
	mov rax, qword [free_var_0]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3
	mov rax, qword [free_var_86]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0288:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0288
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0288
.L_lambda_simple_env_end_0288:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0288:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0288
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0288
.L_lambda_simple_params_end_0288:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0288
	jmp .L_lambda_simple_end_0288
.L_lambda_simple_code_0288:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0288
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0288:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin/
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_037b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_037b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_037b
.L_tc_recycle_frame_done_037b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0288:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_037a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_037a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_037a
.L_tc_recycle_frame_done_037a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01fe:
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_005e:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0287:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_036b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_036b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_036b
.L_tc_recycle_frame_done_036b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0285:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_3], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0289:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0289
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0289
.L_lambda_simple_env_end_0289:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0289:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0289
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0289
.L_lambda_simple_params_end_0289:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0289
	jmp .L_lambda_simple_end_0289
.L_lambda_simple_code_0289:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0289
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0289:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1
	mov rax, qword [free_var_153]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_01ff
	mov rax, L_constants + 2270
	jmp .L_if_end_01ff
.L_if_else_01ff:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var fact
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_0]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_037c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_037c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_037c
.L_tc_recycle_frame_done_037c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_01ff:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0289:	; new closure is in rax
	mov qword [free_var_85], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_4], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_5], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_7], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_8], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_6], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_028a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_028a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_028a
.L_lambda_simple_env_end_028a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_028a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_028a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_028a
.L_lambda_simple_params_end_028a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_028a
	jmp .L_lambda_simple_end_028a
.L_lambda_simple_code_028a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_028a
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_028a:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 2408
	push rax
	mov rax, L_constants + 2399
	push rax
	push 2	; arg count
	mov rax, qword [free_var_83]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_037d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_037d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_037d
.L_tc_recycle_frame_done_037d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_028a:	; new closure is in rax
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_028b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_028b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_028b
.L_lambda_simple_env_end_028b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_028b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_028b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_028b
.L_lambda_simple_params_end_028b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_028b
	jmp .L_lambda_simple_end_028b
.L_lambda_simple_code_028b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_028b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_028b:
	enter 0, 0
	;debug: preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_028c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_028c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_028c
.L_lambda_simple_env_end_028c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_028c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_028c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_028c
.L_lambda_simple_params_end_028c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_028c
	jmp .L_lambda_simple_end_028c
.L_lambda_simple_code_028c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_028c
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_028c:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_028d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_028d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_028d
.L_lambda_simple_env_end_028d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_028d:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_028d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_028d
.L_lambda_simple_params_end_028d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_028d
	jmp .L_lambda_simple_end_028d
.L_lambda_simple_code_028d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_028d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_028d:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_020b
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0202
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator-zz
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_037f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_037f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_037f
.L_tc_recycle_frame_done_037f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0202
.L_if_else_0202:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0201
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0380:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0380
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0380
.L_tc_recycle_frame_done_0380:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0201
.L_if_else_0201:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0200
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0381:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0381
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0381
.L_tc_recycle_frame_done_0381:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0200
.L_if_else_0200:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0382:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0382
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0382
.L_tc_recycle_frame_done_0382:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0200:
.L_if_end_0201:
.L_if_end_0202:
	jmp .L_if_end_020b
.L_if_else_020b:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_020a
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0205
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0383:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0383
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0383
.L_tc_recycle_frame_done_0383:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0205
.L_if_else_0205:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0204
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0384:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0384
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0384
.L_tc_recycle_frame_done_0384:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0204
.L_if_else_0204:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0203
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0385:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0385
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0385
.L_tc_recycle_frame_done_0385:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0203
.L_if_else_0203:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0386:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0386
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0386
.L_tc_recycle_frame_done_0386:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0203:
.L_if_end_0204:
.L_if_end_0205:
	jmp .L_if_end_020a
.L_if_else_020a:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0209
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_92]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0208
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0387:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0387
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0387
.L_tc_recycle_frame_done_0387:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0208
.L_if_else_0208:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0207
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0388:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0388
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0388
.L_tc_recycle_frame_done_0388:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0207
.L_if_else_0207:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_117]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0206
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0389:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0389
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0389
.L_tc_recycle_frame_done_0389:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0206
.L_if_else_0206:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_038a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_038a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_038a
.L_tc_recycle_frame_done_038a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0206:
.L_if_end_0207:
.L_if_end_0208:
	jmp .L_if_end_0209
.L_if_else_0209:
	;debug: preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_038b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_038b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_038b
.L_tc_recycle_frame_done_038b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0209:
.L_if_end_020a:
.L_if_end_020b:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_028d:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_028c:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_028e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_028e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_028e
.L_lambda_simple_env_end_028e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_028e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_028e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_028e
.L_lambda_simple_params_end_028e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_028e
	jmp .L_lambda_simple_end_028e
.L_lambda_simple_code_028e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_028e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_028e:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, qword [free_var_20]	; free var __bin-less-than-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_19]	; free var __bin-less-than-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_21]	; free var __bin-less-than-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3
	mov rax, PARAM(0)	; param make-bin-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_028f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_028f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_028f
.L_lambda_simple_env_end_028f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_028f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_028f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_028f
.L_lambda_simple_params_end_028f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_028f
	jmp .L_lambda_simple_end_028f
.L_lambda_simple_code_028f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_028f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_028f:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, qword [free_var_17]	; free var __bin-equal-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_16]	; free var __bin-equal-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_18]	; free var __bin-equal-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var make-bin-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0290:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0290
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0290
.L_lambda_simple_env_end_0290:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0290:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0290
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0290
.L_lambda_simple_params_end_0290:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0290
	jmp .L_lambda_simple_end_0290
.L_lambda_simple_code_0290:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0290
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0290:
	enter 0, 0
	;debug: preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0291:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_0291
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0291
.L_lambda_simple_env_end_0291:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0291:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0291
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0291
.L_lambda_simple_params_end_0291:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0291
	jmp .L_lambda_simple_end_0291
.L_lambda_simple_code_0291:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0291
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0291:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_038f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_038f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_038f
.L_tc_recycle_frame_done_038f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0291:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0292:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_0292
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0292
.L_lambda_simple_env_end_0292:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0292:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0292
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0292
.L_lambda_simple_params_end_0292:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0292
	jmp .L_lambda_simple_end_0292
.L_lambda_simple_code_0292:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0292
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0292:
	enter 0, 0
	;debug: preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 6	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0293:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_0293
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0293
.L_lambda_simple_env_end_0293:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0293:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0293
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0293
.L_lambda_simple_params_end_0293:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0293
	jmp .L_lambda_simple_end_0293
.L_lambda_simple_code_0293:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0293
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0293:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0391:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0391
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0391
.L_tc_recycle_frame_done_0391:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0293:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 6	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0294:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_0294
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0294
.L_lambda_simple_env_end_0294:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0294:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0294
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0294
.L_lambda_simple_params_end_0294:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0294
	jmp .L_lambda_simple_end_0294
.L_lambda_simple_code_0294:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0294
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0294:
	enter 0, 0
	;debug: preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 7	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0295:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_0295
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0295
.L_lambda_simple_env_end_0295:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0295:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0295
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0295
.L_lambda_simple_params_end_0295:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0295
	jmp .L_lambda_simple_end_0295
.L_lambda_simple_code_0295:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0295
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0295:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin>?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0393:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0393
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0393
.L_tc_recycle_frame_done_0393:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0295:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 7	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0296:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_0296
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0296
.L_lambda_simple_env_end_0296:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0296:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0296
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0296
.L_lambda_simple_params_end_0296:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0296
	jmp .L_lambda_simple_end_0296
.L_lambda_simple_code_0296:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0296
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0296:
	enter 0, 0
	;debug: preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 8	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0297:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_0297
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0297
.L_lambda_simple_env_end_0297:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0297:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0297
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0297
.L_lambda_simple_params_end_0297:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0297
	jmp .L_lambda_simple_end_0297
.L_lambda_simple_code_0297:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0297
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0297:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 9	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0298:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_0298
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0298
.L_lambda_simple_env_end_0298:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0298:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0298
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0298
.L_lambda_simple_params_end_0298:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0298
	jmp .L_lambda_simple_end_0298
.L_lambda_simple_code_0298:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0298
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0298:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 10	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0299:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 9
	je .L_lambda_simple_env_end_0299
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0299
.L_lambda_simple_env_end_0299:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0299:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0299
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0299
.L_lambda_simple_params_end_0299:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0299
	jmp .L_lambda_simple_end_0299
.L_lambda_simple_code_0299:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0299
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0299:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0030
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin-ordering
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_020c
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0396:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0396
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0396
.L_tc_recycle_frame_done_0396:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_020c
.L_if_else_020c:
	mov rax, L_constants + 2
.L_if_end_020c:
.L_or_end_0030:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0299:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	push rax
	mov rdi, 8 * 10
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_005f:
	cmp rsi, 9
	je .L_lambda_opt_env_end_005f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_005f
.L_lambda_opt_env_end_005f:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_005f:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_005f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_005f
.L_lambda_opt_params_end_005f:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_005f
	jmp .L_lambda_opt_end_005f
.L_lambda_opt_code_005f:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_005f
	ja .L_lambda_opt_arity_check_more_005f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_005f:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_011c:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_011c
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_011c
.L_lambda_opt_stack_shrink_loop_exit_011c:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_011d:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_011d
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_011d
.L_lambda_opt_stack_shrink_loop_exit_011d:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_005f
.L_lambda_opt_arity_check_exact_005f:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_011b:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_011b
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_011b
.L_lambda_opt_stack_shrink_loop_exit_011b:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_005f:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0397:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0397
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0397
.L_tc_recycle_frame_done_0397:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_005f:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0298:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0395:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0395
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0395
.L_tc_recycle_frame_done_0395:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0297:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 8	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_029a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_029a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_029a
.L_lambda_simple_env_end_029a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_029a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_029a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_029a
.L_lambda_simple_params_end_029a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_029a
	jmp .L_lambda_simple_end_029a
.L_lambda_simple_code_029a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_029a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_029a:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 4]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	push rax
	push 1
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_4], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin<=?
	push rax
	push 1
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_5], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin>?
	push rax
	push 1
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_7], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var bin>=?
	push rax
	push 1
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_8], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 3]
	mov rax, qword [rax + 8 * 0]	; bound var bin=?
	push rax
	push 1
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_6], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_029a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0394:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0394
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0394
.L_tc_recycle_frame_done_0394:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0296:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0392:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0392
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0392
.L_tc_recycle_frame_done_0392:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0294:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0390:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0390
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0390
.L_tc_recycle_frame_done_0390:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0292:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_038e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_038e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_038e
.L_tc_recycle_frame_done_038e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0290:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_038d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_038d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_038d
.L_tc_recycle_frame_done_038d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_028f:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_038c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_038c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_038c
.L_tc_recycle_frame_done_038c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_028e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_037e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_037e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_037e
.L_tc_recycle_frame_done_037e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_028b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_74], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_73], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_75], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_77], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_76], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_029b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_029b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_029b
.L_lambda_simple_env_end_029b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_029b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_029b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_029b
.L_lambda_simple_params_end_029b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_029b
	jmp .L_lambda_simple_end_029b
.L_lambda_simple_code_029b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_029b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_029b:
	enter 0, 0
	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_0060:
	cmp rsi, 1
	je .L_lambda_opt_env_end_0060
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0060
.L_lambda_opt_env_end_0060:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0060:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_0060
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0060
.L_lambda_opt_params_end_0060:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0060
	jmp .L_lambda_opt_end_0060
.L_lambda_opt_code_0060:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_0060
	ja .L_lambda_opt_arity_check_more_0060
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0060:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_011f:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_011f
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_011f
.L_lambda_opt_stack_shrink_loop_exit_011f:
	lea r10, [rsp + 8 * 0 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_0120:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0120
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0120
.L_lambda_opt_stack_shrink_loop_exit_0120:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0060
.L_lambda_opt_arity_check_exact_0060:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_011e:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_011e
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_011e
.L_lambda_opt_stack_shrink_loop_exit_011e:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0060:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_104]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0398:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0398
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0398
.L_tc_recycle_frame_done_0398:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_0060:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_029b:	; new closure is in rax
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_029c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_029c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_029c
.L_lambda_simple_env_end_029c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_029c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_029c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_029c
.L_lambda_simple_params_end_029c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_029c
	jmp .L_lambda_simple_end_029c
.L_lambda_simple_code_029c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_029c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_029c:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_74], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_5]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_73], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_75], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_7]	; free var >
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_77], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_8]	; free var >=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_76], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_029c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_71], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_72], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2569
	push rax
	push 1
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2573
	push rax
	push 1
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_029d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_029d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_029d
.L_lambda_simple_env_end_029d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_029d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_029d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_029d
.L_lambda_simple_params_end_029d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_029d
	jmp .L_lambda_simple_end_029d
.L_lambda_simple_code_029d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_029d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_029d:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_029e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_029e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_029e
.L_lambda_simple_env_end_029e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_029e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_029e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_029e
.L_lambda_simple_params_end_029e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_029e
	jmp .L_lambda_simple_end_029e
.L_lambda_simple_code_029e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_029e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_029e:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, L_constants + 2571
	push rax
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, L_constants + 2569
	push rax
	push 3
	mov rax, qword [free_var_73]	; free var char<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_020d
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var delta
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	push 1
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_90]	; free var integer->char
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0399:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0399
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0399
.L_tc_recycle_frame_done_0399:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_020d
.L_if_else_020d:
	mov rax, PARAM(0)	; param ch
.L_if_end_020d:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_029e:	; new closure is in rax
	mov qword [free_var_71], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_029f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_029f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_029f
.L_lambda_simple_env_end_029f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_029f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_029f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_029f
.L_lambda_simple_params_end_029f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_029f
	jmp .L_lambda_simple_end_029f
.L_lambda_simple_code_029f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_029f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_029f:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, L_constants + 2575
	push rax
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, L_constants + 2573
	push rax
	push 3
	mov rax, qword [free_var_73]	; free var char<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_020e
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var delta
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	push 1
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_90]	; free var integer->char
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_039a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_039a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_039a
.L_tc_recycle_frame_done_039a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_020e
.L_if_else_020e:
	mov rax, PARAM(0)	; param ch
.L_if_end_020e:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_029f:	; new closure is in rax
	mov qword [free_var_72], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_029d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_67], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_66], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_68], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_70], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_69], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02a0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02a0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02a0
.L_lambda_simple_env_end_02a0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02a0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02a0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02a0
.L_lambda_simple_params_end_02a0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02a0
	jmp .L_lambda_simple_end_02a0
.L_lambda_simple_code_02a0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02a0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02a0:
	enter 0, 0
	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_0061:
	cmp rsi, 1
	je .L_lambda_opt_env_end_0061
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0061
.L_lambda_opt_env_end_0061:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0061:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_0061
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0061
.L_lambda_opt_params_end_0061:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0061
	jmp .L_lambda_opt_end_0061
.L_lambda_opt_code_0061:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_0061
	ja .L_lambda_opt_arity_check_more_0061
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0061:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0122:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0122
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0122
.L_lambda_opt_stack_shrink_loop_exit_0122:
	lea r10, [rsp + 8 * 0 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_0123:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0123
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0123
.L_lambda_opt_stack_shrink_loop_exit_0123:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0061
.L_lambda_opt_arity_check_exact_0061:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0121:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0121
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0121
.L_lambda_opt_stack_shrink_loop_exit_0121:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0061:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02a1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02a1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02a1
.L_lambda_simple_env_end_02a1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02a1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02a1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02a1
.L_lambda_simple_params_end_02a1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02a1
	jmp .L_lambda_simple_end_02a1
.L_lambda_simple_code_02a1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02a1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02a1:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	push 1
	mov rax, qword [free_var_71]	; free var char-downcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_039c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_039c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_039c
.L_tc_recycle_frame_done_039c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02a1:	; new closure is in rax
	push rax
	push 2
	mov rax, qword [free_var_104]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_039b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_039b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_039b
.L_tc_recycle_frame_done_039b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_0061:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02a0:	; new closure is in rax
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02a2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02a2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02a2
.L_lambda_simple_env_end_02a2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02a2:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02a2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02a2
.L_lambda_simple_params_end_02a2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02a2
	jmp .L_lambda_simple_end_02a2
.L_lambda_simple_code_02a2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02a2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02a2:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_67], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_5]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_66], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_68], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_7]	; free var >
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_70], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_8]	; free var >=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_69], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02a2:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_127], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_133], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02a3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02a3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02a3
.L_lambda_simple_env_end_02a3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02a3:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02a3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02a3
.L_lambda_simple_params_end_02a3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02a3
	jmp .L_lambda_simple_end_02a3
.L_lambda_simple_code_02a3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02a3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02a3:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02a4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02a4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02a4
.L_lambda_simple_env_end_02a4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02a4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02a4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02a4
.L_lambda_simple_params_end_02a4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02a4
	jmp .L_lambda_simple_end_02a4
.L_lambda_simple_code_02a4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02a4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02a4:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1
	mov rax, qword [free_var_120]	; free var string->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var char-case-converter
	push rax
	push 2
	mov rax, qword [free_var_104]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_95]	; free var list->string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_039d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_039d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_039d
.L_tc_recycle_frame_done_039d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02a4:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02a3:	; new closure is in rax
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02a5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02a5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02a5
.L_lambda_simple_env_end_02a5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02a5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02a5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02a5
.L_lambda_simple_params_end_02a5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02a5
	jmp .L_lambda_simple_end_02a5
.L_lambda_simple_code_02a5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02a5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02a5:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_71]	; free var char-downcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-string-case-converter
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_127], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_72]	; free var char-upcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-string-case-converter
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_133], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02a5:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_135], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_134], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_136], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_137], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_138], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_123], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_122], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_124], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_125], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_126], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02a6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02a6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02a6
.L_lambda_simple_env_end_02a6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02a6:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02a6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02a6
.L_lambda_simple_params_end_02a6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02a6
	jmp .L_lambda_simple_end_02a6
.L_lambda_simple_code_02a6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02a6
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02a6:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02a7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02a7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02a7
.L_lambda_simple_env_end_02a7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02a7:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_02a7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02a7
.L_lambda_simple_params_end_02a7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02a7
	jmp .L_lambda_simple_end_02a7
.L_lambda_simple_code_02a7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02a7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02a7:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02a8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02a8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02a8
.L_lambda_simple_env_end_02a8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02a8:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02a8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02a8
.L_lambda_simple_params_end_02a8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02a8
	jmp .L_lambda_simple_end_02a8
.L_lambda_simple_code_02a8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_02a8
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02a8:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_020f
	; preparing a non-tail-call
	mov rax, PARAM(4)	; param len2
	push rax
	mov rax, PARAM(2)	; param len1
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_020f
.L_if_else_020f:
	mov rax, L_constants + 2
.L_if_end_020f:
	cmp rax, sob_boolean_false
	jne .L_or_end_0031
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0211
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2
	mov rax, qword [free_var_129]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2
	mov rax, qword [free_var_129]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var char<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0032
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2
	mov rax, qword [free_var_129]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2
	mov rax, qword [free_var_129]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var char=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0210
	;debug: preparing a tail-call
	mov rax, PARAM(4)	; param len2
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 5
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_039f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_039f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_039f
.L_tc_recycle_frame_done_039f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0210
.L_if_else_0210:
	mov rax, L_constants + 2
.L_if_end_0210:
.L_or_end_0032:
	jmp .L_if_end_0211
.L_if_else_0211:
	mov rax, L_constants + 2
.L_if_end_0211:
.L_or_end_0031:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_02a8:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	;debug: preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02a9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02a9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02a9
.L_lambda_simple_env_end_02a9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02a9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02a9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02a9
.L_lambda_simple_params_end_02a9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02a9
	jmp .L_lambda_simple_end_02a9
.L_lambda_simple_code_02a9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02a9
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02a9:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1
	mov rax, qword [free_var_128]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str1
	push rax
	push 1
	mov rax, qword [free_var_128]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02aa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_02aa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02aa
.L_lambda_simple_env_end_02aa:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02aa:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_02aa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02aa
.L_lambda_simple_params_end_02aa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02aa
	jmp .L_lambda_simple_end_02aa
.L_lambda_simple_code_02aa:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02aa
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02aa:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	push 2
	mov rax, qword [free_var_5]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0212
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, L_constants + 2135
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 5
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03a2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03a2
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03a2
.L_tc_recycle_frame_done_03a2:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0212
.L_if_else_0212:
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, L_constants + 2135
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 5
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03a3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03a3
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03a3
.L_tc_recycle_frame_done_03a3:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0212:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02aa:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03a1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03a1
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03a1
.L_tc_recycle_frame_done_03a1:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02a9:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02ab:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02ab
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02ab
.L_lambda_simple_env_end_02ab:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02ab:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02ab
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02ab
.L_lambda_simple_params_end_02ab:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02ab
	jmp .L_lambda_simple_end_02ab
.L_lambda_simple_code_02ab:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02ab
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02ab:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02ac:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_02ac
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02ac
.L_lambda_simple_env_end_02ac:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02ac:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02ac
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02ac
.L_lambda_simple_params_end_02ac:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02ac
	jmp .L_lambda_simple_end_02ac
.L_lambda_simple_code_02ac:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02ac
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02ac:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02ad:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_02ad
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02ad
.L_lambda_simple_env_end_02ad:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02ad:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02ad
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02ad
.L_lambda_simple_params_end_02ad:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02ad
	jmp .L_lambda_simple_end_02ad
.L_lambda_simple_code_02ad:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02ad
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02ad:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0033
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var binary-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0213
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03a5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03a5
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03a5
.L_tc_recycle_frame_done_03a5:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0213
.L_if_else_0213:
	mov rax, L_constants + 2
.L_if_end_0213:
.L_or_end_0033:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02ad:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	push rax
	mov rdi, 8 * 5
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_0062:
	cmp rsi, 4
	je .L_lambda_opt_env_end_0062
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0062
.L_lambda_opt_env_end_0062:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0062:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_0062
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0062
.L_lambda_opt_params_end_0062:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0062
	jmp .L_lambda_opt_end_0062
.L_lambda_opt_code_0062:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0062
	ja .L_lambda_opt_arity_check_more_0062
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0062:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0125:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0125
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0125
.L_lambda_opt_stack_shrink_loop_exit_0125:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_0126:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0126
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0126
.L_lambda_opt_stack_shrink_loop_exit_0126:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0062
.L_lambda_opt_arity_check_exact_0062:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0124:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0124
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0124
.L_lambda_opt_stack_shrink_loop_exit_0124:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0062:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03a6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03a6
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03a6
.L_tc_recycle_frame_done_03a6:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0062:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02ac:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03a4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03a4
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03a4
.L_tc_recycle_frame_done_03a4:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02ab:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03a0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03a0
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03a0
.L_tc_recycle_frame_done_03a0:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02a7:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_039e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_039e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_039e
.L_tc_recycle_frame_done_039e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02a6:	; new closure is in rax
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02ae:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02ae
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02ae
.L_lambda_simple_env_end_02ae:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02ae:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02ae
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02ae
.L_lambda_simple_params_end_02ae:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02ae
	jmp .L_lambda_simple_end_02ae
.L_lambda_simple_code_02ae:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02ae
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02ae:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_75]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_74]	; free var char<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_135], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_68]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_67]	; free var char-ci<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_123], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_75]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_77]	; free var char>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_138], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_68]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_70]	; free var char-ci>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_126], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02ae:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02af:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02af
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02af
.L_lambda_simple_env_end_02af:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02af:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02af
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02af
.L_lambda_simple_params_end_02af:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02af
	jmp .L_lambda_simple_end_02af
.L_lambda_simple_code_02af:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02af
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02af:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02b0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02b0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02b0
.L_lambda_simple_env_end_02b0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02b0:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_02b0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02b0
.L_lambda_simple_params_end_02b0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02b0
	jmp .L_lambda_simple_end_02b0
.L_lambda_simple_code_02b0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02b0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02b0:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02b1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02b1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02b1
.L_lambda_simple_env_end_02b1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02b1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02b1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02b1
.L_lambda_simple_params_end_02b1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02b1
	jmp .L_lambda_simple_end_02b1
.L_lambda_simple_code_02b1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_02b1
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02b1:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0034
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2
	mov rax, qword [free_var_129]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2
	mov rax, qword [free_var_129]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var char<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0034
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0215
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2
	mov rax, qword [free_var_129]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2
	mov rax, qword [free_var_129]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var char=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0214
	;debug: preparing a tail-call
	mov rax, PARAM(4)	; param len2
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 5
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03a8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03a8
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03a8
.L_tc_recycle_frame_done_03a8:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0214
.L_if_else_0214:
	mov rax, L_constants + 2
.L_if_end_0214:
	jmp .L_if_end_0215
.L_if_else_0215:
	mov rax, L_constants + 2
.L_if_end_0215:
.L_or_end_0034:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_02b1:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	;debug: preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02b2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02b2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02b2
.L_lambda_simple_env_end_02b2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02b2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02b2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02b2
.L_lambda_simple_params_end_02b2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02b2
	jmp .L_lambda_simple_end_02b2
.L_lambda_simple_code_02b2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02b2
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02b2:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1
	mov rax, qword [free_var_128]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str1
	push rax
	push 1
	mov rax, qword [free_var_128]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02b3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_02b3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02b3
.L_lambda_simple_env_end_02b3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02b3:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_02b3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02b3
.L_lambda_simple_params_end_02b3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02b3
	jmp .L_lambda_simple_end_02b3
.L_lambda_simple_code_02b3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02b3
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02b3:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	push 2
	mov rax, qword [free_var_5]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0216
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, L_constants + 2135
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 5
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03ab:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03ab
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03ab
.L_tc_recycle_frame_done_03ab:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0216
.L_if_else_0216:
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, L_constants + 2135
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 5
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03ac:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03ac
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03ac
.L_tc_recycle_frame_done_03ac:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0216:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02b3:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03aa:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03aa
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03aa
.L_tc_recycle_frame_done_03aa:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02b2:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02b4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02b4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02b4
.L_lambda_simple_env_end_02b4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02b4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02b4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02b4
.L_lambda_simple_params_end_02b4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02b4
	jmp .L_lambda_simple_end_02b4
.L_lambda_simple_code_02b4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02b4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02b4:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02b5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_02b5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02b5
.L_lambda_simple_env_end_02b5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02b5:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02b5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02b5
.L_lambda_simple_params_end_02b5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02b5
	jmp .L_lambda_simple_end_02b5
.L_lambda_simple_code_02b5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02b5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02b5:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02b6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_02b6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02b6
.L_lambda_simple_env_end_02b6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02b6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02b6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02b6
.L_lambda_simple_params_end_02b6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02b6
	jmp .L_lambda_simple_end_02b6
.L_lambda_simple_code_02b6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02b6
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02b6:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0035
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var binary-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0217
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03ae:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03ae
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03ae
.L_tc_recycle_frame_done_03ae:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0217
.L_if_else_0217:
	mov rax, L_constants + 2
.L_if_end_0217:
.L_or_end_0035:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02b6:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	push rax
	mov rdi, 8 * 5
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_0063:
	cmp rsi, 4
	je .L_lambda_opt_env_end_0063
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0063
.L_lambda_opt_env_end_0063:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0063:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_0063
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0063
.L_lambda_opt_params_end_0063:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0063
	jmp .L_lambda_opt_end_0063
.L_lambda_opt_code_0063:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0063
	ja .L_lambda_opt_arity_check_more_0063
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0063:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0128:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0128
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0128
.L_lambda_opt_stack_shrink_loop_exit_0128:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_0129:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0129
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0129
.L_lambda_opt_stack_shrink_loop_exit_0129:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0063
.L_lambda_opt_arity_check_exact_0063:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0127:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0127
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0127
.L_lambda_opt_stack_shrink_loop_exit_0127:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0063:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03af:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03af
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03af
.L_tc_recycle_frame_done_03af:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0063:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02b5:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03ad:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03ad
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03ad
.L_tc_recycle_frame_done_03ad:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02b4:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03a9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03a9
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03a9
.L_tc_recycle_frame_done_03a9:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02b0:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03a7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03a7
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03a7
.L_tc_recycle_frame_done_03a7:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02af:	; new closure is in rax
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02b7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02b7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02b7
.L_lambda_simple_env_end_02b7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02b7:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02b7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02b7
.L_lambda_simple_params_end_02b7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02b7
	jmp .L_lambda_simple_end_02b7
.L_lambda_simple_code_02b7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02b7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02b7:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_75]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_74]	; free var char<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_134], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_68]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_67]	; free var char-ci<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_122], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_75]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_77]	; free var char>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_137], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_68]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_70]	; free var char-ci>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_125], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02b7:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02b8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02b8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02b8
.L_lambda_simple_env_end_02b8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02b8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02b8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02b8
.L_lambda_simple_params_end_02b8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02b8
	jmp .L_lambda_simple_end_02b8
.L_lambda_simple_code_02b8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02b8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02b8:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02b9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02b9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02b9
.L_lambda_simple_env_end_02b9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02b9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02b9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02b9
.L_lambda_simple_params_end_02b9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02b9
	jmp .L_lambda_simple_end_02b9
.L_lambda_simple_code_02b9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02b9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02b9:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02ba:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02ba
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02ba
.L_lambda_simple_env_end_02ba:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02ba:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02ba
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02ba
.L_lambda_simple_params_end_02ba:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02ba
	jmp .L_lambda_simple_end_02ba
.L_lambda_simple_code_02ba:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 4
	je .L_lambda_simple_arity_check_ok_02ba
	push qword [rsp + 8 * 2]
	push 4
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02ba:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param len
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0036
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param len
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0219
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(2)	; param str2
	push rax
	push 2
	mov rax, qword [free_var_129]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2
	mov rax, qword [free_var_129]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var char=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0218
	;debug: preparing a tail-call
	mov rax, PARAM(3)	; param len
	push rax
	mov rax, PARAM(2)	; param str2
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 4	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 4
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03b1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03b1
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03b1
.L_tc_recycle_frame_done_03b1:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0218
.L_if_else_0218:
	mov rax, L_constants + 2
.L_if_end_0218:
	jmp .L_if_end_0219
.L_if_else_0219:
	mov rax, L_constants + 2
.L_if_end_0219:
.L_or_end_0036:
	leave
	ret AND_KILL_FRAME(4)
.L_lambda_simple_end_02ba:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	;debug: preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02bb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02bb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02bb
.L_lambda_simple_env_end_02bb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02bb:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02bb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02bb
.L_lambda_simple_params_end_02bb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02bb
	jmp .L_lambda_simple_end_02bb
.L_lambda_simple_code_02bb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02bb
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02bb:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1
	mov rax, qword [free_var_128]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str1
	push rax
	push 1
	mov rax, qword [free_var_128]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02bc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_02bc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02bc
.L_lambda_simple_env_end_02bc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02bc:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_02bc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02bc
.L_lambda_simple_params_end_02bc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02bc
	jmp .L_lambda_simple_end_02bc
.L_lambda_simple_code_02bc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02bc
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02bc:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	push 2
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_021a
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, L_constants + 2135
	push rax
	push 4	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 4
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03b4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03b4
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03b4
.L_tc_recycle_frame_done_03b4:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_021a
.L_if_else_021a:
	mov rax, L_constants + 2
.L_if_end_021a:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02bc:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03b3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03b3
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03b3
.L_tc_recycle_frame_done_03b3:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02bb:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02bd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02bd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02bd
.L_lambda_simple_env_end_02bd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02bd:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02bd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02bd
.L_lambda_simple_params_end_02bd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02bd
	jmp .L_lambda_simple_end_02bd
.L_lambda_simple_code_02bd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02bd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02bd:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02be:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_02be
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02be
.L_lambda_simple_env_end_02be:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02be:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02be
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02be
.L_lambda_simple_params_end_02be:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02be
	jmp .L_lambda_simple_end_02be
.L_lambda_simple_code_02be:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02be
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02be:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02bf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_02bf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02bf
.L_lambda_simple_env_end_02bf:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02bf:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02bf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02bf
.L_lambda_simple_params_end_02bf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02bf
	jmp .L_lambda_simple_end_02bf
.L_lambda_simple_code_02bf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02bf
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02bf:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0037
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var binary-string=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_021b
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03b6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03b6
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03b6
.L_tc_recycle_frame_done_03b6:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_021b
.L_if_else_021b:
	mov rax, L_constants + 2
.L_if_end_021b:
.L_or_end_0037:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02bf:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	push rax
	mov rdi, 8 * 5
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_0064:
	cmp rsi, 4
	je .L_lambda_opt_env_end_0064
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0064
.L_lambda_opt_env_end_0064:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0064:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_0064
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0064
.L_lambda_opt_params_end_0064:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0064
	jmp .L_lambda_opt_end_0064
.L_lambda_opt_code_0064:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0064
	ja .L_lambda_opt_arity_check_more_0064
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0064:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_012b:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_012b
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_012b
.L_lambda_opt_stack_shrink_loop_exit_012b:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_012c:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_012c
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_012c
.L_lambda_opt_stack_shrink_loop_exit_012c:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0064
.L_lambda_opt_arity_check_exact_0064:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_012a:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_012a
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_012a
.L_lambda_opt_stack_shrink_loop_exit_012a:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0064:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03b7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03b7
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03b7
.L_tc_recycle_frame_done_03b7:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0064:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02be:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03b5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03b5
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03b5
.L_tc_recycle_frame_done_03b5:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02bd:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03b2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03b2
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03b2
.L_tc_recycle_frame_done_03b2:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02b9:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03b0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03b0
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03b0
.L_tc_recycle_frame_done_03b0:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02b8:	; new closure is in rax
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02c0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02c0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02c0
.L_lambda_simple_env_end_02c0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02c0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02c0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02c0
.L_lambda_simple_params_end_02c0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02c0
	jmp .L_lambda_simple_end_02c0
.L_lambda_simple_code_02c0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02c0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02c0:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_75]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-string=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_136], rax
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_68]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-string=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_124], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02c0:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02c1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02c1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02c1
.L_lambda_simple_env_end_02c1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02c1:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02c1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02c1
.L_lambda_simple_params_end_02c1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02c1
	jmp .L_lambda_simple_end_02c1
.L_lambda_simple_code_02c1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02c1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02c1:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0038
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1
	mov rax, qword [free_var_112]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_021c
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var list?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03b8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03b8
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03b8
.L_tc_recycle_frame_done_03b8:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_021c
.L_if_else_021c:
	mov rax, L_constants + 2
.L_if_end_021c:
.L_or_end_0038:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02c1:	; new closure is in rax
	mov qword [free_var_97], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, qword [free_var_102]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02c2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02c2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02c2
.L_lambda_simple_env_end_02c2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02c2:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02c2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02c2
.L_lambda_simple_params_end_02c2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02c2
	jmp .L_lambda_simple_end_02c2
.L_lambda_simple_code_02c2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02c2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02c2:
	enter 0, 0
	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_0065:
	cmp rsi, 1
	je .L_lambda_opt_env_end_0065
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0065
.L_lambda_opt_env_end_0065:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0065:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_0065
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0065
.L_lambda_opt_params_end_0065:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0065
	jmp .L_lambda_opt_end_0065
.L_lambda_opt_code_0065:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0065
	ja .L_lambda_opt_arity_check_more_0065
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0065:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_012e:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_012e
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_012e
.L_lambda_opt_stack_shrink_loop_exit_012e:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_012f:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_012f
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_012f
.L_lambda_opt_stack_shrink_loop_exit_012f:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0065
.L_lambda_opt_arity_check_exact_0065:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_012d:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_012d
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_012d
.L_lambda_opt_stack_shrink_loop_exit_012d:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0065:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_021f
	mov rax, L_constants + 0
	jmp .L_if_end_021f
.L_if_else_021f:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1
	mov rax, qword [free_var_112]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_021d
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_021d
.L_if_else_021d:
	mov rax, L_constants + 2
.L_if_end_021d:
	cmp rax, sob_boolean_false
	je .L_if_else_021e
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_021e
.L_if_else_021e:
	; preparing a non-tail-call
	mov rax, L_constants + 2955
	push rax
	mov rax, L_constants + 2946
	push rax
	push 2
	mov rax, qword [free_var_83]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
.L_if_end_021e:
.L_if_end_021f:
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02c3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02c3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02c3
.L_lambda_simple_env_end_02c3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02c3:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_02c3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02c3
.L_lambda_simple_params_end_02c3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02c3
	jmp .L_lambda_simple_end_02c3
.L_lambda_simple_code_02c3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02c3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02c3:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var asm-make-vector
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03ba:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03ba
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03ba
.L_tc_recycle_frame_done_03ba:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02c3:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03b9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03b9
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03b9
.L_tc_recycle_frame_done_03b9:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0065:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02c2:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_102], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, qword [free_var_100]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02c4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02c4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02c4
.L_lambda_simple_env_end_02c4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02c4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02c4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02c4
.L_lambda_simple_params_end_02c4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02c4
	jmp .L_lambda_simple_end_02c4
.L_lambda_simple_code_02c4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02c4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02c4:
	enter 0, 0
	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_0066:
	cmp rsi, 1
	je .L_lambda_opt_env_end_0066
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0066
.L_lambda_opt_env_end_0066:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0066:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_0066
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0066
.L_lambda_opt_params_end_0066:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0066
	jmp .L_lambda_opt_end_0066
.L_lambda_opt_code_0066:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0066
	ja .L_lambda_opt_arity_check_more_0066
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0066:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0131:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0131
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0131
.L_lambda_opt_stack_shrink_loop_exit_0131:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_0132:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0132
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0132
.L_lambda_opt_stack_shrink_loop_exit_0132:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0066
.L_lambda_opt_arity_check_exact_0066:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0130:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0130
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0130
.L_lambda_opt_stack_shrink_loop_exit_0130:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0066:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0222
	mov rax, L_constants + 4
	jmp .L_if_end_0222
.L_if_else_0222:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1
	mov rax, qword [free_var_112]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0220
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0220
.L_if_else_0220:
	mov rax, L_constants + 2
.L_if_end_0220:
	cmp rax, sob_boolean_false
	je .L_if_else_0221
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0221
.L_if_else_0221:
	; preparing a non-tail-call
	mov rax, L_constants + 3016
	push rax
	mov rax, L_constants + 3007
	push rax
	push 2
	mov rax, qword [free_var_83]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
.L_if_end_0221:
.L_if_end_0222:
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02c5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02c5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02c5
.L_lambda_simple_env_end_02c5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02c5:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_02c5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02c5
.L_lambda_simple_params_end_02c5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02c5
	jmp .L_lambda_simple_end_02c5
.L_lambda_simple_code_02c5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02c5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02c5:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var asm-make-string
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03bc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03bc
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03bc
.L_tc_recycle_frame_done_03bc:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02c5:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03bb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03bb
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03bb
.L_tc_recycle_frame_done_03bb:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0066:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02c4:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_100], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02c6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02c6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02c6
.L_lambda_simple_env_end_02c6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02c6:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02c6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02c6
.L_lambda_simple_params_end_02c6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02c6
	jmp .L_lambda_simple_end_02c6
.L_lambda_simple_code_02c6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02c6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02c6:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02c7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02c7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02c7
.L_lambda_simple_env_end_02c7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02c7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02c7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02c7
.L_lambda_simple_params_end_02c7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02c7
	jmp .L_lambda_simple_end_02c7
.L_lambda_simple_code_02c7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02c7
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02c7:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0223
	;debug: preparing a tail-call
	mov rax, L_constants + 0
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_102]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03bd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03bd
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03bd
.L_tc_recycle_frame_done_03bd:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0223
.L_if_else_0223:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02c8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02c8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02c8
.L_lambda_simple_env_end_02c8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02c8:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_02c8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02c8
.L_lambda_simple_params_end_02c8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02c8
	jmp .L_lambda_simple_end_02c8
.L_lambda_simple_code_02c8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02c8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02c8:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3
	mov rax, qword [free_var_148]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param v
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02c8:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03be:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03be
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03be
.L_tc_recycle_frame_done_03be:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0223:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02c7:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02c9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02c9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02c9
.L_lambda_simple_env_end_02c9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02c9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02c9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02c9
.L_lambda_simple_params_end_02c9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02c9
	jmp .L_lambda_simple_end_02c9
.L_lambda_simple_code_02c9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02c9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02c9:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03bf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03bf
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03bf
.L_tc_recycle_frame_done_03bf:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02c9:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02c6:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_96], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02ca:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02ca
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02ca
.L_lambda_simple_env_end_02ca:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02ca:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02ca
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02ca
.L_lambda_simple_params_end_02ca:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02ca
	jmp .L_lambda_simple_end_02ca
.L_lambda_simple_code_02ca:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02ca
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02ca:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02cb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02cb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02cb
.L_lambda_simple_env_end_02cb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02cb:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02cb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02cb
.L_lambda_simple_params_end_02cb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02cb
	jmp .L_lambda_simple_end_02cb
.L_lambda_simple_code_02cb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02cb
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02cb:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0224
	;debug: preparing a tail-call
	mov rax, L_constants + 4
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_100]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03c0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03c0
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03c0
.L_tc_recycle_frame_done_03c0:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0224
.L_if_else_0224:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02cc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02cc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02cc
.L_lambda_simple_env_end_02cc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02cc:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_02cc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02cc
.L_lambda_simple_params_end_02cc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02cc
	jmp .L_lambda_simple_end_02cc
.L_lambda_simple_code_02cc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02cc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02cc:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3
	mov rax, qword [free_var_132]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param str
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02cc:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03c1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03c1
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03c1
.L_tc_recycle_frame_done_03c1:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0224:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02cb:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02cd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02cd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02cd
.L_lambda_simple_env_end_02cd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02cd:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02cd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02cd
.L_lambda_simple_params_end_02cd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02cd
	jmp .L_lambda_simple_end_02cd
.L_lambda_simple_code_02cd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02cd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02cd:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03c2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03c2
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03c2
.L_tc_recycle_frame_done_03c2:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02cd:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02ca:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_95], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 0
	call malloc
	push rax
	mov rdi, 8 * 1
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_0067:
	cmp rsi, 0
	je .L_lambda_opt_env_end_0067
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0067
.L_lambda_opt_env_end_0067:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0067:	; copying parameters
	cmp rsi, 0
	je .L_lambda_opt_params_end_0067
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0067
.L_lambda_opt_params_end_0067:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0067
	jmp .L_lambda_opt_end_0067
.L_lambda_opt_code_0067:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_0067
	ja .L_lambda_opt_arity_check_more_0067
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0067:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0134:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0134
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0134
.L_lambda_opt_stack_shrink_loop_exit_0134:
	lea r10, [rsp + 8 * 0 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_0135:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0135
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0135
.L_lambda_opt_stack_shrink_loop_exit_0135:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0067
.L_lambda_opt_arity_check_exact_0067:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0133:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0133
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0133
.L_lambda_opt_stack_shrink_loop_exit_0133:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0067:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_96]	; free var list->vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03c3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03c3
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03c3
.L_tc_recycle_frame_done_03c3:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_0067:
	mov qword [free_var_141], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02ce:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02ce
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02ce
.L_lambda_simple_env_end_02ce:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02ce:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02ce
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02ce
.L_lambda_simple_params_end_02ce:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02ce
	jmp .L_lambda_simple_end_02ce
.L_lambda_simple_code_02ce:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02ce
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02ce:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02cf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02cf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02cf
.L_lambda_simple_env_end_02cf:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02cf:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02cf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02cf
.L_lambda_simple_params_end_02cf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02cf
	jmp .L_lambda_simple_end_02cf
.L_lambda_simple_code_02cf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_02cf
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02cf:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0225
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2
	mov rax, qword [free_var_129]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03c4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03c4
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03c4
.L_tc_recycle_frame_done_03c4:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0225
.L_if_else_0225:
	mov rax, L_constants + 1
.L_if_end_0225:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_02cf:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02d0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02d0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02d0
.L_lambda_simple_env_end_02d0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02d0:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02d0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02d0
.L_lambda_simple_params_end_02d0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02d0
	jmp .L_lambda_simple_end_02d0
.L_lambda_simple_code_02d0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02d0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02d0:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1
	mov rax, qword [free_var_128]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2135
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03c5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03c5
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03c5
.L_tc_recycle_frame_done_03c5:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02d0:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02ce:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_120], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02d1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02d1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02d1
.L_lambda_simple_env_end_02d1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02d1:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02d1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02d1
.L_lambda_simple_params_end_02d1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02d1
	jmp .L_lambda_simple_end_02d1
.L_lambda_simple_code_02d1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02d1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02d1:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02d2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02d2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02d2
.L_lambda_simple_env_end_02d2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02d2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02d2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02d2
.L_lambda_simple_params_end_02d2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02d2
	jmp .L_lambda_simple_end_02d2
.L_lambda_simple_code_02d2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_02d2
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02d2:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0226
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 2
	mov rax, qword [free_var_145]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03c6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03c6
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03c6
.L_tc_recycle_frame_done_03c6:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0226
.L_if_else_0226:
	mov rax, L_constants + 1
.L_if_end_0226:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_02d2:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02d3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02d3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02d3
.L_lambda_simple_env_end_02d3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02d3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02d3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02d3
.L_lambda_simple_params_end_02d3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02d3
	jmp .L_lambda_simple_end_02d3
.L_lambda_simple_code_02d3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02d3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02d3:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param v
	push rax
	push 1
	mov rax, qword [free_var_144]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2135
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03c7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03c7
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03c7
.L_tc_recycle_frame_done_03c7:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02d3:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02d1:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_142], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02d4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02d4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02d4
.L_lambda_simple_env_end_02d4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02d4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02d4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02d4
.L_lambda_simple_params_end_02d4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02d4
	jmp .L_lambda_simple_end_02d4
.L_lambda_simple_code_02d4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02d4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02d4:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param n
	push rax
	; preparing a non-tail-call
	push 0
	mov rax, qword [free_var_140]	; free var trng
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_118]	; free var remainder
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03c8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03c8
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03c8
.L_tc_recycle_frame_done_03c8:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02d4:	; new closure is in rax
	mov qword [free_var_114], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02d5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02d5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02d5
.L_lambda_simple_env_end_02d5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02d5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02d5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02d5
.L_lambda_simple_params_end_02d5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02d5
	jmp .L_lambda_simple_end_02d5
.L_lambda_simple_code_02d5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02d5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02d5:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	mov rax, L_constants + 2135
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03c9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03c9
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03c9
.L_tc_recycle_frame_done_03c9:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02d5:	; new closure is in rax
	mov qword [free_var_113], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02d6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02d6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02d6
.L_lambda_simple_env_end_02d6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02d6:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02d6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02d6
.L_lambda_simple_params_end_02d6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02d6
	jmp .L_lambda_simple_end_02d6
.L_lambda_simple_code_02d6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02d6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02d6:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	mov rax, PARAM(0)	; param x
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03ca:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03ca
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03ca
.L_tc_recycle_frame_done_03ca:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02d6:	; new closure is in rax
	mov qword [free_var_105], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02d7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02d7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02d7
.L_lambda_simple_env_end_02d7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02d7:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02d7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02d7
.L_lambda_simple_params_end_02d7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02d7
	jmp .L_lambda_simple_end_02d7
.L_lambda_simple_code_02d7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02d7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02d7:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 3190
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2
	mov rax, qword [free_var_118]	; free var remainder
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_153]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03cb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03cb
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03cb
.L_tc_recycle_frame_done_03cb:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02d7:	; new closure is in rax
	mov qword [free_var_84], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02d8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02d8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02d8
.L_lambda_simple_env_end_02d8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02d8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02d8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02d8
.L_lambda_simple_params_end_02d8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02d8
	jmp .L_lambda_simple_end_02d8
.L_lambda_simple_code_02d8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02d8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02d8:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1
	mov rax, qword [free_var_84]	; free var even?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03cc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03cc
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03cc
.L_tc_recycle_frame_done_03cc:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02d8:	; new closure is in rax
	mov qword [free_var_110], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02d9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02d9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02d9
.L_lambda_simple_env_end_02d9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02d9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02d9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02d9
.L_lambda_simple_params_end_02d9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02d9
	jmp .L_lambda_simple_end_02d9
.L_lambda_simple_code_02d9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02d9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02d9:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_105]	; free var negative?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0227
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03cd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03cd
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03cd
.L_tc_recycle_frame_done_03cd:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0227
.L_if_else_0227:
	mov rax, PARAM(0)	; param x
.L_if_end_0227:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02d9:	; new closure is in rax
	mov qword [free_var_30], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02da:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02da
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02da
.L_lambda_simple_env_end_02da:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02da:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02da
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02da
.L_lambda_simple_params_end_02da:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02da
	jmp .L_lambda_simple_end_02da
.L_lambda_simple_code_02da:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02da
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02da:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_112]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0228
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_112]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0228
.L_if_else_0228:
	mov rax, L_constants + 2
.L_if_end_0228:
	cmp rax, sob_boolean_false
	je .L_if_else_0234
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_82]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0229
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_82]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03ce:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03ce
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03ce
.L_tc_recycle_frame_done_03ce:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0229
.L_if_else_0229:
	mov rax, L_constants + 2
.L_if_end_0229:
	jmp .L_if_end_0234
.L_if_else_0234:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_149]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_022b
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_149]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_022a
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_144]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_144]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_022a
.L_if_else_022a:
	mov rax, L_constants + 2
.L_if_end_022a:
	jmp .L_if_end_022b
.L_if_else_022b:
	mov rax, L_constants + 2
.L_if_end_022b:
	cmp rax, sob_boolean_false
	je .L_if_else_0233
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_142]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_142]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_82]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03cf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03cf
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03cf
.L_tc_recycle_frame_done_03cf:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0233
.L_if_else_0233:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_139]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_022d
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_139]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_022c
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_128]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_128]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_022c
.L_if_else_022c:
	mov rax, L_constants + 2
.L_if_end_022c:
	jmp .L_if_end_022d
.L_if_else_022d:
	mov rax, L_constants + 2
.L_if_end_022d:
	cmp rax, sob_boolean_false
	je .L_if_else_0232
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_136]	; free var string=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03d0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03d0
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03d0
.L_tc_recycle_frame_done_03d0:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0232
.L_if_else_0232:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_109]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_022e
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_109]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_022e
.L_if_else_022e:
	mov rax, L_constants + 2
.L_if_end_022e:
	cmp rax, sob_boolean_false
	je .L_if_else_0231
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03d1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03d1
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03d1
.L_tc_recycle_frame_done_03d1:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0231
.L_if_else_0231:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_78]	; free var char?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_022f
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_78]	; free var char?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_022f
.L_if_else_022f:
	mov rax, L_constants + 2
.L_if_end_022f:
	cmp rax, sob_boolean_false
	je .L_if_else_0230
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_75]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03d2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03d2
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03d2
.L_tc_recycle_frame_done_03d2:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0230
.L_if_else_0230:
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_81]	; free var eq?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03d3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03d3
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03d3
.L_tc_recycle_frame_done_03d3:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0230:
.L_if_end_0231:
.L_if_end_0232:
.L_if_end_0233:
.L_if_end_0234:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02da:	; new closure is in rax
	mov qword [free_var_82], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02db:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02db
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02db
.L_lambda_simple_env_end_02db:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02db:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02db
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02db
.L_lambda_simple_params_end_02db:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02db
	jmp .L_lambda_simple_end_02db
.L_lambda_simple_code_02db:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02db
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02db:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0236
	mov rax, L_constants + 2
	jmp .L_if_end_0236
.L_if_else_0236:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_81]	; free var eq?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0235
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03d4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03d4
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03d4
.L_tc_recycle_frame_done_03d4:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0235
.L_if_else_0235:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_34]	; free var assoc
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03d5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03d5
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03d5
.L_tc_recycle_frame_done_03d5:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0235:
.L_if_end_0236:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02db:	; new closure is in rax
	mov qword [free_var_34], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02dc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02dc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02dc
.L_lambda_simple_env_end_02dc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02dc:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02dc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02dc
.L_lambda_simple_params_end_02dc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02dc
	jmp .L_lambda_simple_end_02dc
.L_lambda_simple_code_02dc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02dc
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02dc:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(1)
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02dd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02dd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02dd
.L_lambda_simple_env_end_02dd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02dd:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_02dd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02dd
.L_lambda_simple_params_end_02dd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02dd
	jmp .L_lambda_simple_end_02dd
.L_lambda_simple_code_02dd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_02dd
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02dd:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0237
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_0237
.L_if_else_0237:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_128]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2135
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02de:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02de
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02de
.L_lambda_simple_env_end_02de:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02de:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_02de
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02de
.L_lambda_simple_params_end_02de:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02de
	jmp .L_lambda_simple_end_02de
.L_lambda_simple_code_02de:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02de
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02de:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var target
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03d7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03d7
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03d7
.L_tc_recycle_frame_done_03d7:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02de:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03d6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03d6
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03d6
.L_tc_recycle_frame_done_03d6:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0237:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_02dd:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02df:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02df
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02df
.L_lambda_simple_env_end_02df:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02df:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_02df
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02df
.L_lambda_simple_params_end_02df:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02df
	jmp .L_lambda_simple_end_02df
.L_lambda_simple_code_02df:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_02df
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02df:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0238
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param str
	push rax
	push 2
	mov rax, qword [free_var_129]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 3
	mov rax, qword [free_var_132]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	;debug: preparing a tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(2)	; param str
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 5
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03d8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03d8
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03d8
.L_tc_recycle_frame_done_03d8:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0238
.L_if_else_0238:
	mov rax, PARAM(1)	; param i
.L_if_end_0238:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_02df:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param add
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_0068:
	cmp rsi, 1
	je .L_lambda_opt_env_end_0068
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0068
.L_lambda_opt_env_end_0068:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0068:	; copying parameters
	cmp rsi, 2
	je .L_lambda_opt_params_end_0068
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0068
.L_lambda_opt_params_end_0068:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0068
	jmp .L_lambda_opt_end_0068
.L_lambda_opt_code_0068:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_0068
	ja .L_lambda_opt_arity_check_more_0068
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0068:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0137:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0137
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0137
.L_lambda_opt_stack_shrink_loop_exit_0137:
	lea r10, [rsp + 8 * 0 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_0138:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0138
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0138
.L_lambda_opt_stack_shrink_loop_exit_0138:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0068
.L_lambda_opt_arity_check_exact_0068:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0136:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0136
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0136
.L_lambda_opt_stack_shrink_loop_exit_0136:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0068:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param strings
	push rax
	mov rax, L_constants + 2135
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param strings
	push rax
	mov rax, qword [free_var_128]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_104]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_100]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03d9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03d9
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03d9
.L_tc_recycle_frame_done_03d9:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_0068:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02dc:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_121], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02e0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02e0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02e0
.L_lambda_simple_env_end_02e0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02e0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02e0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02e0
.L_lambda_simple_params_end_02e0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02e0
	jmp .L_lambda_simple_end_02e0
.L_lambda_simple_code_02e0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02e0
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02e0:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(1)
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02e1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02e1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02e1
.L_lambda_simple_env_end_02e1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02e1:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_02e1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02e1
.L_lambda_simple_params_end_02e1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02e1
	jmp .L_lambda_simple_end_02e1
.L_lambda_simple_code_02e1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_02e1
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02e1:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0239
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_0239
.L_if_else_0239:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_144]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2135
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02e2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02e2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02e2
.L_lambda_simple_env_end_02e2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02e2:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_02e2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02e2
.L_lambda_simple_params_end_02e2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02e2
	jmp .L_lambda_simple_end_02e2
.L_lambda_simple_code_02e2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02e2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02e2:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var target
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03db:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03db
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03db
.L_tc_recycle_frame_done_03db:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02e2:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03da:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03da
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03da
.L_tc_recycle_frame_done_03da:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0239:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_02e1:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02e3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02e3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02e3
.L_lambda_simple_env_end_02e3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02e3:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_02e3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02e3
.L_lambda_simple_params_end_02e3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02e3
	jmp .L_lambda_simple_end_02e3
.L_lambda_simple_code_02e3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_02e3
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02e3:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_023a
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	push 2
	mov rax, qword [free_var_145]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 3
	mov rax, qword [free_var_148]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	;debug: preparing a tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 5
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03dc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03dc
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03dc
.L_tc_recycle_frame_done_03dc:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_023a
.L_if_else_023a:
	mov rax, PARAM(1)	; param i
.L_if_end_023a:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_02e3:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param add
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_0069:
	cmp rsi, 1
	je .L_lambda_opt_env_end_0069
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0069
.L_lambda_opt_env_end_0069:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0069:	; copying parameters
	cmp rsi, 2
	je .L_lambda_opt_params_end_0069
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0069
.L_lambda_opt_params_end_0069:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0069
	jmp .L_lambda_opt_end_0069
.L_lambda_opt_code_0069:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_0069
	ja .L_lambda_opt_arity_check_more_0069
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0069:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_013a:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_013a
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_013a
.L_lambda_opt_stack_shrink_loop_exit_013a:
	lea r10, [rsp + 8 * 0 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_013b:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_013b
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_013b
.L_lambda_opt_stack_shrink_loop_exit_013b:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0069
.L_lambda_opt_arity_check_exact_0069:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0139:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0139
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0139
.L_lambda_opt_stack_shrink_loop_exit_0139:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0069:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param vectors
	push rax
	mov rax, L_constants + 2135
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param vectors
	push rax
	mov rax, qword [free_var_144]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_104]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_102]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03dd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03dd
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03dd
.L_tc_recycle_frame_done_03dd:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_0069:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02e0:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_143], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02e4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02e4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02e4
.L_lambda_simple_env_end_02e4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02e4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02e4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02e4
.L_lambda_simple_params_end_02e4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02e4
	jmp .L_lambda_simple_end_02e4
.L_lambda_simple_code_02e4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02e4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02e4:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1
	mov rax, qword [free_var_120]	; free var string->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_119]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_95]	; free var list->string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03de:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03de
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03de
.L_tc_recycle_frame_done_03de:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02e4:	; new closure is in rax
	mov qword [free_var_130], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02e5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02e5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02e5
.L_lambda_simple_env_end_02e5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02e5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02e5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02e5
.L_lambda_simple_params_end_02e5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02e5
	jmp .L_lambda_simple_end_02e5
.L_lambda_simple_code_02e5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02e5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02e5:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param vec
	push rax
	push 1
	mov rax, qword [free_var_142]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_119]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_96]	; free var list->vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03df:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03df
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03df
.L_tc_recycle_frame_done_03df:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02e5:	; new closure is in rax
	mov qword [free_var_146], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02e6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02e6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02e6
.L_lambda_simple_env_end_02e6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02e6:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02e6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02e6
.L_lambda_simple_params_end_02e6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02e6
	jmp .L_lambda_simple_end_02e6
.L_lambda_simple_code_02e6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02e6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02e6:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02e7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02e7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02e7
.L_lambda_simple_env_end_02e7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02e7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02e7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02e7
.L_lambda_simple_params_end_02e7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02e7
	jmp .L_lambda_simple_end_02e7
.L_lambda_simple_code_02e7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_02e7
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02e7:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param j
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_023b
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2
	mov rax, qword [free_var_129]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02e8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02e8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02e8
.L_lambda_simple_env_end_02e8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02e8:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_02e8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02e8
.L_lambda_simple_params_end_02e8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02e8
	jmp .L_lambda_simple_end_02e8
.L_lambda_simple_code_02e8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02e8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02e8:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 2
	mov rax, qword [free_var_129]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3
	mov rax, qword [free_var_132]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a non-tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3
	mov rax, qword [free_var_132]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03e1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03e1
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03e1
.L_tc_recycle_frame_done_03e1:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02e8:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03e0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03e0
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03e0
.L_tc_recycle_frame_done_03e0:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_023b
.L_if_else_023b:
	mov rax, PARAM(0)	; param str
.L_if_end_023b:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_02e7:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02e9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02e9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02e9
.L_lambda_simple_env_end_02e9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02e9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02e9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02e9
.L_lambda_simple_params_end_02e9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02e9
	jmp .L_lambda_simple_end_02e9
.L_lambda_simple_code_02e9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02e9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02e9:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1
	mov rax, qword [free_var_128]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02ea:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02ea
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02ea
.L_lambda_simple_env_end_02ea:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02ea:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02ea
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02ea
.L_lambda_simple_params_end_02ea:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02ea
	jmp .L_lambda_simple_end_02ea
.L_lambda_simple_code_02ea:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02ea
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02ea:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1
	mov rax, qword [free_var_153]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_023c
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	jmp .L_if_end_023c
.L_if_else_023c:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2135
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03e3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03e3
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03e3
.L_tc_recycle_frame_done_03e3:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_023c:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02ea:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03e2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03e2
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03e2
.L_tc_recycle_frame_done_03e2:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02e9:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02e6:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_131], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02eb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02eb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02eb
.L_lambda_simple_env_end_02eb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02eb:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02eb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02eb
.L_lambda_simple_params_end_02eb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02eb
	jmp .L_lambda_simple_end_02eb
.L_lambda_simple_code_02eb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02eb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02eb:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02ec:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02ec
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02ec
.L_lambda_simple_env_end_02ec:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02ec:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02ec
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02ec
.L_lambda_simple_params_end_02ec:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02ec
	jmp .L_lambda_simple_end_02ec
.L_lambda_simple_code_02ec:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_02ec
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02ec:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param j
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_023d
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param vec
	push rax
	push 2
	mov rax, qword [free_var_145]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02ed:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02ed
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02ed
.L_lambda_simple_env_end_02ed:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02ed:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_02ed
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02ed
.L_lambda_simple_params_end_02ed:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02ed
	jmp .L_lambda_simple_end_02ed
.L_lambda_simple_code_02ed:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02ed
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02ed:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 2
	mov rax, qword [free_var_145]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3
	mov rax, qword [free_var_148]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a non-tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3
	mov rax, qword [free_var_148]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03e5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03e5
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03e5
.L_tc_recycle_frame_done_03e5:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02ed:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03e4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03e4
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03e4
.L_tc_recycle_frame_done_03e4:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_023d
.L_if_else_023d:
	mov rax, PARAM(0)	; param vec
.L_if_end_023d:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_02ec:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02ee:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02ee
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02ee
.L_lambda_simple_env_end_02ee:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02ee:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02ee
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02ee
.L_lambda_simple_params_end_02ee:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02ee
	jmp .L_lambda_simple_end_02ee
.L_lambda_simple_code_02ee:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02ee
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02ee:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param vec
	push rax
	push 1
	mov rax, qword [free_var_144]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02ef:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02ef
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02ef
.L_lambda_simple_env_end_02ef:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02ef:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02ef
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02ef
.L_lambda_simple_params_end_02ef:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02ef
	jmp .L_lambda_simple_end_02ef
.L_lambda_simple_code_02ef:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02ef
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02ef:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1
	mov rax, qword [free_var_153]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_023e
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	jmp .L_if_end_023e
.L_if_else_023e:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2135
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03e7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03e7
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03e7
.L_tc_recycle_frame_done_03e7:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_023e:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02ef:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03e6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03e6
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03e6
.L_tc_recycle_frame_done_03e6:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02ee:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02eb:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_147], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02f0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02f0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02f0
.L_lambda_simple_env_end_02f0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02f0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02f0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02f0
.L_lambda_simple_params_end_02f0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02f0
	jmp .L_lambda_simple_end_02f0
.L_lambda_simple_code_02f0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02f0
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02f0:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02f1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02f1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02f1
.L_lambda_simple_env_end_02f1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02f1:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_02f1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02f1
.L_lambda_simple_params_end_02f1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02f1
	jmp .L_lambda_simple_end_02f1
.L_lambda_simple_code_02f1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02f1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02f1:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02f2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02f2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02f2
.L_lambda_simple_env_end_02f2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02f2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02f2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02f2
.L_lambda_simple_params_end_02f2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02f2
	jmp .L_lambda_simple_end_02f2
.L_lambda_simple_code_02f2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02f2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02f2:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_023f
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var thunk
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_79]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03e9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03e9
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03e9
.L_tc_recycle_frame_done_03e9:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_023f
.L_if_else_023f:
	mov rax, L_constants + 1
.L_if_end_023f:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02f2:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	;debug: preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03ea:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03ea
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03ea
.L_tc_recycle_frame_done_03ea:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02f1:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03e8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03e8
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03e8
.L_tc_recycle_frame_done_03e8:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02f0:	; new closure is in rax
	mov qword [free_var_99], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02f3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02f3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02f3
.L_lambda_simple_env_end_02f3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02f3:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02f3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02f3
.L_lambda_simple_params_end_02f3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02f3
	jmp .L_lambda_simple_end_02f3
.L_lambda_simple_code_02f3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02f3
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02f3:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1
	mov rax, qword [free_var_100]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02f4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02f4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02f4
.L_lambda_simple_env_end_02f4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02f4:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_02f4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02f4
.L_lambda_simple_params_end_02f4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02f4
	jmp .L_lambda_simple_end_02f4
.L_lambda_simple_code_02f4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02f4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02f4:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02f5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02f5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02f5
.L_lambda_simple_env_end_02f5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02f5:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02f5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02f5
.L_lambda_simple_params_end_02f5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02f5
	jmp .L_lambda_simple_end_02f5
.L_lambda_simple_code_02f5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02f5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02f5:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02f6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_02f6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02f6
.L_lambda_simple_env_end_02f6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02f6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02f6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02f6
.L_lambda_simple_params_end_02f6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02f6
	jmp .L_lambda_simple_end_02f6
.L_lambda_simple_code_02f6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02f6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02f6:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0240
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 1]	; bound var thunk
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3
	mov rax, qword [free_var_132]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03ed:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03ed
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03ed
.L_tc_recycle_frame_done_03ed:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0240
.L_if_else_0240:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
.L_if_end_0240:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02f6:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	;debug: preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03ee:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03ee
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03ee
.L_tc_recycle_frame_done_03ee:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02f5:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03ec:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03ec
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03ec
.L_tc_recycle_frame_done_03ec:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02f4:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03eb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03eb
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03eb
.L_tc_recycle_frame_done_03eb:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02f3:	; new closure is in rax
	mov qword [free_var_101], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02f7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02f7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02f7
.L_lambda_simple_env_end_02f7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02f7:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02f7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02f7
.L_lambda_simple_params_end_02f7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02f7
	jmp .L_lambda_simple_end_02f7
.L_lambda_simple_code_02f7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02f7
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02f7:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1
	mov rax, qword [free_var_102]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02f8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_02f8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02f8
.L_lambda_simple_env_end_02f8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02f8:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_02f8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02f8
.L_lambda_simple_params_end_02f8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02f8
	jmp .L_lambda_simple_end_02f8
.L_lambda_simple_code_02f8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02f8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02f8:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02f9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_02f9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02f9
.L_lambda_simple_env_end_02f9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02f9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02f9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02f9
.L_lambda_simple_params_end_02f9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02f9
	jmp .L_lambda_simple_end_02f9
.L_lambda_simple_code_02f9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02f9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02f9:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02fa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_02fa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02fa
.L_lambda_simple_env_end_02fa:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02fa:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_02fa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02fa
.L_lambda_simple_params_end_02fa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02fa
	jmp .L_lambda_simple_end_02fa
.L_lambda_simple_code_02fa:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_02fa
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02fa:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0241
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 1]	; bound var thunk
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3
	mov rax, qword [free_var_148]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03f1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03f1
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03f1
.L_tc_recycle_frame_done_03f1:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0241
.L_if_else_0241:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
.L_if_end_0241:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02fa:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	;debug: preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03f2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03f2
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03f2
.L_tc_recycle_frame_done_03f2:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02f9:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03f0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03f0
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03f0
.L_tc_recycle_frame_done_03f0:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_02f8:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03ef:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03ef
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03ef
.L_tc_recycle_frame_done_03ef:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02f7:	; new closure is in rax
	mov qword [free_var_103], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02fb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02fb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02fb
.L_lambda_simple_env_end_02fb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02fb:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02fb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02fb
.L_lambda_simple_params_end_02fb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02fb
	jmp .L_lambda_simple_end_02fb
.L_lambda_simple_code_02fb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_02fb
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02fb:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	push 1
	mov rax, qword [free_var_153]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0244
	mov rax, L_constants + 3485
	jmp .L_if_end_0244
.L_if_else_0244:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0243
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2
	mov rax, qword [free_var_3]	; free var /
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 3
	mov rax, qword [free_var_98]	; free var logarithm
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 3485
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03f3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03f3
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03f3
.L_tc_recycle_frame_done_03f3:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0243
.L_if_else_0243:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0242
	mov rax, L_constants + 3485
	jmp .L_if_end_0242
.L_if_else_0242:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(2)	; param n
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 3
	mov rax, qword [free_var_98]	; free var logarithm
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 3485
	push rax
	push 2	; arg count
	mov rax, qword [free_var_3]	; free var /
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03f4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03f4
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03f4
.L_tc_recycle_frame_done_03f4:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0242:
.L_if_end_0243:
.L_if_end_0244:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_02fb:	; new closure is in rax
	mov qword [free_var_98], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02fc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02fc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02fc
.L_lambda_simple_env_end_02fc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02fc:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02fc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02fc
.L_lambda_simple_params_end_02fc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02fc
	jmp .L_lambda_simple_end_02fc
.L_lambda_simple_code_02fc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_02fc
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02fc:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 3510
	push rax
	push 1	; arg count
	mov rax, qword [free_var_152]	; free var write-char
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03f5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03f5
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03f5
.L_tc_recycle_frame_done_03f5:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_02fc:	; new closure is in rax
	mov qword [free_var_106], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02fd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02fd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02fd
.L_lambda_simple_env_end_02fd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02fd:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02fd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02fd
.L_lambda_simple_params_end_02fd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02fd
	jmp .L_lambda_simple_end_02fd
.L_lambda_simple_code_02fd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_02fd
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02fd:
	enter 0, 0
	mov rax, L_constants + 0
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_02fd:	; new closure is in rax
	mov qword [free_var_150], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02fe:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02fe
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02fe
.L_lambda_simple_env_end_02fe:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02fe:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02fe
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02fe
.L_lambda_simple_params_end_02fe:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02fe
	jmp .L_lambda_simple_end_02fe
.L_lambda_simple_code_02fe:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_02fe
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02fe:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, PARAM(1)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03f6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03f6
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03f6
.L_tc_recycle_frame_done_03f6:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_02fe:	; new closure is in rax
	mov qword [free_var_151], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 4
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_02ff:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_02ff
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_02ff
.L_lambda_simple_env_end_02ff:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_02ff:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_02ff
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_02ff
.L_lambda_simple_params_end_02ff:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_02ff
	jmp .L_lambda_simple_end_02ff
.L_lambda_simple_code_02ff:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 4
	je .L_lambda_simple_arity_check_ok_02ff
	push qword [rsp + 8 * 2]
	push 4
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_02ff:
	enter 0, 0
	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(0)
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(1)
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(2)
	mov qword [rax], rbx
	mov PARAM(2), rax
	mov rax, sob_void

	mov rdi, 8*1
	call malloc
	mov rbx, PARAM(3)
	mov qword [rax], rbx
	mov PARAM(3), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 4	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0300:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0300
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0300
.L_lambda_simple_env_end_0300:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0300:	; copy params
	cmp rsi, 4
	je .L_lambda_simple_params_end_0300
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0300
.L_lambda_simple_params_end_0300:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0300
	jmp .L_lambda_simple_end_0300
.L_lambda_simple_code_0300:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0300
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0300:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_153]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0245
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_153]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0245
.L_if_else_0245:
	mov rax, L_constants + 2
.L_if_end_0245:
	cmp rax, sob_boolean_false
	je .L_if_else_024d
	;debug: preparing a tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(2)	; param c
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03f7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03f7
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03f7
.L_tc_recycle_frame_done_03f7:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_024d
.L_if_else_024d:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_153]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0246
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param c
	push rax
	push 1
	mov rax, qword [free_var_153]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0246
.L_if_else_0246:
	mov rax, L_constants + 2
.L_if_end_0246:
	cmp rax, sob_boolean_false
	je .L_if_else_024c
	;debug: preparing a tail-call
	mov rax, L_constants + 2270
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2135
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var ack-x
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03f8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03f8
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03f8
.L_tc_recycle_frame_done_03f8:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_024c
.L_if_else_024c:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_153]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_024b
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(2)	; param c
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, L_constants + 2135
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var ack-y
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2135
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 3]	; bound var ack-z
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03f9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03f9
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03f9
.L_tc_recycle_frame_done_03f9:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_024b
.L_if_else_024b:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_153]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0247
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param c
	push rax
	push 1
	mov rax, qword [free_var_153]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0247
.L_if_else_0247:
	mov rax, L_constants + 2
.L_if_end_0247:
	cmp rax, sob_boolean_false
	je .L_if_else_024a
	;debug: preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	mov rax, L_constants + 2270
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var ack-x
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03fa:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03fa
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03fa
.L_tc_recycle_frame_done_03fa:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_024a
.L_if_else_024a:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_153]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0249
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(2)	; param c
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2135
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var ack-y
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2270
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 3]	; bound var ack-z
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03fb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03fb
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03fb
.L_tc_recycle_frame_done_03fb:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0249
.L_if_else_0249:
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param c
	push rax
	push 1
	mov rax, qword [free_var_153]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0248
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var ack-y
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var ack-x
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03fc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03fc
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03fc
.L_tc_recycle_frame_done_03fc:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0248
.L_if_else_0248:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(2)	; param c
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var ack-x
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var ack-y
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 3]	; bound var ack-z
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03fd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03fd
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03fd
.L_tc_recycle_frame_done_03fd:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0248:
.L_if_end_0249:
.L_if_end_024a:
.L_if_end_024b:
.L_if_end_024c:
.L_if_end_024d:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0300:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param ack3
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 4
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_006a:
	cmp rsi, 1
	je .L_lambda_opt_env_end_006a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_006a
.L_lambda_opt_env_end_006a:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_006a:	; copying parameters
	cmp rsi, 4
	je .L_lambda_opt_params_end_006a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_006a
.L_lambda_opt_params_end_006a:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_006a
	jmp .L_lambda_opt_end_006a
.L_lambda_opt_code_006a:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_006a
	ja .L_lambda_opt_arity_check_more_006a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_006a:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_013d:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_013d
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_013d
.L_lambda_opt_stack_shrink_loop_exit_013d:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_013e:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_013e
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_013e
.L_lambda_opt_stack_shrink_loop_exit_013e:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_006a
.L_lambda_opt_arity_check_exact_006a:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_013c:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_013c
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_013c
.L_lambda_opt_stack_shrink_loop_exit_013c:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_006a:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	;debug: preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0301:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0301
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0301
.L_lambda_simple_env_end_0301:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0301:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0301
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0301
.L_lambda_simple_params_end_0301:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0301
	jmp .L_lambda_simple_end_0301
.L_lambda_simple_code_0301:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0301
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0301:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param c
	push rax
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var ack3
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03ff:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03ff
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03ff
.L_tc_recycle_frame_done_03ff:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0301:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param bcs
	push rax
	push 2	; arg count
	mov rax, qword [free_var_151]	; free var with
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_03fe:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_03fe
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_03fe
.L_tc_recycle_frame_done_03fe:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_006a:
	push rax
	mov rax, PARAM(1)	; param ack-x
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 4
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_006b:
	cmp rsi, 1
	je .L_lambda_opt_env_end_006b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_006b
.L_lambda_opt_env_end_006b:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_006b:	; copying parameters
	cmp rsi, 4
	je .L_lambda_opt_params_end_006b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_006b
.L_lambda_opt_params_end_006b:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_006b
	jmp .L_lambda_opt_end_006b
.L_lambda_opt_code_006b:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 3
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_arity_check_exact_006b
	ja .L_lambda_opt_arity_check_more_006b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_006b:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0140:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0140
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0140
.L_lambda_opt_stack_shrink_loop_exit_0140:
	lea r10, [rsp + 8 * 2 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 5
	mov rcx, 4 + 2
.L_lambda_opt_stack_shrink_loop_0141:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0141
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0141
.L_lambda_opt_stack_shrink_loop_exit_0141:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_006b
.L_lambda_opt_arity_check_exact_006b:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_013f:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_013f
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_013f
.L_lambda_opt_stack_shrink_loop_exit_013f:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_006b:
	mov qword [rsp + 8*2], 3
	enter 0, 0
	;debug: preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0302:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0302
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0302
.L_lambda_simple_env_end_0302:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0302:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_0302
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0302
.L_lambda_simple_params_end_0302:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0302
	jmp .L_lambda_simple_end_0302
.L_lambda_simple_code_0302:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0302
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0302:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param c
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var ack3
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0401:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0401
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0401
.L_tc_recycle_frame_done_0401:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0302:	; new closure is in rax
	push rax
	mov rax, PARAM(2)	; param cs
	push rax
	push 2	; arg count
	mov rax, qword [free_var_151]	; free var with
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0400:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0400
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0400
.L_tc_recycle_frame_done_0400:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 3)
.L_lambda_opt_end_006b:
	push rax
	mov rax, PARAM(2)	; param ack-y
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)
	call malloc
	push rax
	mov rdi, 8 * 4
	call malloc
	push rax
	mov rdi, 8 * 2
	call malloc
	mov rdi, qword [rbp + 8 * 2]
	mov rdx, 1
	mov rsi, 0
.L_lambda_opt_env_loop_006c:
	cmp rsi, 1
	je .L_lambda_opt_env_end_006c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_006c
.L_lambda_opt_env_end_006c:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_006c:	; copying parameters
	cmp rsi, 4
	je .L_lambda_opt_params_end_006c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_006c
.L_lambda_opt_params_end_006c:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_006c
	jmp .L_lambda_opt_end_006c
.L_lambda_opt_code_006c:	; body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_006c
	ja .L_lambda_opt_arity_check_more_006c
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_006c:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0143:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0143
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0143
.L_lambda_opt_stack_shrink_loop_exit_0143:
	lea r10, [rsp + 8 * 0 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_0144:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0144
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0144
.L_lambda_opt_stack_shrink_loop_exit_0144:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_006c
.L_lambda_opt_arity_check_exact_006c:
	mov r8, qword [rsp - 8 * 0]
	mov qword [rsp - 8 * 1], r8
	mov r8, qword [rsp + 8 * 1]
	mov qword [rsp + 8 * 0], r8
	mov r8, qword [rsp + 8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp + 8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0142:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0142
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0142
.L_lambda_opt_stack_shrink_loop_exit_0142:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_006c:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	;debug: preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0303:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0303
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0303
.L_lambda_simple_env_end_0303:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0303:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0303
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0303
.L_lambda_simple_params_end_0303:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0303
	jmp .L_lambda_simple_end_0303
.L_lambda_simple_code_0303:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0303
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0303:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(2)	; param c
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var ack3
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 3
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0403:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0403
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0403
.L_tc_recycle_frame_done_0403:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0303:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param abcs
	push rax
	push 2	; arg count
	mov rax, qword [free_var_151]	; free var with
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0402:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0402
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0402
.L_tc_recycle_frame_done_0402:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_006c:
	push rax
	mov rax, PARAM(3)	; param ack-z
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 4	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0304:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0304
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0304
.L_lambda_simple_env_end_0304:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0304:	; copy params
	cmp rsi, 4
	je .L_lambda_simple_params_end_0304
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0304
.L_lambda_simple_params_end_0304:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0304
	jmp .L_lambda_simple_end_0304
.L_lambda_simple_code_0304:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0304
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0304:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 3190
	push rax
	mov rax, L_constants + 3190
	push rax
	mov rax, L_constants + 2135
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var ack3
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 3556
	push rax
	push 2
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0250
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 3574
	push rax
	mov rax, L_constants + 3574
	push rax
	mov rax, L_constants + 2135
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var ack3
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 3565
	push rax
	push 2
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_024f
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 3592
	push rax
	mov rax, L_constants + 2270
	push rax
	mov rax, L_constants + 2270
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var ack3
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 3583
	push rax
	push 2
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_024e
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, L_constants + 2135
	push rax
	mov rax, L_constants + 3190
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var ack3
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 3601
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0404:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0404
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0404
.L_tc_recycle_frame_done_0404:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_024e
.L_if_else_024e:
	mov rax, L_constants + 2
.L_if_end_024e:
	jmp .L_if_end_024f
.L_if_else_024f:
	mov rax, L_constants + 2
.L_if_end_024f:
	jmp .L_if_end_0250
.L_if_else_0250:
	mov rax, L_constants + 2
.L_if_end_0250:
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0304:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(4)
.L_lambda_simple_end_02ff:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_80], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	push 0
	mov rax, qword [free_var_80]	; free var crazy-ack
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
Lend:
	mov rdi, rax
	call print_sexpr_if_not_void

        mov rdi, fmt_memory_usage
        mov rsi, qword [top_of_memory]
        sub rsi, memory
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, 0
        call exit

L_error_fvar_undefined:
        push rax
        mov rdi, qword [stderr]  ; destination
        mov rsi, fmt_undefined_free_var_1
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        pop rax
        mov rax, qword [rax + 1] ; string
        lea rdi, [rax + 1 + 8]   ; actual characters
        mov rsi, 1               ; sizeof(char)
        mov rdx, qword [rax + 1] ; string-length
        mov rcx, qword [stderr]  ; destination
        mov rax, 0
        ENTER
        call fwrite
        LEAVE
        mov rdi, [stderr]       ; destination
        mov rsi, fmt_undefined_free_var_2
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -10
        call exit

L_error_non_closure:
        mov rdi, qword [stderr]
        mov rsi, fmt_non_closure
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -2
        call exit

L_error_improper_list:
	mov rdi, qword [stderr]
	mov rsi, fmt_error_improper_list
	mov rax, 0
        ENTER
	call fprintf
        LEAVE
	mov rax, -7
	call exit

L_error_incorrect_arity_simple:
        mov rdi, qword [stderr]
        mov rsi, fmt_incorrect_arity_simple
        jmp L_error_incorrect_arity_common
L_error_incorrect_arity_opt:
        mov rdi, qword [stderr]
        mov rsi, fmt_incorrect_arity_opt
L_error_incorrect_arity_common:
        pop rdx
        pop rcx
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -6
        call exit

section .data
fmt_undefined_free_var_1:
        db `!!! The free variable \0`
fmt_undefined_free_var_2:
        db ` was used before it was defined.\n\0`
fmt_incorrect_arity_simple:
        db `!!! Expected %ld arguments, but given %ld\n\0`
fmt_incorrect_arity_opt:
        db `!!! Expected at least %ld arguments, but given %ld\n\0`
fmt_memory_usage:
        db `\n!!! Used %ld bytes of dynamically-allocated memory\n\n\0`
fmt_non_closure:
        db `!!! Attempting to apply a non-closure!\n\0`
fmt_error_improper_list:
	db `!!! The argument is not a proper list!\n\0`

section .bss

memory:
	resb gbytes(1)

section .data
top_of_memory:
        dq memory

section .text
malloc:
        mov rax, qword [top_of_memory]
        add qword [top_of_memory], rdi
        ret

L_code_ptr_return:
	cmp qword [rsp + 8*2], 2
	jne L_error_arg_count_2
	mov rcx, qword [rsp + 8*3]
	assert_integer(rcx)
	mov rcx, qword [rcx + 1]
	cmp rcx, 0
	jl L_error_integer_range
	mov rax, qword [rsp + 8*4]
.L0:
        cmp rcx, 0
        je .L1
	mov rbp, qword [rbp]
	dec rcx
	jg .L0
.L1:
	mov rsp, rbp
	pop rbp
        pop rbx
        mov rcx, qword [rsp + 8*1]
        lea rsp, [rsp + 8*rcx + 8*2]
	jmp rbx

L_code_ptr_make_list:
	enter 0, 0
        cmp COUNT, 1
        je .L0
        cmp COUNT, 2
        je .L1
        jmp L_error_arg_count_12
.L0:
        mov r9, sob_void
        jmp .L2
.L1:
        mov r9, PARAM(1)
.L2:
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_arg_negative
        mov r8, sob_nil
.L3:
        cmp rcx, 0
        jle .L4
        mov rdi, 1 + 8 + 8
        call malloc
        mov byte [rax], T_pair
        mov qword [rax + 1], r9
        mov qword [rax + 1 + 8], r8
        mov r8, rax
        dec rcx
        jmp .L3
.L4:
        mov rax, r8
        cmp COUNT, 2
        je .L5
        leave
        ret AND_KILL_FRAME(1)
.L5:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_is_primitive:
	enter 0, 0
	cmp COUNT, 1
	jne L_error_arg_count_1
	mov rax, PARAM(0)
	assert_closure(rax)
	cmp SOB_CLOSURE_ENV(rax), 0
	jne .L_false
	mov rax, sob_boolean_true
	jmp .L_end
.L_false:
	mov rax, sob_boolean_false
.L_end:
	leave
	ret AND_KILL_FRAME(1)

L_code_ptr_length:
	enter 0, 0
	cmp COUNT, 1
	jne L_error_arg_count_1
	mov rbx, PARAM(0)
	mov rdi, 0
.L:
	cmp byte [rbx], T_nil
	je .L_end
	assert_pair(rbx)
	mov rbx, SOB_PAIR_CDR(rbx)
	inc rdi
	jmp .L
.L_end:
	call make_integer
	leave
	ret AND_KILL_FRAME(1)

L_code_ptr_break:
        cmp qword [rsp + 8 * 2], 0
        jne L_error_arg_count_0
        int3
        mov rax, sob_void
        ret AND_KILL_FRAME(0)        

L_code_ptr_frame:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0

        mov rdi, fmt_frame
        mov rsi, qword [rbp]    ; old rbp
        mov rdx, qword [rsi + 8*1] ; ret addr
        mov rcx, qword [rsi + 8*2] ; lexical environment
        mov r8, qword [rsi + 8*3] ; count
        lea r9, [rsi + 8*4]       ; address of argument 0
        push 0
        push r9
        push r8                   ; we'll use it when printing the params
        mov rax, 0
        
        ENTER
        call printf
        LEAVE

.L:
        mov rcx, qword [rsp]
        cmp rcx, 0
        je .L_out
        mov rdi, fmt_frame_param_prefix
        mov rsi, qword [rsp + 8*2]
        mov rax, 0
        
        ENTER
        call printf
        LEAVE

        mov rcx, qword [rsp]
        dec rcx
        mov qword [rsp], rcx    ; dec arg count
        inc qword [rsp + 8*2]   ; increment index of current arg
        mov rdi, qword [rsp + 8*1] ; addr of addr current arg
        lea r9, [rdi + 8]          ; addr of next arg
        mov qword [rsp + 8*1], r9  ; backup addr of next arg
        mov rdi, qword [rdi]       ; addr of current arg
        call print_sexpr
        mov rdi, fmt_newline
        mov rax, 0
        ENTER
        call printf
        LEAVE
        jmp .L
.L_out:
        mov rdi, fmt_frame_continue
        mov rax, 0
        ENTER
        call printf
        call getchar
        LEAVE
        
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(0)
        
print_sexpr_if_not_void:
	cmp rdi, sob_void
	je .done
	call print_sexpr
	mov rdi, fmt_newline
	mov rax, 0
	ENTER
	call printf
	LEAVE
.done:
	ret

section .data
fmt_frame:
        db `RBP = %p; ret addr = %p; lex env = %p; param count = %d\n\0`
fmt_frame_param_prefix:
        db `==[param %d]==> \0`
fmt_frame_continue:
        db `Hit <Enter> to continue...\0`
fmt_newline:
	db `\n\0`
fmt_void:
	db `#<void>\0`
fmt_nil:
	db `()\0`
fmt_boolean_false:
	db `#f\0`
fmt_boolean_true:
	db `#t\0`
fmt_char_backslash:
	db `#\\\\\0`
fmt_char_dquote:
	db `#\\"\0`
fmt_char_simple:
	db `#\\%c\0`
fmt_char_null:
	db `#\\nul\0`
fmt_char_bell:
	db `#\\bell\0`
fmt_char_backspace:
	db `#\\backspace\0`
fmt_char_tab:
	db `#\\tab\0`
fmt_char_newline:
	db `#\\newline\0`
fmt_char_formfeed:
	db `#\\page\0`
fmt_char_return:
	db `#\\return\0`
fmt_char_escape:
	db `#\\esc\0`
fmt_char_space:
	db `#\\space\0`
fmt_char_hex:
	db `#\\x%02X\0`
fmt_gensym:
        db `G%ld\0`
fmt_closure:
	db `#<closure at 0x%08X env=0x%08X code=0x%08X>\0`
fmt_lparen:
	db `(\0`
fmt_dotted_pair:
	db ` . \0`
fmt_rparen:
	db `)\0`
fmt_space:
	db ` \0`
fmt_empty_vector:
	db `#()\0`
fmt_vector:
	db `#(\0`
fmt_real:
	db `%f\0`
fmt_fraction:
	db `%ld/%ld\0`
fmt_zero:
	db `0\0`
fmt_int:
	db `%ld\0`
fmt_unknown_scheme_object_error:
	db `\n\n!!! Error: Unknown Scheme-object (RTTI 0x%02X) `
	db `at address 0x%08X\n\n\0`
fmt_dquote:
	db `\"\0`
fmt_string_char:
        db `%c\0`
fmt_string_char_7:
        db `\\a\0`
fmt_string_char_8:
        db `\\b\0`
fmt_string_char_9:
        db `\\t\0`
fmt_string_char_10:
        db `\\n\0`
fmt_string_char_11:
        db `\\v\0`
fmt_string_char_12:
        db `\\f\0`
fmt_string_char_13:
        db `\\r\0`
fmt_string_char_34:
        db `\\"\0`
fmt_string_char_92:
        db `\\\\\0`
fmt_string_char_hex:
        db `\\x%X;\0`

section .text

print_sexpr:
	enter 0, 0
	mov al, byte [rdi]
	cmp al, T_void
	je .Lvoid
	cmp al, T_nil
	je .Lnil
	cmp al, T_boolean_false
	je .Lboolean_false
	cmp al, T_boolean_true
	je .Lboolean_true
	cmp al, T_char
	je .Lchar
	cmp al, T_interned_symbol
	je .Linterned_symbol
        cmp al, T_uninterned_symbol
        je .Luninterned_symbol
	cmp al, T_pair
	je .Lpair
	cmp al, T_vector
	je .Lvector
	cmp al, T_closure
	je .Lclosure
	cmp al, T_real
	je .Lreal
	cmp al, T_fraction
	je .Lfraction
	cmp al, T_integer
	je .Linteger
	cmp al, T_string
	je .Lstring

	jmp .Lunknown_sexpr_type

.Lvoid:
	mov rdi, fmt_void
	jmp .Lemit

.Lnil:
	mov rdi, fmt_nil
	jmp .Lemit

.Lboolean_false:
	mov rdi, fmt_boolean_false
	jmp .Lemit

.Lboolean_true:
	mov rdi, fmt_boolean_true
	jmp .Lemit

.Lchar:
	mov al, byte [rdi + 1]
	cmp al, ' '
	jle .Lchar_whitespace
	cmp al, 92 		; backslash
	je .Lchar_backslash
	cmp al, '"'
	je .Lchar_dquote
	and rax, 255
	mov rdi, fmt_char_simple
	mov rsi, rax
	jmp .Lemit

.Lchar_whitespace:
	cmp al, 0
	je .Lchar_null
	cmp al, 7
	je .Lchar_bell
	cmp al, 8
	je .Lchar_backspace
	cmp al, 9
	je .Lchar_tab
	cmp al, 10
	je .Lchar_newline
	cmp al, 12
	je .Lchar_formfeed
	cmp al, 13
	je .Lchar_return
	cmp al, 27
	je .Lchar_escape
	and rax, 255
	cmp al, ' '
	je .Lchar_space
	mov rdi, fmt_char_hex
	mov rsi, rax
	jmp .Lemit	

.Lchar_backslash:
	mov rdi, fmt_char_backslash
	jmp .Lemit

.Lchar_dquote:
	mov rdi, fmt_char_dquote
	jmp .Lemit

.Lchar_null:
	mov rdi, fmt_char_null
	jmp .Lemit

.Lchar_bell:
	mov rdi, fmt_char_bell
	jmp .Lemit

.Lchar_backspace:
	mov rdi, fmt_char_backspace
	jmp .Lemit

.Lchar_tab:
	mov rdi, fmt_char_tab
	jmp .Lemit

.Lchar_newline:
	mov rdi, fmt_char_newline
	jmp .Lemit

.Lchar_formfeed:
	mov rdi, fmt_char_formfeed
	jmp .Lemit

.Lchar_return:
	mov rdi, fmt_char_return
	jmp .Lemit

.Lchar_escape:
	mov rdi, fmt_char_escape
	jmp .Lemit

.Lchar_space:
	mov rdi, fmt_char_space
	jmp .Lemit

.Lclosure:
	mov rsi, qword rdi
	mov rdi, fmt_closure
	mov rdx, SOB_CLOSURE_ENV(rsi)
	mov rcx, SOB_CLOSURE_CODE(rsi)
	jmp .Lemit

.Linterned_symbol:
	mov rdi, qword [rdi + 1] ; sob_string
	mov rsi, 1		 ; size = 1 byte
	mov rdx, qword [rdi + 1] ; length
	lea rdi, [rdi + 1 + 8]	 ; actual characters
	mov rcx, qword [stdout]	 ; FILE *
	ENTER
	call fwrite
	LEAVE
	jmp .Lend

.Luninterned_symbol:
        mov rsi, qword [rdi + 1] ; gensym counter
        mov rdi, fmt_gensym
        jmp .Lemit
	
.Lpair:
	push rdi
	mov rdi, fmt_lparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp] 	; pair
	mov rdi, SOB_PAIR_CAR(rdi)
	call print_sexpr
	pop rdi 		; pair
	mov rdi, SOB_PAIR_CDR(rdi)
.Lcdr:
	mov al, byte [rdi]
	cmp al, T_nil
	je .Lcdr_nil
	cmp al, T_pair
	je .Lcdr_pair
	push rdi
	mov rdi, fmt_dotted_pair
	mov rax, 0
        ENTER
	call printf
        LEAVE
	pop rdi
	call print_sexpr
	mov rdi, fmt_rparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	leave
	ret

.Lcdr_nil:
	mov rdi, fmt_rparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	leave
	ret

.Lcdr_pair:
	push rdi
	mov rdi, fmt_space
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp]
	mov rdi, SOB_PAIR_CAR(rdi)
	call print_sexpr
	pop rdi
	mov rdi, SOB_PAIR_CDR(rdi)
	jmp .Lcdr

.Lvector:
	mov rax, qword [rdi + 1] ; length
	cmp rax, 0
	je .Lvector_empty
	push rdi
	mov rdi, fmt_vector
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp]
	push qword [rdi + 1]
	push 1
	mov rdi, qword [rdi + 1 + 8] ; v[0]
	call print_sexpr
.Lvector_loop:
	; [rsp] index
	; [rsp + 8*1] limit
	; [rsp + 8*2] vector
	mov rax, qword [rsp]
	cmp rax, qword [rsp + 8*1]
	je .Lvector_end
	mov rdi, fmt_space
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rax, qword [rsp]
	mov rbx, qword [rsp + 8*2]
	mov rdi, qword [rbx + 1 + 8 + 8 * rax] ; v[i]
	call print_sexpr
	inc qword [rsp]
	jmp .Lvector_loop

.Lvector_end:
	add rsp, 8*3
	mov rdi, fmt_rparen
	jmp .Lemit	

.Lvector_empty:
	mov rdi, fmt_empty_vector
	jmp .Lemit

.Lreal:
	push qword [rdi + 1]
	movsd xmm0, qword [rsp]
	add rsp, 8*1
	mov rdi, fmt_real
	mov rax, 1
	ENTER
	call printf
	LEAVE
	jmp .Lend

.Lfraction:
	mov rsi, qword [rdi + 1]
	mov rdx, qword [rdi + 1 + 8]
	cmp rsi, 0
	je .Lrat_zero
	cmp rdx, 1
	je .Lrat_int
	mov rdi, fmt_fraction
	jmp .Lemit

.Lrat_zero:
	mov rdi, fmt_zero
	jmp .Lemit

.Lrat_int:
	mov rdi, fmt_int
	jmp .Lemit

.Linteger:
	mov rsi, qword [rdi + 1]
	mov rdi, fmt_int
	jmp .Lemit

.Lstring:
	lea rax, [rdi + 1 + 8]
	push rax
	push qword [rdi + 1]
	mov rdi, fmt_dquote
	mov rax, 0
	ENTER
	call printf
	LEAVE
.Lstring_loop:
	; qword [rsp]: limit
	; qword [rsp + 8*1]: char *
	cmp qword [rsp], 0
	je .Lstring_end
	mov rax, qword [rsp + 8*1]
	mov al, byte [rax]
	and rax, 255
	cmp al, 7
        je .Lstring_char_7
        cmp al, 8
        je .Lstring_char_8
        cmp al, 9
        je .Lstring_char_9
        cmp al, 10
        je .Lstring_char_10
        cmp al, 11
        je .Lstring_char_11
        cmp al, 12
        je .Lstring_char_12
        cmp al, 13
        je .Lstring_char_13
        cmp al, 34
        je .Lstring_char_34
        cmp al, 92              ; \
        je .Lstring_char_92
        cmp al, ' '
        jl .Lstring_char_hex
        mov rdi, fmt_string_char
        mov rsi, rax
.Lstring_char_emit:
        mov rax, 0
        ENTER
        call printf
        LEAVE
        dec qword [rsp]
        inc qword [rsp + 8*1]
        jmp .Lstring_loop

.Lstring_char_7:
        mov rdi, fmt_string_char_7
        jmp .Lstring_char_emit

.Lstring_char_8:
        mov rdi, fmt_string_char_8
        jmp .Lstring_char_emit
        
.Lstring_char_9:
        mov rdi, fmt_string_char_9
        jmp .Lstring_char_emit

.Lstring_char_10:
        mov rdi, fmt_string_char_10
        jmp .Lstring_char_emit

.Lstring_char_11:
        mov rdi, fmt_string_char_11
        jmp .Lstring_char_emit

.Lstring_char_12:
        mov rdi, fmt_string_char_12
        jmp .Lstring_char_emit

.Lstring_char_13:
        mov rdi, fmt_string_char_13
        jmp .Lstring_char_emit

.Lstring_char_34:
        mov rdi, fmt_string_char_34
        jmp .Lstring_char_emit

.Lstring_char_92:
        mov rdi, fmt_string_char_92
        jmp .Lstring_char_emit

.Lstring_char_hex:
        mov rdi, fmt_string_char_hex
        mov rsi, rax
        jmp .Lstring_char_emit        

.Lstring_end:
	add rsp, 8 * 2
	mov rdi, fmt_dquote
	jmp .Lemit

.Lunknown_sexpr_type:
	mov rsi, fmt_unknown_scheme_object_error
	and rax, 255
	mov rdx, rax
	mov rcx, rdi
	mov rdi, qword [stderr]
	mov rax, 0
        ENTER
	call fprintf
        LEAVE
        leave
        ret

.Lemit:
	mov rax, 0
        ENTER
	call printf
        LEAVE
	jmp .Lend

.Lend:
	LEAVE
	ret

;;; rdi: address of free variable
;;; rsi: address of code-pointer
bind_primitive:
        enter 0, 0
        push rdi
        mov rdi, (1 + 8 + 8)
        call malloc
        pop rdi
        mov byte [rax], T_closure
        mov SOB_CLOSURE_ENV(rax), 0 ; dummy, lexical environment
        mov SOB_CLOSURE_CODE(rax), rsi ; code pointer
        mov qword [rdi], rax
        mov rax, sob_void
        leave
        ret

L_code_ptr_ash:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_integer(rdi)
        mov rcx, PARAM(1)
        assert_integer(rcx)
        mov rdi, qword [rdi + 1]
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl .L_negative
.L_loop_positive:
        cmp rcx, 0
        je .L_exit
        sal rdi, cl
        shr rcx, 8
        jmp .L_loop_positive
.L_negative:
        neg rcx
.L_loop_negative:
        cmp rcx, 0
        je .L_exit
        sar rdi, cl
        shr rcx, 8
        jmp .L_loop_negative
.L_exit:
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logand:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        and rdi, qword [r9 + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logor:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        or rdi, qword [r9 + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logxor:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        xor rdi, qword [r9 + 1]
        call make_integer
        LEAVE
        ret AND_KILL_FRAME(2)

L_code_ptr_lognot:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        assert_integer(r8)
        mov rdi, qword [r8 + 1]
        not rdi
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_bin_apply:
        ;1. Save the old rsp
        mov  r8, rbp
        push qword [rbp]
        mov rbp, rsp    
        
        ;2. Calc the number of the args - argv[1].length
        mov rsi, PARAM(1); rsi - point to the first var in the list
	mov rdi, rsi
	mov rcx, 0

.L_bin_apply_calc_number_of_args:
	cmp rdi, sob_nil
	je .L_bin_apply_end_calc_loop
	cmp byte [rdi], T_pair
        jne L_error_incorrect_type
	mov rdi, qword [rdi + 1 + 8] ; rdi = cdr list
	inc rcx
	jmp .L_bin_apply_calc_number_of_args

.L_bin_apply_end_calc_loop:
        ;3. Update rsp -> rsp - 8 * argv[1].length
        lea r11, [8*(rcx - 3)]
        sub rsp, r11

        ;4. Save return address of the closure
        mov r10, qword [rbp + 8 * 1] ; r10 points to return address
        mov qword [rsp], r10

        ;5. Save environment of the closure
        mov r10, PARAM(0)
        cmp byte [r10], T_closure
        jne L_error_incorrect_type
        mov rax, qword [r10 + 1] ; rax -> env
        mov qword [rsp + 8 * 1], rax

        ;6. Save new argc
        mov qword [rsp + 8 * 2], rcx

        ;5. Push all args in argv[1] to the stack
        lea r9, [rsp + 8 * 3]
	mov rdi, rsi; rsi - point to the first var in the list

.L_bin_apply_recycle_frame_loop:
	cmp rdi, sob_nil
	je .L_bin_apply_recycle_frame_done
        mov rax, qword [rdi + 1] ; rax -> car list
        mov qword [r9], rax
        add r9, 8
        mov rdi, qword [rdi + 1 + 8] ; rax -> cdr list
	jmp .L_bin_apply_recycle_frame_loop
        
.L_bin_apply_recycle_frame_done:
        mov  rbp, r8
        jmp SOB_CLOSURE_CODE(r10)
        

L_code_ptr_is_null:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_nil
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_pair:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_pair
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_void:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_void
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_char
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_string:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_string
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        and byte [r8], T_symbol
        jz .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_uninterned_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        cmp byte [r8], T_uninterned_symbol
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_interned_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_interned_symbol
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_gensym:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        inc qword [gensym_count]
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_uninterned_symbol
        mov rcx, qword [gensym_count]
        mov qword [rax + 1], rcx
        leave
        ret AND_KILL_FRAME(0)

L_code_ptr_is_vector:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_vector
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_closure:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_closure
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_real
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_fraction:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_fraction
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_boolean:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_boolean
        je .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_boolean_false:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        cmp bl, T_boolean_false
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_boolean_true:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        cmp bl, T_boolean_true
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_number:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_number
        jz .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_collection:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_collection
        je .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_cons:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, (1 + 8 + 8)
        call malloc
        mov byte [rax], T_pair
        mov rbx, PARAM(0)
        mov SOB_PAIR_CAR(rax), rbx
        mov rbx, PARAM(1)
        mov SOB_PAIR_CDR(rax), rbx
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_display_sexpr:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rdi, PARAM(0)
        call print_sexpr
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_write_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_char(rax)
        mov al, SOB_CHAR_VALUE(rax)
        and rax, 255
        mov rdi, fmt_char
        mov rsi, rax
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_car:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rax, SOB_PAIR_CAR(rax)
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_cdr:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rax, SOB_PAIR_CDR(rax)
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_string_length:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_string(rax)
        mov rdi, SOB_STRING_LENGTH(rax)
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_vector_length:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_vector(rax)
        mov rdi, SOB_VECTOR_LENGTH(rax)
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_real_to_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rbx, PARAM(0)
        assert_real(rbx)
        movsd xmm0, qword [rbx + 1]
        cvttsd2si rdi, xmm0
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_exit:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        mov rax, 0
        call exit

L_code_ptr_integer_to_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_integer(rax)
        push qword [rax + 1]
        cvtsi2sd xmm0, qword [rsp]
        call make_real
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_fraction_to_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        push qword [rax + 1]
        cvtsi2sd xmm0, qword [rsp]
        push qword [rax + 1 + 8]
        cvtsi2sd xmm1, qword [rsp]
        divsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_char_to_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_char(rax)
        mov al, byte [rax + 1]
        and rax, 255
        mov rdi, rax
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_integer_to_fraction:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        assert_integer(r8)
        mov rdi, (1 + 8 + 8)
        call malloc
        mov rbx, qword [r8 + 1]
        mov byte [rax], T_fraction
        mov qword [rax + 1], rbx
        mov qword [rax + 1 + 8], 1
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_integer_to_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_integer(rax)
        mov rbx, qword [rax + 1]
        cmp rbx, 0
        jle L_error_integer_range
        cmp rbx, 256
        jge L_error_integer_range
        mov rdi, (1 + 1)
        call malloc
        mov byte [rax], T_char
        mov byte [rax + 1], bl
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_trng:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        rdrand rdi
        shr rdi, 1
        call make_integer
        leave
        ret AND_KILL_FRAME(0)

L_code_ptr_is_zero:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_integer
        je .L_integer
        cmp byte [rax], T_fraction
        je .L_fraction
        cmp byte [rax], T_real
        je .L_real
        jmp L_error_incorrect_type
.L_integer:
        cmp qword [rax + 1], 0
        je .L_zero
        jmp .L_not_zero
.L_fraction:
        cmp qword [rax + 1], 0
        je .L_zero
        jmp .L_not_zero
.L_real:
        pxor xmm0, xmm0
        push qword [rax + 1]
        movsd xmm1, qword [rsp]
        ucomisd xmm0, xmm1
        je .L_zero
.L_not_zero:
        mov rax, sob_boolean_false
        jmp .L_end
.L_zero:
        mov rax, sob_boolean_true
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_integer
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_raw_bin_add_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        addsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        subsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        mulsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_div_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        pxor xmm2, xmm2
        ucomisd xmm1, xmm2
        je L_error_division_by_zero
        divsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_add_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	add rdi, qword [r9 + 1]
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_add_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1]     ; num2
        cqo
        imul rbx
        add rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	sub rdi, qword [r9 + 1]
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1]     ; num2
        cqo
        imul rbx
        sub rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	cqo
	mov rax, qword [r8 + 1]
	mul qword [r9 + 1]
	mov rdi, rax
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1] ; num2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_bin_div_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r9 + 1]
	cmp rdi, 0
	je L_error_division_by_zero
	mov rsi, qword [r8 + 1]
	call normalize_fraction
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_div_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        cmp qword [r9 + 1], 0
        je L_error_division_by_zero
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1] ; num2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)
        
normalize_fraction:
        push rsi
        push rdi
        call gcd
        mov rbx, rax
        pop rax
        cqo
        idiv rbx
        mov r8, rax
        pop rax
        cqo
        idiv rbx
        mov r9, rax
        cmp r9, 0
        je .L_zero
        cmp r8, 1
        je .L_int
        mov rdi, (1 + 8 + 8)
        call malloc
        mov byte [rax], T_fraction
        mov qword [rax + 1], r9
        mov qword [rax + 1 + 8], r8
        ret
.L_zero:
        mov rdi, 0
        call make_integer
        ret
.L_int:
        mov rdi, r9
        call make_integer
        ret

iabs:
        mov rax, rdi
        cmp rax, 0
        jl .Lneg
        ret
.Lneg:
        neg rax
        ret

gcd:
        call iabs
        mov rbx, rax
        mov rdi, rsi
        call iabs
        cmp rax, 0
        jne .L0
        xchg rax, rbx
.L0:
        cmp rbx, 0
        je .L1
        cqo
        div rbx
        mov rax, rdx
        xchg rax, rbx
        jmp .L0
.L1:
        ret

L_code_ptr_error:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_interned_symbol(rsi)
        mov rsi, PARAM(1)
        assert_string(rsi)
        mov rdi, fmt_scheme_error_part_1
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rdi, PARAM(0)
        call print_sexpr
        mov rdi, fmt_scheme_error_part_2
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, PARAM(1)       ; sob_string
        mov rsi, 1              ; size = 1 byte
        mov rdx, qword [rax + 1] ; length
        lea rdi, [rax + 1 + 8]   ; actual characters
        mov rcx, qword [stdout]  ; FILE*
	ENTER
        call fwrite
	LEAVE
        mov rdi, fmt_scheme_error_part_3
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, -9
        call exit

L_code_ptr_raw_less_than_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_real(rsi)
        mov rdi, PARAM(1)
        assert_real(rdi)
        movsd xmm0, qword [rsi + 1]
        movsd xmm1, qword [rdi + 1]
        comisd xmm0, xmm1
        jae .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_less_than_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	cmp rdi, qword [r9 + 1]
	jge .L_false
	mov rax, sob_boolean_true
	jmp .L_exit
.L_false:
	mov rax, sob_boolean_false
.L_exit:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_less_than_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_fraction(rsi)
        mov rdi, PARAM(1)
        assert_fraction(rdi)
        mov rax, qword [rsi + 1] ; num1
        cqo
        imul qword [rdi + 1 + 8] ; den2
        mov rcx, rax
        mov rax, qword [rsi + 1 + 8] ; den1
        cqo
        imul qword [rdi + 1]          ; num2
        sub rcx, rax
        jge .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_equal_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_real(rsi)
        mov rdi, PARAM(1)
        assert_real(rdi)
        movsd xmm0, qword [rsi + 1]
        movsd xmm1, qword [rdi + 1]
        comisd xmm0, xmm1
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_equal_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	cmp rdi, qword [r9 + 1]
	jne .L_false
	mov rax, sob_boolean_true
	jmp .L_exit
.L_false:
	mov rax, sob_boolean_false
.L_exit:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_equal_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_fraction(rsi)
        mov rdi, PARAM(1)
        assert_fraction(rdi)
        mov rax, qword [rsi + 1] ; num1
        cqo
        imul qword [rdi + 1 + 8] ; den2
        mov rcx, rax
        mov rax, qword [rdi + 1 + 8] ; den1
        cqo
        imul qword [rdi + 1]          ; num2
        sub rcx, rax
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_quotient:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_integer(rsi)
        mov rdi, PARAM(1)
        assert_integer(rdi)
        mov rax, qword [rsi + 1]
        mov rbx, qword [rdi + 1]
        cmp rbx, 0
        je L_error_division_by_zero
        cqo
        idiv rbx
        mov rdi, rax
        call make_integer
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_remainder:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_integer(rsi)
        mov rdi, PARAM(1)
        assert_integer(rdi)
        mov rax, qword [rsi + 1]
        mov rbx, qword [rdi + 1]
        cmp rbx, 0
        je L_error_division_by_zero
        cqo
        idiv rbx
        mov rdi, rdx
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_set_car:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rbx, PARAM(1)
        mov SOB_PAIR_CAR(rax), rbx
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_set_cdr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rbx, PARAM(1)
        mov SOB_PAIR_CDR(rax), rbx
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_string_ref:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_string(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov bl, byte [rdi + 1 + 8 + 1 * rcx]
        mov rdi, 2
        call malloc
        mov byte [rax], T_char
        mov byte [rax + 1], bl
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_vector_ref:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_vector(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, [rdi + 1 + 8 + 8 * rcx]
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_vector_set:
        enter 0, 0
        cmp COUNT, 3
        jne L_error_arg_count_3
        mov rdi, PARAM(0)
        assert_vector(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, PARAM(2)
        mov qword [rdi + 1 + 8 + 8 * rcx], rax
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(3)

L_code_ptr_string_set:
        enter 0, 0
        cmp COUNT, 3
        jne L_error_arg_count_3
        mov rdi, PARAM(0)
        assert_string(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, PARAM(2)
        assert_char(rax)
        mov al, byte [rax + 1]
        mov byte [rdi + 1 + 8 + 1 * rcx], al
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(3)

L_code_ptr_make_vector:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_integer_range
        mov rdx, PARAM(1)
        lea rdi, [1 + 8 + 8 * rcx]
        call malloc
        mov byte [rax], T_vector
        mov qword [rax + 1], rcx
        mov r8, 0
.L0:
        cmp r8, rcx
        je .L1
        mov qword [rax + 1 + 8 + 8 * r8], rdx
        inc r8
        jmp .L0
.L1:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_make_string:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_integer_range
        mov rdx, PARAM(1)
        assert_char(rdx)
        mov dl, byte [rdx + 1]
        lea rdi, [1 + 8 + 1 * rcx]
        call malloc
        mov byte [rax], T_string
        mov qword [rax + 1], rcx
        mov r8, 0
.L0:
        cmp r8, rcx
        je .L1
        mov byte [rax + 1 + 8 + 1 * r8], dl
        inc r8
        jmp .L0
.L1:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_numerator:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        mov rdi, qword [rax + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_denominator:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        mov rdi, qword [rax + 1 + 8]
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_eq:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov rdi, PARAM(0)
	mov rsi, PARAM(1)
	cmp rdi, rsi
	je .L_eq_true
	mov dl, byte [rdi]
	cmp dl, byte [rsi]
	jne .L_eq_false
	cmp dl, T_char
	je .L_char
	cmp dl, T_interned_symbol
	je .L_interned_symbol
        cmp dl, T_uninterned_symbol
        je .L_uninterned_symbol
	cmp dl, T_real
	je .L_real
	cmp dl, T_fraction
	je .L_fraction
        cmp dl, T_integer
        je .L_integer
	jmp .L_eq_false
.L_integer:
        mov rax, qword [rsi + 1]
        cmp rax, qword [rdi + 1]
        jne .L_eq_false
        jmp .L_eq_true
.L_fraction:
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
	jne .L_eq_false
	mov rax, qword [rsi + 1 + 8]
	cmp rax, qword [rdi + 1 + 8]
	jne .L_eq_false
	jmp .L_eq_true
.L_real:
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
.L_interned_symbol:
	; never reached, because interned_symbols are static!
	; but I'm keeping it in case, I'll ever change
	; the implementation
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
.L_uninterned_symbol:
        mov r8, qword [rdi + 1]
        cmp r8, qword [rsi + 1]
        jne .L_eq_false
        jmp .L_eq_true
.L_char:
	mov bl, byte [rsi + 1]
	cmp bl, byte [rdi + 1]
	jne .L_eq_false
.L_eq_true:
	mov rax, sob_boolean_true
	jmp .L_eq_exit
.L_eq_false:
	mov rax, sob_boolean_false
.L_eq_exit:
	leave
	ret AND_KILL_FRAME(2)

make_real:
        enter 0, 0
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_real
        movsd qword [rax + 1], xmm0
        leave 
        ret
        
make_integer:
        enter 0, 0
        mov rsi, rdi
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_integer
        mov qword [rax + 1], rsi
        leave
        ret
        
L_error_integer_range:
        mov rdi, qword [stderr]
        mov rsi, fmt_integer_range
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -5
        call exit

L_error_arg_negative:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_negative
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_0:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_0
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_1:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_1
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_2:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_2
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_12:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_12
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_3:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_3
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit
        
L_error_incorrect_type:
        mov rdi, qword [stderr]
        mov rsi, fmt_type
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -4
        call exit

L_error_division_by_zero:
        mov rdi, qword [stderr]
        mov rsi, fmt_division_by_zero
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -8
        call exit

section .data
gensym_count:
        dq 0
fmt_char:
        db `%c\0`
fmt_arg_negative:
        db `!!! The argument cannot be negative.\n\0`
fmt_arg_count_0:
        db `!!! Expecting zero arguments. Found %d\n\0`
fmt_arg_count_1:
        db `!!! Expecting one argument. Found %d\n\0`
fmt_arg_count_12:
        db `!!! Expecting one required and one optional argument. Found %d\n\0`
fmt_arg_count_2:
        db `!!! Expecting two arguments. Found %d\n\0`
fmt_arg_count_3:
        db `!!! Expecting three arguments. Found %d\n\0`
fmt_type:
        db `!!! Function passed incorrect type\n\0`
fmt_integer_range:
        db `!!! Incorrect integer range\n\0`
fmt_division_by_zero:
        db `!!! Division by zero\n\0`
fmt_scheme_error_part_1:
        db `\n!!! The procedure \0`
fmt_scheme_error_part_2:
        db ` asked to terminate the program\n`
        db `    with the following message:\n\n\0`
fmt_scheme_error_part_3:
        db `\n\nGoodbye!\n\n\0`

section .note.GNU-stack noalloc noexec nowrite progbits
