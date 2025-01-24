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

free_var_80:	; location of eq?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1174

free_var_81:	; location of equal?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3224

free_var_82:	; location of error
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 785

free_var_83:	; location of even?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3176

free_var_84:	; location of fact
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2307

free_var_85:	; location of fold-left
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2073

free_var_86:	; location of fold-right
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2106

free_var_87:	; location of fraction->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 402

free_var_88:	; location of fraction?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 152

free_var_89:	; location of integer->char
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 447

free_var_90:	; location of integer->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 380

free_var_91:	; location of integer?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 496

free_var_92:	; location of list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1919

free_var_93:	; location of list*
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1962

free_var_94:	; location of list->string
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2715

free_var_95:	; location of list->vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3068

free_var_96:	; location of list?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1905

free_var_97:	; location of logarithm
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3467

free_var_98:	; location of make-list-thunk
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3391

free_var_99:	; location of make-string
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1116

free_var_100:	; location of make-string-thunk
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3415

free_var_101:	; location of make-vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1096

free_var_102:	; location of make-vector-thunk
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3441

free_var_103:	; location of map
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2030

free_var_104:	; location of negative?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3158

free_var_105:	; location of newline
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3494

free_var_106:	; location of not
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1932

free_var_107:	; location of null?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 6

free_var_108:	; location of number?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 187

free_var_109:	; location of odd?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3199

free_var_110:	; location of ormap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2016

free_var_111:	; location of pair?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 20

free_var_112:	; location of positive?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3140

free_var_113:	; location of random
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3125

free_var_114:	; location of rational?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1944

free_var_115:	; location of real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2238

free_var_116:	; location of real?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 138

free_var_117:	; location of remainder
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 966

free_var_118:	; location of reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2057

free_var_119:	; location of string->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2736

free_var_120:	; location of string-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3253

free_var_121:	; location of string-ci<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2864

free_var_122:	; location of string-ci<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2844

free_var_123:	; location of string-ci=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2885

free_var_124:	; location of string-ci>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2905

free_var_125:	; location of string-ci>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2926

free_var_126:	; location of string-downcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2669

free_var_127:	; location of string-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 301

free_var_128:	; location of string-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1018

free_var_129:	; location of string-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3297

free_var_130:	; location of string-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3343

free_var_131:	; location of string-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1076

free_var_132:	; location of string-upcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2693

free_var_133:	; location of string<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2774

free_var_134:	; location of string<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2757

free_var_135:	; location of string=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2792

free_var_136:	; location of string>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2809

free_var_137:	; location of string>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2827

free_var_138:	; location of string?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 62

free_var_139:	; location of trng
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 469

free_var_140:	; location of vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3089

free_var_141:	; location of vector->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3104

free_var_142:	; location of vector-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3275

free_var_143:	; location of vector-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 323

free_var_144:	; location of vector-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1037

free_var_145:	; location of vector-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3320

free_var_146:	; location of vector-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3367

free_var_147:	; location of vector-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1056

free_var_148:	; location of vector?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 103

free_var_149:	; location of void
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3512

free_var_150:	; location of write-char
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 258

free_var_151:	; location of zero?
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
	mov rdi, free_var_107
	mov rsi, L_code_ptr_is_null
	call bind_primitive

	; building closure for pair?
	mov rdi, free_var_111
	mov rsi, L_code_ptr_is_pair
	call bind_primitive

	; building closure for char?
	mov rdi, free_var_78
	mov rsi, L_code_ptr_is_char
	call bind_primitive

	; building closure for string?
	mov rdi, free_var_138
	mov rsi, L_code_ptr_is_string
	call bind_primitive

	; building closure for vector?
	mov rdi, free_var_148
	mov rsi, L_code_ptr_is_vector
	call bind_primitive

	; building closure for real?
	mov rdi, free_var_116
	mov rsi, L_code_ptr_is_real
	call bind_primitive

	; building closure for fraction?
	mov rdi, free_var_88
	mov rsi, L_code_ptr_is_fraction
	call bind_primitive

	; building closure for number?
	mov rdi, free_var_108
	mov rsi, L_code_ptr_is_number
	call bind_primitive

	; building closure for cons
	mov rdi, free_var_79
	mov rsi, L_code_ptr_cons
	call bind_primitive

	; building closure for write-char
	mov rdi, free_var_150
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
	mov rdi, free_var_127
	mov rsi, L_code_ptr_string_length
	call bind_primitive

	; building closure for vector-length
	mov rdi, free_var_143
	mov rsi, L_code_ptr_vector_length
	call bind_primitive

	; building closure for integer->real
	mov rdi, free_var_90
	mov rsi, L_code_ptr_integer_to_real
	call bind_primitive

	; building closure for fraction->real
	mov rdi, free_var_87
	mov rsi, L_code_ptr_fraction_to_real
	call bind_primitive

	; building closure for char->integer
	mov rdi, free_var_65
	mov rsi, L_code_ptr_char_to_integer
	call bind_primitive

	; building closure for integer->char
	mov rdi, free_var_89
	mov rsi, L_code_ptr_integer_to_char
	call bind_primitive

	; building closure for trng
	mov rdi, free_var_139
	mov rsi, L_code_ptr_trng
	call bind_primitive

	; building closure for zero?
	mov rdi, free_var_151
	mov rsi, L_code_ptr_is_zero
	call bind_primitive

	; building closure for integer?
	mov rdi, free_var_91
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
	mov rdi, free_var_82
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
	mov rdi, free_var_117
	mov rsi, L_code_ptr_remainder
	call bind_primitive

	; building closure for string-ref
	mov rdi, free_var_128
	mov rsi, L_code_ptr_string_ref
	call bind_primitive

	; building closure for vector-ref
	mov rdi, free_var_144
	mov rsi, L_code_ptr_vector_ref
	call bind_primitive

	; building closure for vector-set!
	mov rdi, free_var_147
	mov rsi, L_code_ptr_vector_set
	call bind_primitive

	; building closure for string-set!
	mov rdi, free_var_131
	mov rsi, L_code_ptr_string_set
	call bind_primitive

	; building closure for make-vector
	mov rdi, free_var_101
	mov rsi, L_code_ptr_make_vector
	call bind_primitive

	; building closure for make-string
	mov rdi, free_var_99
	mov rsi, L_code_ptr_make_string
	call bind_primitive

	; building closure for eq?
	mov rdi, free_var_80
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
.L_lambda_simple_env_loop_04f9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04f9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04f9
.L_lambda_simple_env_end_04f9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04f9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04f9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04f9
.L_lambda_simple_params_end_04f9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04f9
	jmp .L_lambda_simple_end_04f9
.L_lambda_simple_code_04f9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04f9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f9:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_047d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_047d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_047d
.L_tc_recycle_frame_done_047d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04f9:	; new closure is in rax
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
.L_lambda_simple_env_loop_04fa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04fa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04fa
.L_lambda_simple_env_end_04fa:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04fa:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04fa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04fa
.L_lambda_simple_params_end_04fa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04fa
	jmp .L_lambda_simple_end_04fa
.L_lambda_simple_code_04fa:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04fa
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04fa:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_047e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_047e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_047e
.L_tc_recycle_frame_done_047e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04fa:	; new closure is in rax
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
.L_lambda_simple_env_loop_04fb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04fb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04fb
.L_lambda_simple_env_end_04fb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04fb:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04fb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04fb
.L_lambda_simple_params_end_04fb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04fb
	jmp .L_lambda_simple_end_04fb
.L_lambda_simple_code_04fb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04fb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04fb:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_047f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_047f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_047f
.L_tc_recycle_frame_done_047f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04fb:	; new closure is in rax
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
.L_lambda_simple_env_loop_04fc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04fc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04fc
.L_lambda_simple_env_end_04fc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04fc:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04fc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04fc
.L_lambda_simple_params_end_04fc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04fc
	jmp .L_lambda_simple_end_04fc
.L_lambda_simple_code_04fc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04fc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04fc:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0480:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0480
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0480
.L_tc_recycle_frame_done_0480:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04fc:	; new closure is in rax
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
.L_lambda_simple_env_loop_04fd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04fd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04fd
.L_lambda_simple_env_end_04fd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04fd:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04fd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04fd
.L_lambda_simple_params_end_04fd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04fd
	jmp .L_lambda_simple_end_04fd
.L_lambda_simple_code_04fd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04fd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04fd:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0481:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0481
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0481
.L_tc_recycle_frame_done_0481:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04fd:	; new closure is in rax
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
.L_lambda_simple_env_loop_04fe:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04fe
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04fe
.L_lambda_simple_env_end_04fe:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04fe:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04fe
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04fe
.L_lambda_simple_params_end_04fe:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04fe
	jmp .L_lambda_simple_end_04fe
.L_lambda_simple_code_04fe:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04fe
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04fe:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0482:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0482
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0482
.L_tc_recycle_frame_done_0482:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04fe:	; new closure is in rax
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
.L_lambda_simple_env_loop_04ff:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04ff
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04ff
.L_lambda_simple_env_end_04ff:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04ff:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04ff
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04ff
.L_lambda_simple_params_end_04ff:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04ff
	jmp .L_lambda_simple_end_04ff
.L_lambda_simple_code_04ff:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04ff
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ff:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0483:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0483
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0483
.L_tc_recycle_frame_done_0483:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04ff:	; new closure is in rax
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
.L_lambda_simple_env_loop_0500:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0500
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0500
.L_lambda_simple_env_end_0500:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0500:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0500
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0500
.L_lambda_simple_params_end_0500:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0500
	jmp .L_lambda_simple_end_0500
.L_lambda_simple_code_0500:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0500
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0500:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0484:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0484
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0484
.L_tc_recycle_frame_done_0484:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0500:	; new closure is in rax
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
.L_lambda_simple_env_loop_0501:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0501
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0501
.L_lambda_simple_env_end_0501:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0501:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0501
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0501
.L_lambda_simple_params_end_0501:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0501
	jmp .L_lambda_simple_end_0501
.L_lambda_simple_code_0501:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0501
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0501:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0485:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0485
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0485
.L_tc_recycle_frame_done_0485:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0501:	; new closure is in rax
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
.L_lambda_simple_env_loop_0502:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0502
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0502
.L_lambda_simple_env_end_0502:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0502:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0502
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0502
.L_lambda_simple_params_end_0502:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0502
	jmp .L_lambda_simple_end_0502
.L_lambda_simple_code_0502:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0502
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0502:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0486:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0486
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0486
.L_tc_recycle_frame_done_0486:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0502:	; new closure is in rax
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
.L_lambda_simple_env_loop_0503:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0503
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0503
.L_lambda_simple_env_end_0503:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0503:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0503
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0503
.L_lambda_simple_params_end_0503:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0503
	jmp .L_lambda_simple_end_0503
.L_lambda_simple_code_0503:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0503
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0503:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0487:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0487
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0487
.L_tc_recycle_frame_done_0487:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0503:	; new closure is in rax
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
.L_lambda_simple_env_loop_0504:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0504
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0504
.L_lambda_simple_env_end_0504:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0504:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0504
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0504
.L_lambda_simple_params_end_0504:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0504
	jmp .L_lambda_simple_end_0504
.L_lambda_simple_code_0504:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0504
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0504:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0488:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0488
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0488
.L_tc_recycle_frame_done_0488:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0504:	; new closure is in rax
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
.L_lambda_simple_env_loop_0505:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0505
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0505
.L_lambda_simple_env_end_0505:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0505:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0505
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0505
.L_lambda_simple_params_end_0505:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0505
	jmp .L_lambda_simple_end_0505
.L_lambda_simple_code_0505:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0505
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0505:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0489:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0489
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0489
.L_tc_recycle_frame_done_0489:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0505:	; new closure is in rax
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
.L_lambda_simple_env_loop_0506:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0506
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0506
.L_lambda_simple_env_end_0506:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0506:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0506
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0506
.L_lambda_simple_params_end_0506:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0506
	jmp .L_lambda_simple_end_0506
.L_lambda_simple_code_0506:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0506
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0506:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_048a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_048a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_048a
.L_tc_recycle_frame_done_048a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0506:	; new closure is in rax
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
.L_lambda_simple_env_loop_0507:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0507
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0507
.L_lambda_simple_env_end_0507:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0507:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0507
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0507
.L_lambda_simple_params_end_0507:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0507
	jmp .L_lambda_simple_end_0507
.L_lambda_simple_code_0507:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0507
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0507:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_048b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_048b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_048b
.L_tc_recycle_frame_done_048b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0507:	; new closure is in rax
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
.L_lambda_simple_env_loop_0508:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0508
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0508
.L_lambda_simple_env_end_0508:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0508:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0508
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0508
.L_lambda_simple_params_end_0508:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0508
	jmp .L_lambda_simple_end_0508
.L_lambda_simple_code_0508:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0508
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0508:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_048c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_048c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_048c
.L_tc_recycle_frame_done_048c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0508:	; new closure is in rax
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
.L_lambda_simple_env_loop_0509:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0509
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0509
.L_lambda_simple_env_end_0509:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0509:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0509
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0509
.L_lambda_simple_params_end_0509:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0509
	jmp .L_lambda_simple_end_0509
.L_lambda_simple_code_0509:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0509
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0509:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_048d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_048d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_048d
.L_tc_recycle_frame_done_048d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0509:	; new closure is in rax
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
.L_lambda_simple_env_loop_050a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_050a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_050a
.L_lambda_simple_env_end_050a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_050a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_050a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_050a
.L_lambda_simple_params_end_050a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_050a
	jmp .L_lambda_simple_end_050a
.L_lambda_simple_code_050a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_050a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_050a:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_048e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_048e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_048e
.L_tc_recycle_frame_done_048e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_050a:	; new closure is in rax
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
.L_lambda_simple_env_loop_050b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_050b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_050b
.L_lambda_simple_env_end_050b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_050b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_050b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_050b
.L_lambda_simple_params_end_050b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_050b
	jmp .L_lambda_simple_end_050b
.L_lambda_simple_code_050b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_050b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_050b:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_048f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_048f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_048f
.L_tc_recycle_frame_done_048f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_050b:	; new closure is in rax
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
.L_lambda_simple_env_loop_050c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_050c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_050c
.L_lambda_simple_env_end_050c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_050c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_050c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_050c
.L_lambda_simple_params_end_050c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_050c
	jmp .L_lambda_simple_end_050c
.L_lambda_simple_code_050c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_050c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_050c:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0490:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0490
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0490
.L_tc_recycle_frame_done_0490:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_050c:	; new closure is in rax
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
.L_lambda_simple_env_loop_050d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_050d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_050d
.L_lambda_simple_env_end_050d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_050d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_050d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_050d
.L_lambda_simple_params_end_050d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_050d
	jmp .L_lambda_simple_end_050d
.L_lambda_simple_code_050d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_050d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_050d:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0491:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0491
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0491
.L_tc_recycle_frame_done_0491:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_050d:	; new closure is in rax
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
.L_lambda_simple_env_loop_050e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_050e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_050e
.L_lambda_simple_env_end_050e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_050e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_050e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_050e
.L_lambda_simple_params_end_050e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_050e
	jmp .L_lambda_simple_end_050e
.L_lambda_simple_code_050e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_050e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_050e:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0492:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0492
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0492
.L_tc_recycle_frame_done_0492:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_050e:	; new closure is in rax
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
.L_lambda_simple_env_loop_050f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_050f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_050f
.L_lambda_simple_env_end_050f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_050f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_050f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_050f
.L_lambda_simple_params_end_050f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_050f
	jmp .L_lambda_simple_end_050f
.L_lambda_simple_code_050f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_050f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_050f:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0493:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0493
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0493
.L_tc_recycle_frame_done_0493:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_050f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0510:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0510
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0510
.L_lambda_simple_env_end_0510:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0510:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0510
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0510
.L_lambda_simple_params_end_0510:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0510
	jmp .L_lambda_simple_end_0510
.L_lambda_simple_code_0510:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0510
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0510:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0494:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0494
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0494
.L_tc_recycle_frame_done_0494:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0510:	; new closure is in rax
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
.L_lambda_simple_env_loop_0511:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0511
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0511
.L_lambda_simple_env_end_0511:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0511:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0511
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0511
.L_lambda_simple_params_end_0511:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0511
	jmp .L_lambda_simple_end_0511
.L_lambda_simple_code_0511:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0511
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0511:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0495:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0495
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0495
.L_tc_recycle_frame_done_0495:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0511:	; new closure is in rax
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
.L_lambda_simple_env_loop_0512:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0512
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0512
.L_lambda_simple_env_end_0512:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0512:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0512
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0512
.L_lambda_simple_params_end_0512:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0512
	jmp .L_lambda_simple_end_0512
.L_lambda_simple_code_0512:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0512
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0512:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0496:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0496
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0496
.L_tc_recycle_frame_done_0496:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0512:	; new closure is in rax
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
.L_lambda_simple_env_loop_0513:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0513
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0513
.L_lambda_simple_env_end_0513:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0513:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0513
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0513
.L_lambda_simple_params_end_0513:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0513
	jmp .L_lambda_simple_end_0513
.L_lambda_simple_code_0513:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0513
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0513:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0497:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0497
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0497
.L_tc_recycle_frame_done_0497:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0513:	; new closure is in rax
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
.L_lambda_simple_env_loop_0514:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0514
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0514
.L_lambda_simple_env_end_0514:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0514:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0514
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0514
.L_lambda_simple_params_end_0514:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0514
	jmp .L_lambda_simple_end_0514
.L_lambda_simple_code_0514:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0514
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0514:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0498:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0498
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0498
.L_tc_recycle_frame_done_0498:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0514:	; new closure is in rax
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
.L_lambda_simple_env_loop_0515:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0515
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0515
.L_lambda_simple_env_end_0515:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0515:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0515
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0515
.L_lambda_simple_params_end_0515:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0515
	jmp .L_lambda_simple_end_0515
.L_lambda_simple_code_0515:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0515
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0515:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0039
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0221
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
	push 1	; argc
	mov rax, qword [free_var_96]	; free var list?
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
.L_tc_recycle_frame_loop_0499:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0499
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0499
.L_tc_recycle_frame_done_0499:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0221
.L_if_else_0221:
	mov rax, L_constants + 2
.L_if_end_0221:
.L_or_end_0039:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0515:	; new closure is in rax
	mov qword [free_var_96], rax
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
.L_lambda_opt_env_loop_0061:
	cmp rsi, 0
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
	cmp rsi, 0
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
	mov r8, qword [rsp + 8 * 2]
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
	mov qword [rsp + 8 * 2], 1
	enter 0, 0
	mov rax, PARAM(0)	; param args
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_0061:
	mov qword [free_var_92], rax
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
.L_lambda_simple_env_loop_0516:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0516
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0516
.L_lambda_simple_env_end_0516:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0516:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0516
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0516
.L_lambda_simple_params_end_0516:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0516
	jmp .L_lambda_simple_end_0516
.L_lambda_simple_code_0516:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0516
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0516:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	cmp rax, sob_boolean_false
	je .L_if_else_0222
	mov rax, L_constants + 2
	jmp .L_if_end_0222
.L_if_else_0222:
	mov rax, L_constants + 3
.L_if_end_0222:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0516:	; new closure is in rax
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
.L_lambda_simple_env_loop_0517:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0517
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0517
.L_lambda_simple_env_end_0517:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0517:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0517
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0517
.L_lambda_simple_params_end_0517:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0517
	jmp .L_lambda_simple_end_0517
.L_lambda_simple_code_0517:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0517
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0517:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param q
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_003a
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param q
	push rax
	push 1	; argc
	mov rax, qword [free_var_88]	; free var fraction?
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
.L_tc_recycle_frame_loop_049a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_049a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_049a
.L_tc_recycle_frame_done_049a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_003a:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0517:	; new closure is in rax
	mov qword [free_var_114], rax
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
.L_lambda_simple_env_loop_0518:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0518
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0518
.L_lambda_simple_env_end_0518:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0518:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0518
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0518
.L_lambda_simple_params_end_0518:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0518
	jmp .L_lambda_simple_end_0518
.L_lambda_simple_code_0518:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0518
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0518:
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
.L_lambda_simple_env_loop_0519:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0519
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0519
.L_lambda_simple_env_end_0519:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0519:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0519
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0519
.L_lambda_simple_params_end_0519:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0519
	jmp .L_lambda_simple_end_0519
.L_lambda_simple_code_0519:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0519
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0519:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0223
	mov rax, PARAM(0)	; param a
	jmp .L_if_end_0223
.L_if_else_0223:
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_049b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_049b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_049b
.L_tc_recycle_frame_done_049b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0223:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0519:	; new closure is in rax
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
.L_lambda_opt_env_loop_0062:
	cmp rsi, 1
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
	mov r8, qword [rsp + 8 * 2]
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
	mov qword [rsp + 8 * 2], 2
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_049c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_049c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_049c
.L_tc_recycle_frame_done_049c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0062:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0518:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_93], rax
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
.L_lambda_simple_env_loop_051a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_051a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_051a
.L_lambda_simple_env_end_051a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_051a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_051a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_051a
.L_lambda_simple_params_end_051a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_051a
	jmp .L_lambda_simple_end_051a
.L_lambda_simple_code_051a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_051a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_051a:
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
.L_lambda_simple_env_loop_051b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_051b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_051b
.L_lambda_simple_env_end_051b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_051b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_051b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_051b
.L_lambda_simple_params_end_051b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_051b
	jmp .L_lambda_simple_end_051b
.L_lambda_simple_code_051b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_051b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_051b:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0224
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_049d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_049d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_049d
.L_tc_recycle_frame_done_049d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0224
.L_if_else_0224:
	mov rax, PARAM(0)	; param a
.L_if_end_0224:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_051b:	; new closure is in rax
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
.L_lambda_opt_env_loop_0063:
	cmp rsi, 1
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
	mov r8, qword [rsp + 8 * 2]
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
	mov qword [rsp + 8 * 2], 2
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_049e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_049e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_049e
.L_tc_recycle_frame_done_049e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0063:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_051a:	; new closure is in rax
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
.L_lambda_opt_env_loop_0064:
	cmp rsi, 0
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
	cmp rsi, 0
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
	mov r8, qword [rsp + 8 * 2]
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
	mov qword [rsp + 8 * 2], 2
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_051c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_051c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_051c
.L_lambda_simple_env_end_051c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_051c:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_051c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_051c
.L_lambda_simple_params_end_051c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_051c
	jmp .L_lambda_simple_end_051c
.L_lambda_simple_code_051c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_051c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_051c:
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
.L_lambda_simple_env_loop_051d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_051d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_051d
.L_lambda_simple_env_end_051d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_051d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_051d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_051d
.L_lambda_simple_params_end_051d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_051d
	jmp .L_lambda_simple_end_051d
.L_lambda_simple_code_051d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_051d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_051d:
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
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0225
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_103]	; free var map
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
	jne .L_or_end_003b
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_103]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
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
.L_tc_recycle_frame_loop_04a0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04a0
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04a0
.L_tc_recycle_frame_done_04a0:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_003b:
	jmp .L_if_end_0225
.L_if_else_0225:
	mov rax, L_constants + 2
.L_if_end_0225:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_051d:	; new closure is in rax
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
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0226
	;debug: preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; argc
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
.L_tc_recycle_frame_loop_04a1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04a1
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04a1
.L_tc_recycle_frame_done_04a1:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0226
.L_if_else_0226:
	mov rax, L_constants + 2
.L_if_end_0226:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_051c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_049f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_049f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_049f
.L_tc_recycle_frame_done_049f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0064:
	mov qword [free_var_110], rax
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
.L_lambda_opt_env_loop_0065:
	cmp rsi, 0
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
	cmp rsi, 0
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
	mov r8, qword [rsp + 8 * 2]
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
	mov qword [rsp + 8 * 2], 2
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_051e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_051e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_051e
.L_lambda_simple_env_end_051e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_051e:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_051e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_051e
.L_lambda_simple_params_end_051e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_051e
	jmp .L_lambda_simple_end_051e
.L_lambda_simple_code_051e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_051e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_051e:
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
.L_lambda_simple_env_loop_051f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_051f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_051f
.L_lambda_simple_env_end_051f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_051f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_051f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_051f
.L_lambda_simple_params_end_051f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_051f
	jmp .L_lambda_simple_end_051f
.L_lambda_simple_code_051f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_051f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_051f:
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
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_003c
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_103]	; free var map
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
	je .L_if_else_0227
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_103]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
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
.L_tc_recycle_frame_loop_04a3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04a3
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04a3
.L_tc_recycle_frame_done_04a3:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0227
.L_if_else_0227:
	mov rax, L_constants + 2
.L_if_end_0227:
.L_or_end_003c:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_051f:	; new closure is in rax
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
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_003d
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0228
	;debug: preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; argc
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
.L_tc_recycle_frame_loop_04a4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04a4
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04a4
.L_tc_recycle_frame_done_04a4:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0228
.L_if_else_0228:
	mov rax, L_constants + 2
.L_if_end_0228:
.L_or_end_003d:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_051e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_04a2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04a2
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04a2
.L_tc_recycle_frame_done_04a2:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0065:
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
.L_lambda_simple_env_loop_0520:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0520
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0520
.L_lambda_simple_env_end_0520:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0520:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0520
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0520
.L_lambda_simple_params_end_0520:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0520
	jmp .L_lambda_simple_end_0520
.L_lambda_simple_code_0520:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0520
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0520:
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
.L_lambda_simple_env_loop_0521:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0521
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0521
.L_lambda_simple_env_end_0521:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0521:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0521
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0521
.L_lambda_simple_params_end_0521:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0521
	jmp .L_lambda_simple_end_0521
.L_lambda_simple_code_0521:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0521
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0521:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0229
	mov rax, L_constants + 1
	jmp .L_if_end_0229
.L_if_else_0229:
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_04a5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04a5
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04a5
.L_tc_recycle_frame_done_04a5:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0229:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0521:	; new closure is in rax
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
.L_lambda_simple_env_loop_0522:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0522
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0522
.L_lambda_simple_env_end_0522:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0522:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0522
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0522
.L_lambda_simple_params_end_0522:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0522
	jmp .L_lambda_simple_end_0522
.L_lambda_simple_code_0522:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0522
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0522:
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
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_022a
	mov rax, L_constants + 1
	jmp .L_if_end_022a
.L_if_else_022a:
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_04a6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04a6
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04a6
.L_tc_recycle_frame_done_04a6:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_022a:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0522:	; new closure is in rax
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
	cmp rsi, 2
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
	mov r8, qword [rsp + 8 * 2]
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
	mov qword [rsp + 8 * 2], 2
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_022b
	mov rax, L_constants + 1
	jmp .L_if_end_022b
.L_if_else_022b:
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04a7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04a7
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04a7
.L_tc_recycle_frame_done_04a7:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_022b:
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0066:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0520:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
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
.L_lambda_simple_env_loop_0523:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0523
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0523
.L_lambda_simple_env_end_0523:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0523:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0523
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0523
.L_lambda_simple_params_end_0523:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0523
	jmp .L_lambda_simple_end_0523
.L_lambda_simple_code_0523:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0523
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0523:
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
.L_lambda_simple_env_loop_0524:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0524
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0524
.L_lambda_simple_env_end_0524:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0524:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0524
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0524
.L_lambda_simple_params_end_0524:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0524
	jmp .L_lambda_simple_end_0524
.L_lambda_simple_code_0524:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0524
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0524:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param r
	push rax
	mov rax, PARAM(1)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04a9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04a9
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04a9
.L_tc_recycle_frame_done_04a9:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0524:	; new closure is in rax
	push rax
	push 3	; argc
	mov rax, qword [free_var_85]	; free var fold-left
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
.L_tc_recycle_frame_loop_04a8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04a8
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04a8
.L_tc_recycle_frame_done_04a8:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0523:	; new closure is in rax
	mov qword [free_var_118], rax
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
.L_lambda_simple_env_loop_0525:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0525
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0525
.L_lambda_simple_env_end_0525:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0525:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0525
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0525
.L_lambda_simple_params_end_0525:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0525
	jmp .L_lambda_simple_end_0525
.L_lambda_simple_code_0525:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0525
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0525:
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
.L_lambda_simple_env_loop_0526:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0526
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0526
.L_lambda_simple_env_end_0526:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0526:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0526
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0526
.L_lambda_simple_params_end_0526:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0526
	jmp .L_lambda_simple_end_0526
.L_lambda_simple_code_0526:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0526
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0526:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_022c
	mov rax, PARAM(0)	; param s1
	jmp .L_if_end_022c
.L_if_else_022c:
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_04aa:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04aa
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04aa
.L_tc_recycle_frame_done_04aa:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_022c:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0526:	; new closure is in rax
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
.L_lambda_simple_env_loop_0527:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0527
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0527
.L_lambda_simple_env_end_0527:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0527:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0527
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0527
.L_lambda_simple_params_end_0527:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0527
	jmp .L_lambda_simple_end_0527
.L_lambda_simple_code_0527:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0527
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0527:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s1
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_022d
	mov rax, PARAM(1)	; param s2
	jmp .L_if_end_022d
.L_if_else_022d:
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_04ab:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ab
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04ab
.L_tc_recycle_frame_done_04ab:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_022d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0527:	; new closure is in rax
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
.L_lambda_opt_env_loop_0067:
	cmp rsi, 1
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
	cmp rsi, 2
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
	mov r8, qword [rsp + 8 * 2]
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
	mov qword [rsp + 8 * 2], 1
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_022e
	mov rax, L_constants + 1
	jmp .L_if_end_022e
.L_if_else_022e:
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_04ac:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ac
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04ac
.L_tc_recycle_frame_done_04ac:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_022e:
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_0067:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0525:	; new closure is in rax
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
.L_lambda_simple_env_loop_0528:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0528
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0528
.L_lambda_simple_env_end_0528:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0528:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0528
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0528
.L_lambda_simple_params_end_0528:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0528
	jmp .L_lambda_simple_end_0528
.L_lambda_simple_code_0528:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0528
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0528:
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
.L_lambda_simple_env_loop_0529:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0529
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0529
.L_lambda_simple_env_end_0529:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0529:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0529
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0529
.L_lambda_simple_params_end_0529:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0529
	jmp .L_lambda_simple_end_0529
.L_lambda_simple_code_0529:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0529
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0529:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_110]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_022f
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_022f
.L_if_else_022f:
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_103]	; free var map
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
	mov rax, qword [free_var_103]	; free var map
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
	push 3	; argc
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
.L_tc_recycle_frame_loop_04ad:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ad
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04ad
.L_tc_recycle_frame_done_04ad:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_022f:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0529:	; new closure is in rax
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
	cmp rsi, 1
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
	mov r8, qword [rsp + 8 * 2]
	mov r9, 3
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_arity_check_exact_0068
	ja .L_lambda_opt_arity_check_more_0068
	push qword [rsp + 8 * 2]
	push 2
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
	lea r10, [rsp + 8 * 2 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 5
	mov rcx, 4 + 2
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
	mov qword [rsp + 8 * 2], 3
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; argc
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
.L_tc_recycle_frame_loop_04ae:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ae
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04ae
.L_tc_recycle_frame_done_04ae:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 3)
.L_lambda_opt_end_0068:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0528:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_85], rax
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
.L_lambda_simple_env_loop_052a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_052a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_052a
.L_lambda_simple_env_end_052a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_052a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_052a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_052a
.L_lambda_simple_params_end_052a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_052a
	jmp .L_lambda_simple_end_052a
.L_lambda_simple_code_052a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_052a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_052a:
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
.L_lambda_simple_env_loop_052b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_052b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_052b
.L_lambda_simple_env_end_052b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_052b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_052b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_052b
.L_lambda_simple_params_end_052b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_052b
	jmp .L_lambda_simple_end_052b
.L_lambda_simple_code_052b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_052b
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_052b:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_110]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0230
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_0230
.L_if_else_0230:
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
	mov rax, qword [free_var_103]	; free var map
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
	mov rax, qword [free_var_103]	; free var map
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_04af:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04af
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04af
.L_tc_recycle_frame_done_04af:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0230:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_052b:	; new closure is in rax
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
	cmp rsi, 1
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
	mov r8, qword [rsp + 8 * 2]
	mov r9, 3
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_arity_check_exact_0069
	ja .L_lambda_opt_arity_check_more_0069
	push qword [rsp + 8 * 2]
	push 2
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
	lea r10, [rsp + 8 * 2 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 5
	mov rcx, 4 + 2
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
	mov qword [rsp + 8 * 2], 3
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; argc
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
.L_tc_recycle_frame_loop_04b0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04b0
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04b0
.L_tc_recycle_frame_done_04b0:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 3)
.L_lambda_opt_end_0069:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_052a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_86], rax
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
.L_lambda_simple_env_loop_052c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_052c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_052c
.L_lambda_simple_env_end_052c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_052c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_052c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_052c
.L_lambda_simple_params_end_052c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_052c
	jmp .L_lambda_simple_end_052c
.L_lambda_simple_code_052c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_052c
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_052c:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 2187
	push rax
	mov rax, L_constants + 2178
	push rax
	push 2	; argc
	mov rax, qword [free_var_82]	; free var error
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
.L_tc_recycle_frame_loop_04b1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04b1
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04b1
.L_tc_recycle_frame_done_04b1:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_052c:	; new closure is in rax
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
.L_lambda_simple_env_loop_052d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_052d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_052d
.L_lambda_simple_env_end_052d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_052d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_052d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_052d
.L_lambda_simple_params_end_052d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_052d
	jmp .L_lambda_simple_end_052d
.L_lambda_simple_code_052d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_052d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_052d:
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
.L_lambda_simple_env_loop_052e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_052e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_052e
.L_lambda_simple_env_end_052e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_052e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_052e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_052e
.L_lambda_simple_params_end_052e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_052e
	jmp .L_lambda_simple_end_052e
.L_lambda_simple_code_052e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_052e
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_052e:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_023c
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0233
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04b3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04b3
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04b3
.L_tc_recycle_frame_done_04b3:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0233
.L_if_else_0233:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0232
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_04b4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04b4
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04b4
.L_tc_recycle_frame_done_04b4:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0232
.L_if_else_0232:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0231
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04b5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04b5
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04b5
.L_tc_recycle_frame_done_04b5:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0231
.L_if_else_0231:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_04b6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04b6
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04b6
.L_tc_recycle_frame_done_04b6:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0231:
.L_if_end_0232:
.L_if_end_0233:
	jmp .L_if_end_023c
.L_if_else_023c:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_023b
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0236
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_04b7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04b7
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04b7
.L_tc_recycle_frame_done_04b7:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0236
.L_if_else_0236:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0235
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04b8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04b8
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04b8
.L_tc_recycle_frame_done_04b8:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0235
.L_if_else_0235:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0234
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04b9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04b9
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04b9
.L_tc_recycle_frame_done_04b9:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0234
.L_if_else_0234:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_04ba:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ba
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04ba
.L_tc_recycle_frame_done_04ba:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0234:
.L_if_end_0235:
.L_if_end_0236:
	jmp .L_if_end_023b
.L_if_else_023b:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_023a
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0239
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04bb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04bb
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04bb
.L_tc_recycle_frame_done_04bb:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0239
.L_if_else_0239:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0238
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04bc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04bc
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04bc
.L_tc_recycle_frame_done_04bc:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0238
.L_if_else_0238:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0237
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04bd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04bd
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04bd
.L_tc_recycle_frame_done_04bd:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0237
.L_if_else_0237:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_04be:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04be
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04be
.L_tc_recycle_frame_done_04be:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0237:
.L_if_end_0238:
.L_if_end_0239:
	jmp .L_if_end_023a
.L_if_else_023a:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_04bf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04bf
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04bf
.L_tc_recycle_frame_done_04bf:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_023a:
.L_if_end_023b:
.L_if_end_023c:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_052e:	; new closure is in rax
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_052f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_052f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_052f
.L_lambda_simple_env_end_052f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_052f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_052f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_052f
.L_lambda_simple_params_end_052f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_052f
	jmp .L_lambda_simple_end_052f
.L_lambda_simple_code_052f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_052f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_052f:
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
.L_lambda_opt_env_loop_006a:
	cmp rsi, 2
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
	cmp rsi, 1
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
	mov r8, qword [rsp + 8 * 2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_006a
	ja .L_lambda_opt_arity_check_more_006a
	push qword [rsp + 8 * 2]
	push 0
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
	lea r10, [rsp + 8 * 0 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
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
	mov qword [rsp + 8 * 2], 1
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
	push 3	; argc
	mov rax, qword [free_var_85]	; free var fold-left
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
.L_tc_recycle_frame_loop_04c0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c0
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04c0
.L_tc_recycle_frame_done_04c0:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_006a:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_052f:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_04b2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04b2
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04b2
.L_tc_recycle_frame_done_04b2:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_052d:	; new closure is in rax
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
.L_lambda_simple_env_loop_0530:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0530
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0530
.L_lambda_simple_env_end_0530:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0530:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0530
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0530
.L_lambda_simple_params_end_0530:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0530
	jmp .L_lambda_simple_end_0530
.L_lambda_simple_code_0530:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0530
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0530:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 2187
	push rax
	mov rax, L_constants + 2251
	push rax
	push 2	; argc
	mov rax, qword [free_var_82]	; free var error
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
.L_tc_recycle_frame_loop_04c1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c1
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04c1
.L_tc_recycle_frame_done_04c1:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0530:	; new closure is in rax
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
.L_lambda_simple_env_loop_0531:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0531
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0531
.L_lambda_simple_env_end_0531:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0531:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0531
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0531
.L_lambda_simple_params_end_0531:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0531
	jmp .L_lambda_simple_end_0531
.L_lambda_simple_code_0531:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0531
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0531:
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
.L_lambda_simple_env_loop_0532:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0532
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0532
.L_lambda_simple_env_end_0532:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0532:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0532
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0532
.L_lambda_simple_params_end_0532:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0532
	jmp .L_lambda_simple_end_0532
.L_lambda_simple_code_0532:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0532
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0532:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0248
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_023f
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04c3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c3
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04c3
.L_tc_recycle_frame_done_04c3:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_023f
.L_if_else_023f:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_023e
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_04c4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c4
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04c4
.L_tc_recycle_frame_done_04c4:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_023e
.L_if_else_023e:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_115]	; free var real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_023d
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04c5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c5
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04c5
.L_tc_recycle_frame_done_04c5:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_023d
.L_if_else_023d:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_04c6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c6
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04c6
.L_tc_recycle_frame_done_04c6:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_023d:
.L_if_end_023e:
.L_if_end_023f:
	jmp .L_if_end_0248
.L_if_else_0248:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0247
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0242
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_04c7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c7
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04c7
.L_tc_recycle_frame_done_04c7:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0242
.L_if_else_0242:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0241
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04c8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c8
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04c8
.L_tc_recycle_frame_done_04c8:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0241
.L_if_else_0241:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0240
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04c9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c9
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04c9
.L_tc_recycle_frame_done_04c9:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0240
.L_if_else_0240:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_04ca:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ca
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04ca
.L_tc_recycle_frame_done_04ca:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0240:
.L_if_end_0241:
.L_if_end_0242:
	jmp .L_if_end_0247
.L_if_else_0247:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0246
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0245
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04cb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04cb
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04cb
.L_tc_recycle_frame_done_04cb:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0245
.L_if_else_0245:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0244
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04cc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04cc
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04cc
.L_tc_recycle_frame_done_04cc:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0244
.L_if_else_0244:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0243
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04cd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04cd
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04cd
.L_tc_recycle_frame_done_04cd:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0243
.L_if_else_0243:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_04ce:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ce
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04ce
.L_tc_recycle_frame_done_04ce:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0243:
.L_if_end_0244:
.L_if_end_0245:
	jmp .L_if_end_0246
.L_if_else_0246:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_04cf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04cf
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04cf
.L_tc_recycle_frame_done_04cf:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0246:
.L_if_end_0247:
.L_if_end_0248:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0532:	; new closure is in rax
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_0533:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0533
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0533
.L_lambda_simple_env_end_0533:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0533:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0533
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0533
.L_lambda_simple_params_end_0533:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0533
	jmp .L_lambda_simple_end_0533
.L_lambda_simple_code_0533:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0533
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0533:
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
.L_lambda_opt_env_loop_006b:
	cmp rsi, 2
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
	cmp rsi, 1
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
	mov r8, qword [rsp + 8 * 2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_006b
	ja .L_lambda_opt_arity_check_more_006b
	push qword [rsp + 8 * 2]
	push 1
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
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
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
	mov qword [rsp + 8 * 2], 2
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0249
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, L_constants + 2135
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04d0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d0
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04d0
.L_tc_recycle_frame_done_04d0:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0249
.L_if_else_0249:
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
	mov rax, qword [free_var_85]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_0534:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0534
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0534
.L_lambda_simple_env_end_0534:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0534:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0534
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0534
.L_lambda_simple_params_end_0534:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0534
	jmp .L_lambda_simple_end_0534
.L_lambda_simple_code_0534:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0534
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0534:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04d2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d2
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04d2
.L_tc_recycle_frame_done_04d2:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0534:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_04d1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d1
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04d1
.L_tc_recycle_frame_done_04d1:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0249:
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_006b:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0533:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_04c2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c2
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04c2
.L_tc_recycle_frame_done_04c2:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0531:	; new closure is in rax
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
.L_lambda_simple_env_loop_0535:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0535
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0535
.L_lambda_simple_env_end_0535:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0535:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0535
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0535
.L_lambda_simple_params_end_0535:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0535
	jmp .L_lambda_simple_end_0535
.L_lambda_simple_code_0535:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0535
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0535:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 2187
	push rax
	mov rax, L_constants + 2279
	push rax
	push 2	; argc
	mov rax, qword [free_var_82]	; free var error
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
.L_tc_recycle_frame_loop_04d3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d3
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04d3
.L_tc_recycle_frame_done_04d3:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0535:	; new closure is in rax
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
.L_lambda_simple_env_loop_0536:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0536
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0536
.L_lambda_simple_env_end_0536:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0536:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0536
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0536
.L_lambda_simple_params_end_0536:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0536
	jmp .L_lambda_simple_end_0536
.L_lambda_simple_code_0536:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0536
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0536:
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
.L_lambda_simple_env_loop_0537:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0537
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0537
.L_lambda_simple_env_end_0537:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0537:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0537
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0537
.L_lambda_simple_params_end_0537:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0537
	jmp .L_lambda_simple_end_0537
.L_lambda_simple_code_0537:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0537
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0537:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0255
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_024c
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04d5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d5
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04d5
.L_tc_recycle_frame_done_04d5:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_024c
.L_if_else_024c:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_024b
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_04d6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d6
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04d6
.L_tc_recycle_frame_done_04d6:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_024b
.L_if_else_024b:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_024a
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04d7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d7
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04d7
.L_tc_recycle_frame_done_04d7:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_024a
.L_if_else_024a:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_04d8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d8
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04d8
.L_tc_recycle_frame_done_04d8:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_024a:
.L_if_end_024b:
.L_if_end_024c:
	jmp .L_if_end_0255
.L_if_else_0255:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0254
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_024f
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_04d9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d9
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04d9
.L_tc_recycle_frame_done_04d9:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_024f
.L_if_else_024f:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_024e
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04da:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04da
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04da
.L_tc_recycle_frame_done_04da:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_024e
.L_if_else_024e:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_024d
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04db:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04db
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04db
.L_tc_recycle_frame_done_04db:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_024d
.L_if_else_024d:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_04dc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04dc
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04dc
.L_tc_recycle_frame_done_04dc:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_024d:
.L_if_end_024e:
.L_if_end_024f:
	jmp .L_if_end_0254
.L_if_else_0254:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0253
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0252
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04dd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04dd
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04dd
.L_tc_recycle_frame_done_04dd:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0252
.L_if_else_0252:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0251
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04de:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04de
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04de
.L_tc_recycle_frame_done_04de:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0251
.L_if_else_0251:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0250
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04df:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04df
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04df
.L_tc_recycle_frame_done_04df:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0250
.L_if_else_0250:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_04e0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e0
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04e0
.L_tc_recycle_frame_done_04e0:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0250:
.L_if_end_0251:
.L_if_end_0252:
	jmp .L_if_end_0253
.L_if_else_0253:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_04e1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e1
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04e1
.L_tc_recycle_frame_done_04e1:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0253:
.L_if_end_0254:
.L_if_end_0255:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0537:	; new closure is in rax
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_0538:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0538
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0538
.L_lambda_simple_env_end_0538:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0538:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0538
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0538
.L_lambda_simple_params_end_0538:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0538
	jmp .L_lambda_simple_end_0538
.L_lambda_simple_code_0538:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0538
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0538:
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
.L_lambda_opt_env_loop_006c:
	cmp rsi, 2
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
	cmp rsi, 1
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
	mov r8, qword [rsp + 8 * 2]
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
	mov qword [rsp + 8 * 2], 1
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
	push 3	; argc
	mov rax, qword [free_var_85]	; free var fold-left
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
.L_tc_recycle_frame_loop_04e2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e2
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04e2
.L_tc_recycle_frame_done_04e2:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_006c:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0538:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_04d4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d4
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04d4
.L_tc_recycle_frame_done_04d4:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0536:	; new closure is in rax
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
.L_lambda_simple_env_loop_0539:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0539
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0539
.L_lambda_simple_env_end_0539:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0539:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0539
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0539
.L_lambda_simple_params_end_0539:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0539
	jmp .L_lambda_simple_end_0539
.L_lambda_simple_code_0539:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0539
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0539:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 2187
	push rax
	mov rax, L_constants + 2298
	push rax
	push 2	; argc
	mov rax, qword [free_var_82]	; free var error
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
.L_tc_recycle_frame_loop_04e3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e3
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04e3
.L_tc_recycle_frame_done_04e3:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0539:	; new closure is in rax
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
.L_lambda_simple_env_loop_053a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_053a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_053a
.L_lambda_simple_env_end_053a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_053a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_053a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_053a
.L_lambda_simple_params_end_053a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_053a
	jmp .L_lambda_simple_end_053a
.L_lambda_simple_code_053a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_053a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_053a:
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
.L_lambda_simple_env_loop_053b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_053b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_053b
.L_lambda_simple_env_end_053b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_053b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_053b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_053b
.L_lambda_simple_params_end_053b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_053b
	jmp .L_lambda_simple_end_053b
.L_lambda_simple_code_053b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_053b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_053b:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0261
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0258
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04e5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e5
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04e5
.L_tc_recycle_frame_done_04e5:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0258
.L_if_else_0258:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0257
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_04e6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e6
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04e6
.L_tc_recycle_frame_done_04e6:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0257
.L_if_else_0257:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0256
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04e7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e7
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04e7
.L_tc_recycle_frame_done_04e7:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0256
.L_if_else_0256:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_04e8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e8
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04e8
.L_tc_recycle_frame_done_04e8:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0256:
.L_if_end_0257:
.L_if_end_0258:
	jmp .L_if_end_0261
.L_if_else_0261:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0260
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_025b
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_04e9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e9
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04e9
.L_tc_recycle_frame_done_04e9:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_025b
.L_if_else_025b:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_025a
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04ea:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ea
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04ea
.L_tc_recycle_frame_done_04ea:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_025a
.L_if_else_025a:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0259
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04eb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04eb
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04eb
.L_tc_recycle_frame_done_04eb:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0259
.L_if_else_0259:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_04ec:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ec
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04ec
.L_tc_recycle_frame_done_04ec:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0259:
.L_if_end_025a:
.L_if_end_025b:
	jmp .L_if_end_0260
.L_if_else_0260:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_025f
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_025e
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04ed:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ed
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04ed
.L_tc_recycle_frame_done_04ed:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_025e
.L_if_else_025e:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_025d
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04ee:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ee
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04ee
.L_tc_recycle_frame_done_04ee:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_025d
.L_if_else_025d:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_025c
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04ef:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ef
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04ef
.L_tc_recycle_frame_done_04ef:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_025c
.L_if_else_025c:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_04f0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f0
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04f0
.L_tc_recycle_frame_done_04f0:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_025c:
.L_if_end_025d:
.L_if_end_025e:
	jmp .L_if_end_025f
.L_if_else_025f:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_04f1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f1
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04f1
.L_tc_recycle_frame_done_04f1:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_025f:
.L_if_end_0260:
.L_if_end_0261:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_053b:	; new closure is in rax
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_053c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_053c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_053c
.L_lambda_simple_env_end_053c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_053c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_053c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_053c
.L_lambda_simple_params_end_053c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_053c
	jmp .L_lambda_simple_end_053c
.L_lambda_simple_code_053c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_053c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_053c:
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
.L_lambda_opt_env_loop_006d:
	cmp rsi, 2
	je .L_lambda_opt_env_end_006d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_006d
.L_lambda_opt_env_end_006d:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_006d:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_006d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_006d
.L_lambda_opt_params_end_006d:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_006d
	jmp .L_lambda_opt_end_006d
.L_lambda_opt_code_006d:	; body
	mov r8, qword [rsp + 8 * 2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_006d
	ja .L_lambda_opt_arity_check_more_006d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_006d:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0146:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0146
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0146
.L_lambda_opt_stack_shrink_loop_exit_0146:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_0147:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0147
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0147
.L_lambda_opt_stack_shrink_loop_exit_0147:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_006d
.L_lambda_opt_arity_check_exact_006d:
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
.L_lambda_opt_stack_shrink_loop_0145:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0145
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0145
.L_lambda_opt_stack_shrink_loop_exit_0145:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_006d:
	mov qword [rsp + 8 * 2], 2
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0262
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, L_constants + 2270
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04f2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f2
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04f2
.L_tc_recycle_frame_done_04f2:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0262
.L_if_else_0262:
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
	mov rax, qword [free_var_85]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_053d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_053d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_053d
.L_lambda_simple_env_end_053d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_053d:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_053d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_053d
.L_lambda_simple_params_end_053d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_053d
	jmp .L_lambda_simple_end_053d
.L_lambda_simple_code_053d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_053d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_053d:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04f4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f4
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04f4
.L_tc_recycle_frame_done_04f4:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_053d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_04f3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f3
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04f3
.L_tc_recycle_frame_done_04f3:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0262:
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_006d:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_053c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_04e4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e4
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04e4
.L_tc_recycle_frame_done_04e4:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_053a:	; new closure is in rax
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
.L_lambda_simple_env_loop_053e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_053e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_053e
.L_lambda_simple_env_end_053e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_053e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_053e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_053e
.L_lambda_simple_params_end_053e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_053e
	jmp .L_lambda_simple_end_053e
.L_lambda_simple_code_053e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_053e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_053e:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1
	mov rax, qword [free_var_151]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0263
	mov rax, L_constants + 2270
	jmp .L_if_end_0263
.L_if_else_0263:
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
	mov rax, qword [free_var_84]	; free var fact
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04f5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f5
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04f5
.L_tc_recycle_frame_done_04f5:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0263:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_053e:	; new closure is in rax
	mov qword [free_var_84], rax
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
.L_lambda_simple_env_loop_053f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_053f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_053f
.L_lambda_simple_env_end_053f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_053f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_053f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_053f
.L_lambda_simple_params_end_053f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_053f
	jmp .L_lambda_simple_end_053f
.L_lambda_simple_code_053f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_053f
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_053f:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 2408
	push rax
	mov rax, L_constants + 2399
	push rax
	push 2	; argc
	mov rax, qword [free_var_82]	; free var error
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
.L_tc_recycle_frame_loop_04f6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f6
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04f6
.L_tc_recycle_frame_done_04f6:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_053f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0540:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0540
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0540
.L_lambda_simple_env_end_0540:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0540:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0540
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0540
.L_lambda_simple_params_end_0540:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0540
	jmp .L_lambda_simple_end_0540
.L_lambda_simple_code_0540:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0540
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0540:
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
.L_lambda_simple_env_loop_0541:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0541
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0541
.L_lambda_simple_env_end_0541:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0541:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0541
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0541
.L_lambda_simple_params_end_0541:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0541
	jmp .L_lambda_simple_end_0541
.L_lambda_simple_code_0541:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0541
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0541:
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
.L_lambda_simple_env_loop_0542:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0542
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0542
.L_lambda_simple_env_end_0542:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0542:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_0542
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0542
.L_lambda_simple_params_end_0542:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0542
	jmp .L_lambda_simple_end_0542
.L_lambda_simple_code_0542:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0542
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0542:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_026f
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0266
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04f8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f8
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04f8
.L_tc_recycle_frame_done_04f8:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0266
.L_if_else_0266:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0265
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_04f9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f9
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04f9
.L_tc_recycle_frame_done_04f9:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0265
.L_if_else_0265:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0264
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04fa:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04fa
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04fa
.L_tc_recycle_frame_done_04fa:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0264
.L_if_else_0264:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_04fb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04fb
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04fb
.L_tc_recycle_frame_done_04fb:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0264:
.L_if_end_0265:
.L_if_end_0266:
	jmp .L_if_end_026f
.L_if_else_026f:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_026e
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0269
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_04fc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04fc
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04fc
.L_tc_recycle_frame_done_04fc:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0269
.L_if_else_0269:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0268
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04fd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04fd
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04fd
.L_tc_recycle_frame_done_04fd:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0268
.L_if_else_0268:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0267
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_04fe:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04fe
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04fe
.L_tc_recycle_frame_done_04fe:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0267
.L_if_else_0267:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_04ff:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ff
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04ff
.L_tc_recycle_frame_done_04ff:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0267:
.L_if_end_0268:
.L_if_end_0269:
	jmp .L_if_end_026e
.L_if_else_026e:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_026d
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_026c
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_90]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_0500:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0500
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0500
.L_tc_recycle_frame_done_0500:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_026c
.L_if_else_026c:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_026b
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_87]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_0501:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0501
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0501
.L_tc_recycle_frame_done_0501:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_026b
.L_if_else_026b:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_026a
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_0502:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0502
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0502
.L_tc_recycle_frame_done_0502:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_026a
.L_if_else_026a:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_0503:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0503
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0503
.L_tc_recycle_frame_done_0503:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_026a:
.L_if_end_026b:
.L_if_end_026c:
	jmp .L_if_end_026d
.L_if_else_026d:
	;debug: preparing a tail-call
	push 0	; argc
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
.L_tc_recycle_frame_loop_0504:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0504
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0504
.L_tc_recycle_frame_done_0504:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_026d:
.L_if_end_026e:
.L_if_end_026f:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0542:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0541:	; new closure is in rax
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_0543:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0543
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0543
.L_lambda_simple_env_end_0543:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0543:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0543
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0543
.L_lambda_simple_params_end_0543:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0543
	jmp .L_lambda_simple_end_0543
.L_lambda_simple_code_0543:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0543
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0543:
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
	push 1	; argc
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
.L_lambda_simple_env_loop_0544:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0544
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0544
.L_lambda_simple_env_end_0544:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0544:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0544
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0544
.L_lambda_simple_params_end_0544:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0544
	jmp .L_lambda_simple_end_0544
.L_lambda_simple_code_0544:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0544
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0544:
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
	push 1	; argc
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
.L_lambda_simple_env_loop_0545:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0545
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0545
.L_lambda_simple_env_end_0545:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0545:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0545
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0545
.L_lambda_simple_params_end_0545:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0545
	jmp .L_lambda_simple_end_0545
.L_lambda_simple_code_0545:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0545
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0545:
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
.L_lambda_simple_env_loop_0546:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_0546
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0546
.L_lambda_simple_env_end_0546:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0546:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0546
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0546
.L_lambda_simple_params_end_0546:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0546
	jmp .L_lambda_simple_end_0546
.L_lambda_simple_code_0546:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0546
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0546:
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
	push 1	; argc
	mov rax, qword [free_var_106]	; free var not
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
.L_tc_recycle_frame_loop_0508:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0508
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0508
.L_tc_recycle_frame_done_0508:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0546:	; new closure is in rax
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_0547:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_0547
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0547
.L_lambda_simple_env_end_0547:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0547:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0547
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0547
.L_lambda_simple_params_end_0547:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0547
	jmp .L_lambda_simple_end_0547
.L_lambda_simple_code_0547:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0547
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0547:
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
.L_lambda_simple_env_loop_0548:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_0548
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0548
.L_lambda_simple_env_end_0548:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0548:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0548
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0548
.L_lambda_simple_params_end_0548:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0548
	jmp .L_lambda_simple_end_0548
.L_lambda_simple_code_0548:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0548
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0548:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_050a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_050a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_050a
.L_tc_recycle_frame_done_050a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0548:	; new closure is in rax
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_0549:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_0549
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0549
.L_lambda_simple_env_end_0549:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0549:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0549
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0549
.L_lambda_simple_params_end_0549:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0549
	jmp .L_lambda_simple_end_0549
.L_lambda_simple_code_0549:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0549
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0549:
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
.L_lambda_simple_env_loop_054a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_054a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_054a
.L_lambda_simple_env_end_054a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_054a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_054a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_054a
.L_lambda_simple_params_end_054a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_054a
	jmp .L_lambda_simple_end_054a
.L_lambda_simple_code_054a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_054a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_054a:
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
	push 1	; argc
	mov rax, qword [free_var_106]	; free var not
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
.L_tc_recycle_frame_loop_050c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_050c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_050c
.L_tc_recycle_frame_done_050c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_054a:	; new closure is in rax
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_054b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_054b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_054b
.L_lambda_simple_env_end_054b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_054b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_054b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_054b
.L_lambda_simple_params_end_054b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_054b
	jmp .L_lambda_simple_end_054b
.L_lambda_simple_code_054b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_054b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_054b:
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
.L_lambda_simple_env_loop_054c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_054c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_054c
.L_lambda_simple_env_end_054c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_054c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_054c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_054c
.L_lambda_simple_params_end_054c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_054c
	jmp .L_lambda_simple_end_054c
.L_lambda_simple_code_054c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_054c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_054c:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_054d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_054d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_054d
.L_lambda_simple_env_end_054d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_054d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_054d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_054d
.L_lambda_simple_params_end_054d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_054d
	jmp .L_lambda_simple_end_054d
.L_lambda_simple_code_054d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_054d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_054d:
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
.L_lambda_simple_env_loop_054e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 9
	je .L_lambda_simple_env_end_054e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_054e
.L_lambda_simple_env_end_054e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_054e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_054e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_054e
.L_lambda_simple_params_end_054e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_054e
	jmp .L_lambda_simple_end_054e
.L_lambda_simple_code_054e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_054e
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_054e:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_003e
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
	je .L_if_else_0270
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_050f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_050f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_050f
.L_tc_recycle_frame_done_050f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0270
.L_if_else_0270:
	mov rax, L_constants + 2
.L_if_end_0270:
.L_or_end_003e:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_054e:	; new closure is in rax
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
.L_lambda_opt_env_loop_006e:
	cmp rsi, 9
	je .L_lambda_opt_env_end_006e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_006e
.L_lambda_opt_env_end_006e:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_006e:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_006e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_006e
.L_lambda_opt_params_end_006e:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_006e
	jmp .L_lambda_opt_end_006e
.L_lambda_opt_code_006e:	; body
	mov r8, qword [rsp + 8 * 2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_006e
	ja .L_lambda_opt_arity_check_more_006e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_006e:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0149:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0149
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0149
.L_lambda_opt_stack_shrink_loop_exit_0149:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_014a:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_014a
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_014a
.L_lambda_opt_stack_shrink_loop_exit_014a:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_006e
.L_lambda_opt_arity_check_exact_006e:
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
.L_lambda_opt_stack_shrink_loop_0148:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0148
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0148
.L_lambda_opt_stack_shrink_loop_exit_0148:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_006e:
	mov qword [rsp + 8 * 2], 2
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_0510:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0510
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0510
.L_tc_recycle_frame_done_0510:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_006e:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_054d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_050e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_050e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_050e
.L_tc_recycle_frame_done_050e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_054c:	; new closure is in rax
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_054f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_054f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_054f
.L_lambda_simple_env_end_054f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_054f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_054f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_054f
.L_lambda_simple_params_end_054f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_054f
	jmp .L_lambda_simple_end_054f
.L_lambda_simple_code_054f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_054f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_054f:
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
.L_lambda_simple_end_054f:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_050d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_050d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_050d
.L_tc_recycle_frame_done_050d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_054b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_050b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_050b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_050b
.L_tc_recycle_frame_done_050b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0549:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0509:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0509
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0509
.L_tc_recycle_frame_done_0509:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0547:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0507:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0507
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0507
.L_tc_recycle_frame_done_0507:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0545:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0506:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0506
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0506
.L_tc_recycle_frame_done_0506:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0544:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0505:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0505
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0505
.L_tc_recycle_frame_done_0505:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0543:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_04f7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f7
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_04f7
.L_tc_recycle_frame_done_04f7:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0540:	; new closure is in rax
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
.L_lambda_simple_env_loop_0550:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0550
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0550
.L_lambda_simple_env_end_0550:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0550:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0550
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0550
.L_lambda_simple_params_end_0550:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0550
	jmp .L_lambda_simple_end_0550
.L_lambda_simple_code_0550:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0550
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0550:
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
.L_lambda_opt_env_loop_006f:
	cmp rsi, 1
	je .L_lambda_opt_env_end_006f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_006f
.L_lambda_opt_env_end_006f:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_006f:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_006f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_006f
.L_lambda_opt_params_end_006f:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_006f
	jmp .L_lambda_opt_end_006f
.L_lambda_opt_code_006f:	; body
	mov r8, qword [rsp + 8 * 2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_006f
	ja .L_lambda_opt_arity_check_more_006f
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_006f:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_014c:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_014c
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_014c
.L_lambda_opt_stack_shrink_loop_exit_014c:
	lea r10, [rsp + 8 * 0 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_014d:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_014d
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_014d
.L_lambda_opt_stack_shrink_loop_exit_014d:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_006f
.L_lambda_opt_arity_check_exact_006f:
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
.L_lambda_opt_stack_shrink_loop_014b:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_014b
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_014b
.L_lambda_opt_stack_shrink_loop_exit_014b:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_006f:
	mov qword [rsp + 8 * 2], 1
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
	mov rax, qword [free_var_103]	; free var map
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_0511:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0511
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0511
.L_tc_recycle_frame_done_0511:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_006f:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0550:	; new closure is in rax
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
.L_lambda_simple_env_loop_0551:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0551
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0551
.L_lambda_simple_env_end_0551:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0551:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0551
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0551
.L_lambda_simple_params_end_0551:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0551
	jmp .L_lambda_simple_end_0551
.L_lambda_simple_code_0551:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0551
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0551:
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
.L_lambda_simple_end_0551:	; new closure is in rax
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
.L_lambda_simple_env_loop_0552:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0552
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0552
.L_lambda_simple_env_end_0552:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0552:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0552
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0552
.L_lambda_simple_params_end_0552:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0552
	jmp .L_lambda_simple_end_0552
.L_lambda_simple_code_0552:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0552
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0552:
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
.L_lambda_simple_env_loop_0553:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0553
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0553
.L_lambda_simple_env_end_0553:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0553:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0553
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0553
.L_lambda_simple_params_end_0553:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0553
	jmp .L_lambda_simple_end_0553
.L_lambda_simple_code_0553:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0553
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0553:
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
	je .L_if_else_0271
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
	push 1	; argc
	mov rax, qword [free_var_89]	; free var integer->char
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
.L_tc_recycle_frame_loop_0512:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0512
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0512
.L_tc_recycle_frame_done_0512:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0271
.L_if_else_0271:
	mov rax, PARAM(0)	; param ch
.L_if_end_0271:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0553:	; new closure is in rax
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
.L_lambda_simple_env_loop_0554:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0554
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0554
.L_lambda_simple_env_end_0554:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0554:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0554
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0554
.L_lambda_simple_params_end_0554:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0554
	jmp .L_lambda_simple_end_0554
.L_lambda_simple_code_0554:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0554
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0554:
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
	je .L_if_else_0272
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
	push 1	; argc
	mov rax, qword [free_var_89]	; free var integer->char
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
.L_tc_recycle_frame_loop_0513:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0513
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0513
.L_tc_recycle_frame_done_0513:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0272
.L_if_else_0272:
	mov rax, PARAM(0)	; param ch
.L_if_end_0272:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0554:	; new closure is in rax
	mov qword [free_var_72], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0552:	; new closure is in rax
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
.L_lambda_simple_env_loop_0555:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0555
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0555
.L_lambda_simple_env_end_0555:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0555:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0555
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0555
.L_lambda_simple_params_end_0555:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0555
	jmp .L_lambda_simple_end_0555
.L_lambda_simple_code_0555:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0555
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0555:
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
.L_lambda_opt_env_loop_0070:
	cmp rsi, 1
	je .L_lambda_opt_env_end_0070
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0070
.L_lambda_opt_env_end_0070:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0070:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_0070
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0070
.L_lambda_opt_params_end_0070:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0070
	jmp .L_lambda_opt_end_0070
.L_lambda_opt_code_0070:	; body
	mov r8, qword [rsp + 8 * 2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_0070
	ja .L_lambda_opt_arity_check_more_0070
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0070:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_014f:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_014f
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_014f
.L_lambda_opt_stack_shrink_loop_exit_014f:
	lea r10, [rsp + 8 * 0 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_0150:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0150
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0150
.L_lambda_opt_stack_shrink_loop_exit_0150:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0070
.L_lambda_opt_arity_check_exact_0070:
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
.L_lambda_opt_stack_shrink_loop_014e:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_014e
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_014e
.L_lambda_opt_stack_shrink_loop_exit_014e:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0070:
	mov qword [rsp + 8 * 2], 1
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
.L_lambda_simple_env_loop_0556:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0556
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0556
.L_lambda_simple_env_end_0556:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0556:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0556
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0556
.L_lambda_simple_params_end_0556:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0556
	jmp .L_lambda_simple_end_0556
.L_lambda_simple_code_0556:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0556
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0556:
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0515:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0515
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0515
.L_tc_recycle_frame_done_0515:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0556:	; new closure is in rax
	push rax
	push 2
	mov rax, qword [free_var_103]	; free var map
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_0514:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0514
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0514
.L_tc_recycle_frame_done_0514:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_0070:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0555:	; new closure is in rax
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
.L_lambda_simple_env_loop_0557:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0557
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0557
.L_lambda_simple_env_end_0557:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0557:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0557
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0557
.L_lambda_simple_params_end_0557:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0557
	jmp .L_lambda_simple_end_0557
.L_lambda_simple_code_0557:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0557
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0557:
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
.L_lambda_simple_end_0557:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_126], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_132], rax
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
.L_lambda_simple_env_loop_0558:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0558
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0558
.L_lambda_simple_env_end_0558:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0558:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0558
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0558
.L_lambda_simple_params_end_0558:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0558
	jmp .L_lambda_simple_end_0558
.L_lambda_simple_code_0558:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0558
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0558:
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
.L_lambda_simple_env_loop_0559:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0559
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0559
.L_lambda_simple_env_end_0559:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0559:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0559
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0559
.L_lambda_simple_params_end_0559:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0559
	jmp .L_lambda_simple_end_0559
.L_lambda_simple_code_0559:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0559
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0559:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1
	mov rax, qword [free_var_119]	; free var string->list
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
	mov rax, qword [free_var_103]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	mov rax, qword [free_var_94]	; free var list->string
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
.L_tc_recycle_frame_loop_0516:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0516
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0516
.L_tc_recycle_frame_done_0516:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0559:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0558:	; new closure is in rax
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
.L_lambda_simple_env_loop_055a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_055a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_055a
.L_lambda_simple_env_end_055a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_055a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_055a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_055a
.L_lambda_simple_params_end_055a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_055a
	jmp .L_lambda_simple_end_055a
.L_lambda_simple_code_055a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_055a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_055a:
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
	mov qword [free_var_126], rax
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
	mov qword [free_var_132], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_055a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_134], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_133], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_135], rax
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
	mov qword [free_var_122], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_121], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_123], rax
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
.L_lambda_simple_env_loop_055b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_055b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_055b
.L_lambda_simple_env_end_055b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_055b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_055b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_055b
.L_lambda_simple_params_end_055b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_055b
	jmp .L_lambda_simple_end_055b
.L_lambda_simple_code_055b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_055b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_055b:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_055c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_055c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_055c
.L_lambda_simple_env_end_055c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_055c:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_055c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_055c
.L_lambda_simple_params_end_055c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_055c
	jmp .L_lambda_simple_end_055c
.L_lambda_simple_code_055c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_055c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_055c:
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
.L_lambda_simple_env_loop_055d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_055d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_055d
.L_lambda_simple_env_end_055d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_055d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_055d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_055d
.L_lambda_simple_params_end_055d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_055d
	jmp .L_lambda_simple_end_055d
.L_lambda_simple_code_055d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_055d
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_055d:
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
	je .L_if_else_0273
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
	jmp .L_if_end_0273
.L_if_else_0273:
	mov rax, L_constants + 2
.L_if_end_0273:
	cmp rax, sob_boolean_false
	jne .L_or_end_003f
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
	je .L_if_else_0275
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2
	mov rax, qword [free_var_128]	; free var string-ref
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
	mov rax, qword [free_var_128]	; free var string-ref
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
	jne .L_or_end_0040
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2
	mov rax, qword [free_var_128]	; free var string-ref
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
	mov rax, qword [free_var_128]	; free var string-ref
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
	je .L_if_else_0274
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
	push 5	; argc
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
.L_tc_recycle_frame_loop_0518:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0518
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0518
.L_tc_recycle_frame_done_0518:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0274
.L_if_else_0274:
	mov rax, L_constants + 2
.L_if_end_0274:
.L_or_end_0040:
	jmp .L_if_end_0275
.L_if_else_0275:
	mov rax, L_constants + 2
.L_if_end_0275:
.L_or_end_003f:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_055d:	; new closure is in rax
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
.L_lambda_simple_env_loop_055e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_055e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_055e
.L_lambda_simple_env_end_055e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_055e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_055e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_055e
.L_lambda_simple_params_end_055e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_055e
	jmp .L_lambda_simple_end_055e
.L_lambda_simple_code_055e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_055e
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_055e:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1
	mov rax, qword [free_var_127]	; free var string-length
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
	mov rax, qword [free_var_127]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; argc
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
.L_lambda_simple_env_loop_055f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_055f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_055f
.L_lambda_simple_env_end_055f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_055f:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_055f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_055f
.L_lambda_simple_params_end_055f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_055f
	jmp .L_lambda_simple_end_055f
.L_lambda_simple_code_055f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_055f
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_055f:
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
	je .L_if_else_0276
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
	push 5	; argc
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
.L_tc_recycle_frame_loop_051b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_051b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_051b
.L_tc_recycle_frame_done_051b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0276
.L_if_else_0276:
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
	push 5	; argc
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
.L_tc_recycle_frame_loop_051c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_051c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_051c
.L_tc_recycle_frame_done_051c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0276:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_055f:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_051a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_051a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_051a
.L_tc_recycle_frame_done_051a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_055e:	; new closure is in rax
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_0560:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0560
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0560
.L_lambda_simple_env_end_0560:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0560:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0560
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0560
.L_lambda_simple_params_end_0560:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0560
	jmp .L_lambda_simple_end_0560
.L_lambda_simple_code_0560:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0560
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0560:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_0561:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0561
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0561
.L_lambda_simple_env_end_0561:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0561:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0561
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0561
.L_lambda_simple_params_end_0561:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0561
	jmp .L_lambda_simple_end_0561
.L_lambda_simple_code_0561:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0561
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0561:
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
.L_lambda_simple_env_loop_0562:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_0562
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0562
.L_lambda_simple_env_end_0562:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0562:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0562
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0562
.L_lambda_simple_params_end_0562:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0562
	jmp .L_lambda_simple_end_0562
.L_lambda_simple_code_0562:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0562
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0562:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0041
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
	je .L_if_else_0277
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_051e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_051e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_051e
.L_tc_recycle_frame_done_051e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0277
.L_if_else_0277:
	mov rax, L_constants + 2
.L_if_end_0277:
.L_or_end_0041:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0562:	; new closure is in rax
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
.L_lambda_opt_env_loop_0071:
	cmp rsi, 4
	je .L_lambda_opt_env_end_0071
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0071
.L_lambda_opt_env_end_0071:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0071:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_0071
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0071
.L_lambda_opt_params_end_0071:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0071
	jmp .L_lambda_opt_end_0071
.L_lambda_opt_code_0071:	; body
	mov r8, qword [rsp + 8 * 2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0071
	ja .L_lambda_opt_arity_check_more_0071
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0071:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0152:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0152
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0152
.L_lambda_opt_stack_shrink_loop_exit_0152:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_0153:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0153
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0153
.L_lambda_opt_stack_shrink_loop_exit_0153:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0071
.L_lambda_opt_arity_check_exact_0071:
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
.L_lambda_opt_stack_shrink_loop_0151:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0151
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0151
.L_lambda_opt_stack_shrink_loop_exit_0151:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0071:
	mov qword [rsp + 8 * 2], 2
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_051f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_051f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_051f
.L_tc_recycle_frame_done_051f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0071:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0561:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_051d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_051d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_051d
.L_tc_recycle_frame_done_051d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0560:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0519:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0519
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0519
.L_tc_recycle_frame_done_0519:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_055c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0517:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0517
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0517
.L_tc_recycle_frame_done_0517:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_055b:	; new closure is in rax
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
.L_lambda_simple_env_loop_0563:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0563
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0563
.L_lambda_simple_env_end_0563:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0563:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0563
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0563
.L_lambda_simple_params_end_0563:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0563
	jmp .L_lambda_simple_end_0563
.L_lambda_simple_code_0563:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0563
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0563:
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
	mov rax, PARAM(0)	; param make-string<?
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
	mov rax, PARAM(0)	; param make-string<?
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
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_125], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0563:	; new closure is in rax
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
.L_lambda_simple_env_loop_0564:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0564
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0564
.L_lambda_simple_env_end_0564:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0564:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0564
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0564
.L_lambda_simple_params_end_0564:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0564
	jmp .L_lambda_simple_end_0564
.L_lambda_simple_code_0564:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0564
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0564:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_0565:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0565
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0565
.L_lambda_simple_env_end_0565:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0565:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0565
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0565
.L_lambda_simple_params_end_0565:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0565
	jmp .L_lambda_simple_end_0565
.L_lambda_simple_code_0565:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0565
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0565:
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
.L_lambda_simple_env_loop_0566:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0566
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0566
.L_lambda_simple_env_end_0566:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0566:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0566
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0566
.L_lambda_simple_params_end_0566:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0566
	jmp .L_lambda_simple_end_0566
.L_lambda_simple_code_0566:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0566
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0566:
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
	jne .L_or_end_0042
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2
	mov rax, qword [free_var_128]	; free var string-ref
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
	mov rax, qword [free_var_128]	; free var string-ref
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
	jne .L_or_end_0042
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
	je .L_if_else_0279
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2
	mov rax, qword [free_var_128]	; free var string-ref
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
	mov rax, qword [free_var_128]	; free var string-ref
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
	je .L_if_else_0278
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
	push 5	; argc
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
.L_tc_recycle_frame_loop_0521:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0521
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0521
.L_tc_recycle_frame_done_0521:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0278
.L_if_else_0278:
	mov rax, L_constants + 2
.L_if_end_0278:
	jmp .L_if_end_0279
.L_if_else_0279:
	mov rax, L_constants + 2
.L_if_end_0279:
.L_or_end_0042:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_0566:	; new closure is in rax
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
.L_lambda_simple_env_loop_0567:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0567
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0567
.L_lambda_simple_env_end_0567:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0567:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0567
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0567
.L_lambda_simple_params_end_0567:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0567
	jmp .L_lambda_simple_end_0567
.L_lambda_simple_code_0567:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0567
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0567:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1
	mov rax, qword [free_var_127]	; free var string-length
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
	mov rax, qword [free_var_127]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; argc
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
.L_lambda_simple_env_loop_0568:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0568
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0568
.L_lambda_simple_env_end_0568:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0568:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0568
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0568
.L_lambda_simple_params_end_0568:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0568
	jmp .L_lambda_simple_end_0568
.L_lambda_simple_code_0568:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0568
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0568:
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
	je .L_if_else_027a
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
	push 5	; argc
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
.L_tc_recycle_frame_loop_0524:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0524
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0524
.L_tc_recycle_frame_done_0524:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_027a
.L_if_else_027a:
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
	push 5	; argc
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
.L_tc_recycle_frame_loop_0525:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0525
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0525
.L_tc_recycle_frame_done_0525:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_027a:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0568:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0523:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0523
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0523
.L_tc_recycle_frame_done_0523:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0567:	; new closure is in rax
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_0569:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0569
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0569
.L_lambda_simple_env_end_0569:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0569:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0569
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0569
.L_lambda_simple_params_end_0569:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0569
	jmp .L_lambda_simple_end_0569
.L_lambda_simple_code_0569:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0569
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0569:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_056a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_056a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_056a
.L_lambda_simple_env_end_056a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_056a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_056a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_056a
.L_lambda_simple_params_end_056a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_056a
	jmp .L_lambda_simple_end_056a
.L_lambda_simple_code_056a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_056a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_056a:
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
.L_lambda_simple_env_loop_056b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_056b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_056b
.L_lambda_simple_env_end_056b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_056b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_056b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_056b
.L_lambda_simple_params_end_056b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_056b
	jmp .L_lambda_simple_end_056b
.L_lambda_simple_code_056b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_056b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_056b:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0043
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
	je .L_if_else_027b
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_0527:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0527
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0527
.L_tc_recycle_frame_done_0527:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_027b
.L_if_else_027b:
	mov rax, L_constants + 2
.L_if_end_027b:
.L_or_end_0043:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_056b:	; new closure is in rax
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
.L_lambda_opt_env_loop_0072:
	cmp rsi, 4
	je .L_lambda_opt_env_end_0072
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0072
.L_lambda_opt_env_end_0072:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0072:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_0072
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0072
.L_lambda_opt_params_end_0072:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0072
	jmp .L_lambda_opt_end_0072
.L_lambda_opt_code_0072:	; body
	mov r8, qword [rsp + 8 * 2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0072
	ja .L_lambda_opt_arity_check_more_0072
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0072:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0155:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0155
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0155
.L_lambda_opt_stack_shrink_loop_exit_0155:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_0156:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0156
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0156
.L_lambda_opt_stack_shrink_loop_exit_0156:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0072
.L_lambda_opt_arity_check_exact_0072:
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
.L_lambda_opt_stack_shrink_loop_0154:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0154
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0154
.L_lambda_opt_stack_shrink_loop_exit_0154:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0072:
	mov qword [rsp + 8 * 2], 2
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_0528:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0528
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0528
.L_tc_recycle_frame_done_0528:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0072:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_056a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0526:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0526
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0526
.L_tc_recycle_frame_done_0526:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0569:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0522:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0522
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0522
.L_tc_recycle_frame_done_0522:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0565:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0520:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0520
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0520
.L_tc_recycle_frame_done_0520:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0564:	; new closure is in rax
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
.L_lambda_simple_env_loop_056c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_056c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_056c
.L_lambda_simple_env_end_056c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_056c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_056c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_056c
.L_lambda_simple_params_end_056c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_056c
	jmp .L_lambda_simple_end_056c
.L_lambda_simple_code_056c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_056c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_056c:
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
	mov qword [free_var_133], rax
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
	mov qword [free_var_121], rax
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
	mov qword [free_var_136], rax
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
	mov qword [free_var_124], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_056c:	; new closure is in rax
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
.L_lambda_simple_env_loop_056d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_056d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_056d
.L_lambda_simple_env_end_056d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_056d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_056d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_056d
.L_lambda_simple_params_end_056d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_056d
	jmp .L_lambda_simple_end_056d
.L_lambda_simple_code_056d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_056d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_056d:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_056e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_056e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_056e
.L_lambda_simple_env_end_056e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_056e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_056e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_056e
.L_lambda_simple_params_end_056e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_056e
	jmp .L_lambda_simple_end_056e
.L_lambda_simple_code_056e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_056e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_056e:
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
.L_lambda_simple_env_loop_056f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_056f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_056f
.L_lambda_simple_env_end_056f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_056f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_056f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_056f
.L_lambda_simple_params_end_056f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_056f
	jmp .L_lambda_simple_end_056f
.L_lambda_simple_code_056f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 4
	je .L_lambda_simple_arity_check_ok_056f
	push qword [rsp + 8 * 2]
	push 4
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_056f:
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
	jne .L_or_end_0044
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
	je .L_if_else_027d
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(2)	; param str2
	push rax
	push 2
	mov rax, qword [free_var_128]	; free var string-ref
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
	mov rax, qword [free_var_128]	; free var string-ref
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
	je .L_if_else_027c
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
	push 4	; argc
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
.L_tc_recycle_frame_loop_052a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_052a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_052a
.L_tc_recycle_frame_done_052a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_027c
.L_if_else_027c:
	mov rax, L_constants + 2
.L_if_end_027c:
	jmp .L_if_end_027d
.L_if_else_027d:
	mov rax, L_constants + 2
.L_if_end_027d:
.L_or_end_0044:
	leave
	ret AND_KILL_FRAME(4)
.L_lambda_simple_end_056f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0570:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0570
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0570
.L_lambda_simple_env_end_0570:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0570:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0570
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0570
.L_lambda_simple_params_end_0570:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0570
	jmp .L_lambda_simple_end_0570
.L_lambda_simple_code_0570:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0570
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0570:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1
	mov rax, qword [free_var_127]	; free var string-length
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
	mov rax, qword [free_var_127]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; argc
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
.L_lambda_simple_env_loop_0571:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0571
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0571
.L_lambda_simple_env_end_0571:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0571:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0571
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0571
.L_lambda_simple_params_end_0571:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0571
	jmp .L_lambda_simple_end_0571
.L_lambda_simple_code_0571:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0571
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0571:
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
	je .L_if_else_027e
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
	push 4	; argc
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
.L_tc_recycle_frame_loop_052d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_052d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_052d
.L_tc_recycle_frame_done_052d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_027e
.L_if_else_027e:
	mov rax, L_constants + 2
.L_if_end_027e:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0571:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_052c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_052c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_052c
.L_tc_recycle_frame_done_052c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0570:	; new closure is in rax
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_0572:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0572
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0572
.L_lambda_simple_env_end_0572:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0572:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0572
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0572
.L_lambda_simple_params_end_0572:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0572
	jmp .L_lambda_simple_end_0572
.L_lambda_simple_code_0572:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0572
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0572:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_0573:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0573
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0573
.L_lambda_simple_env_end_0573:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0573:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0573
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0573
.L_lambda_simple_params_end_0573:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0573
	jmp .L_lambda_simple_end_0573
.L_lambda_simple_code_0573:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0573
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0573:
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
.L_lambda_simple_env_loop_0574:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_0574
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0574
.L_lambda_simple_env_end_0574:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0574:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0574
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0574
.L_lambda_simple_params_end_0574:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0574
	jmp .L_lambda_simple_end_0574
.L_lambda_simple_code_0574:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0574
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0574:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0045
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
	je .L_if_else_027f
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_052f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_052f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_052f
.L_tc_recycle_frame_done_052f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_027f
.L_if_else_027f:
	mov rax, L_constants + 2
.L_if_end_027f:
.L_or_end_0045:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0574:	; new closure is in rax
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
.L_lambda_opt_env_loop_0073:
	cmp rsi, 4
	je .L_lambda_opt_env_end_0073
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0073
.L_lambda_opt_env_end_0073:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0073:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_0073
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0073
.L_lambda_opt_params_end_0073:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0073
	jmp .L_lambda_opt_end_0073
.L_lambda_opt_code_0073:	; body
	mov r8, qword [rsp + 8 * 2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0073
	ja .L_lambda_opt_arity_check_more_0073
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0073:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0158:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0158
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0158
.L_lambda_opt_stack_shrink_loop_exit_0158:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_0159:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0159
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0159
.L_lambda_opt_stack_shrink_loop_exit_0159:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0073
.L_lambda_opt_arity_check_exact_0073:
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
.L_lambda_opt_stack_shrink_loop_0157:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0157
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0157
.L_lambda_opt_stack_shrink_loop_exit_0157:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0073:
	mov qword [rsp + 8 * 2], 2
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_0530:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0530
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0530
.L_tc_recycle_frame_done_0530:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0073:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0573:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_052e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_052e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_052e
.L_tc_recycle_frame_done_052e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0572:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_052b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_052b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_052b
.L_tc_recycle_frame_done_052b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_056e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0529:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0529
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0529
.L_tc_recycle_frame_done_0529:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_056d:	; new closure is in rax
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
.L_lambda_simple_env_loop_0575:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0575
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0575
.L_lambda_simple_env_end_0575:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0575:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0575
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0575
.L_lambda_simple_params_end_0575:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0575
	jmp .L_lambda_simple_end_0575
.L_lambda_simple_code_0575:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0575
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0575:
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
	mov qword [free_var_135], rax
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
	mov qword [free_var_123], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0575:	; new closure is in rax
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
.L_lambda_simple_env_loop_0576:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0576
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0576
.L_lambda_simple_env_end_0576:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0576:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0576
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0576
.L_lambda_simple_params_end_0576:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0576
	jmp .L_lambda_simple_end_0576
.L_lambda_simple_code_0576:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0576
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0576:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0046
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0280
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
	push 1	; argc
	mov rax, qword [free_var_96]	; free var list?
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
.L_tc_recycle_frame_loop_0531:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0531
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0531
.L_tc_recycle_frame_done_0531:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0280
.L_if_else_0280:
	mov rax, L_constants + 2
.L_if_end_0280:
.L_or_end_0046:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0576:	; new closure is in rax
	mov qword [free_var_96], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, qword [free_var_101]	; free var make-vector
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
.L_lambda_simple_env_loop_0577:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0577
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0577
.L_lambda_simple_env_end_0577:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0577:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0577
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0577
.L_lambda_simple_params_end_0577:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0577
	jmp .L_lambda_simple_end_0577
.L_lambda_simple_code_0577:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0577
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0577:
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
.L_lambda_opt_env_loop_0074:
	cmp rsi, 1
	je .L_lambda_opt_env_end_0074
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0074
.L_lambda_opt_env_end_0074:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0074:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_0074
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0074
.L_lambda_opt_params_end_0074:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0074
	jmp .L_lambda_opt_end_0074
.L_lambda_opt_code_0074:	; body
	mov r8, qword [rsp + 8 * 2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0074
	ja .L_lambda_opt_arity_check_more_0074
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0074:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_015b:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_015b
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_015b
.L_lambda_opt_stack_shrink_loop_exit_015b:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_015c:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_015c
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_015c
.L_lambda_opt_stack_shrink_loop_exit_015c:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0074
.L_lambda_opt_arity_check_exact_0074:
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
.L_lambda_opt_stack_shrink_loop_015a:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_015a
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_015a
.L_lambda_opt_stack_shrink_loop_exit_015a:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0074:
	mov qword [rsp + 8 * 2], 2
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0283
	mov rax, L_constants + 0
	jmp .L_if_end_0283
.L_if_else_0283:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0281
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
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0281
.L_if_else_0281:
	mov rax, L_constants + 2
.L_if_end_0281:
	cmp rax, sob_boolean_false
	je .L_if_else_0282
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
	jmp .L_if_end_0282
.L_if_else_0282:
	; preparing a non-tail-call
	mov rax, L_constants + 2955
	push rax
	mov rax, L_constants + 2946
	push rax
	push 2
	mov rax, qword [free_var_82]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
.L_if_end_0282:
.L_if_end_0283:
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_0578:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0578
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0578
.L_lambda_simple_env_end_0578:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0578:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0578
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0578
.L_lambda_simple_params_end_0578:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0578
	jmp .L_lambda_simple_end_0578
.L_lambda_simple_code_0578:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0578
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0578:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_0533:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0533
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0533
.L_tc_recycle_frame_done_0533:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0578:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0532:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0532
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0532
.L_tc_recycle_frame_done_0532:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0074:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0577:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_101], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, qword [free_var_99]	; free var make-string
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
.L_lambda_simple_env_loop_0579:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0579
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0579
.L_lambda_simple_env_end_0579:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0579:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0579
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0579
.L_lambda_simple_params_end_0579:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0579
	jmp .L_lambda_simple_end_0579
.L_lambda_simple_code_0579:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0579
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0579:
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
.L_lambda_opt_env_loop_0075:
	cmp rsi, 1
	je .L_lambda_opt_env_end_0075
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0075
.L_lambda_opt_env_end_0075:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0075:	; copying parameters
	cmp rsi, 1
	je .L_lambda_opt_params_end_0075
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0075
.L_lambda_opt_params_end_0075:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0075
	jmp .L_lambda_opt_end_0075
.L_lambda_opt_code_0075:	; body
	mov r8, qword [rsp + 8 * 2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_0075
	ja .L_lambda_opt_arity_check_more_0075
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0075:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_015e:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_015e
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_015e
.L_lambda_opt_stack_shrink_loop_exit_015e:
	lea r10, [rsp + 8 * 1 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_015f:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_015f
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_015f
.L_lambda_opt_stack_shrink_loop_exit_015f:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0075
.L_lambda_opt_arity_check_exact_0075:
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
.L_lambda_opt_stack_shrink_loop_015d:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_015d
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_015d
.L_lambda_opt_stack_shrink_loop_exit_015d:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0075:
	mov qword [rsp + 8 * 2], 2
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0286
	mov rax, L_constants + 4
	jmp .L_if_end_0286
.L_if_else_0286:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0284
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
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0284
.L_if_else_0284:
	mov rax, L_constants + 2
.L_if_end_0284:
	cmp rax, sob_boolean_false
	je .L_if_else_0285
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
	jmp .L_if_end_0285
.L_if_else_0285:
	; preparing a non-tail-call
	mov rax, L_constants + 3016
	push rax
	mov rax, L_constants + 3007
	push rax
	push 2
	mov rax, qword [free_var_82]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
.L_if_end_0285:
.L_if_end_0286:
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_057a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_057a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_057a
.L_lambda_simple_env_end_057a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_057a:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_057a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_057a
.L_lambda_simple_params_end_057a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_057a
	jmp .L_lambda_simple_end_057a
.L_lambda_simple_code_057a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_057a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_057a:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_0535:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0535
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0535
.L_tc_recycle_frame_done_0535:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_057a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0534:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0534
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0534
.L_tc_recycle_frame_done_0534:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_0075:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0579:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_99], rax
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
.L_lambda_simple_env_loop_057b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_057b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_057b
.L_lambda_simple_env_end_057b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_057b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_057b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_057b
.L_lambda_simple_params_end_057b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_057b
	jmp .L_lambda_simple_end_057b
.L_lambda_simple_code_057b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_057b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_057b:
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
.L_lambda_simple_env_loop_057c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_057c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_057c
.L_lambda_simple_env_end_057c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_057c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_057c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_057c
.L_lambda_simple_params_end_057c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_057c
	jmp .L_lambda_simple_end_057c
.L_lambda_simple_code_057c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_057c
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_057c:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0287
	;debug: preparing a tail-call
	mov rax, L_constants + 0
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; argc
	mov rax, qword [free_var_101]	; free var make-vector
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
.L_tc_recycle_frame_loop_0536:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0536
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0536
.L_tc_recycle_frame_done_0536:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0287
.L_if_else_0287:
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
	push 1	; argc
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
.L_lambda_simple_env_loop_057d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_057d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_057d
.L_lambda_simple_env_end_057d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_057d:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_057d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_057d
.L_lambda_simple_params_end_057d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_057d
	jmp .L_lambda_simple_end_057d
.L_lambda_simple_code_057d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_057d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_057d:
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
	mov rax, qword [free_var_147]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param v
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_057d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0537:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0537
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0537
.L_tc_recycle_frame_done_0537:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0287:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_057c:	; new closure is in rax
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
.L_lambda_simple_env_loop_057e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_057e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_057e
.L_lambda_simple_env_end_057e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_057e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_057e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_057e
.L_lambda_simple_params_end_057e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_057e
	jmp .L_lambda_simple_end_057e
.L_lambda_simple_code_057e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_057e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_057e:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_0538:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0538
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0538
.L_tc_recycle_frame_done_0538:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_057e:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_057b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_95], rax
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
.L_lambda_simple_env_loop_057f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_057f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_057f
.L_lambda_simple_env_end_057f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_057f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_057f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_057f
.L_lambda_simple_params_end_057f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_057f
	jmp .L_lambda_simple_end_057f
.L_lambda_simple_code_057f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_057f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_057f:
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
.L_lambda_simple_env_loop_0580:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0580
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0580
.L_lambda_simple_env_end_0580:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0580:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0580
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0580
.L_lambda_simple_params_end_0580:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0580
	jmp .L_lambda_simple_end_0580
.L_lambda_simple_code_0580:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0580
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0580:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0288
	;debug: preparing a tail-call
	mov rax, L_constants + 4
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; argc
	mov rax, qword [free_var_99]	; free var make-string
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
.L_tc_recycle_frame_loop_0539:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0539
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0539
.L_tc_recycle_frame_done_0539:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0288
.L_if_else_0288:
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
	push 1	; argc
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
.L_lambda_simple_env_loop_0581:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0581
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0581
.L_lambda_simple_env_end_0581:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0581:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0581
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0581
.L_lambda_simple_params_end_0581:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0581
	jmp .L_lambda_simple_end_0581
.L_lambda_simple_code_0581:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0581
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0581:
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
	mov rax, qword [free_var_131]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param str
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0581:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_053a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_053a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_053a
.L_tc_recycle_frame_done_053a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0288:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0580:	; new closure is in rax
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
.L_lambda_simple_env_loop_0582:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0582
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0582
.L_lambda_simple_env_end_0582:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0582:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0582
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0582
.L_lambda_simple_params_end_0582:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0582
	jmp .L_lambda_simple_end_0582
.L_lambda_simple_code_0582:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0582
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0582:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_053b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_053b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_053b
.L_tc_recycle_frame_done_053b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0582:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_057f:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_94], rax
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
.L_lambda_opt_env_loop_0076:
	cmp rsi, 0
	je .L_lambda_opt_env_end_0076
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0076
.L_lambda_opt_env_end_0076:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0076:	; copying parameters
	cmp rsi, 0
	je .L_lambda_opt_params_end_0076
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0076
.L_lambda_opt_params_end_0076:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0076
	jmp .L_lambda_opt_end_0076
.L_lambda_opt_code_0076:	; body
	mov r8, qword [rsp + 8 * 2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_0076
	ja .L_lambda_opt_arity_check_more_0076
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0076:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0161:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0161
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0161
.L_lambda_opt_stack_shrink_loop_exit_0161:
	lea r10, [rsp + 8 * 0 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_0162:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0162
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0162
.L_lambda_opt_stack_shrink_loop_exit_0162:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0076
.L_lambda_opt_arity_check_exact_0076:
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
.L_lambda_opt_stack_shrink_loop_0160:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0160
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0160
.L_lambda_opt_stack_shrink_loop_exit_0160:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0076:
	mov qword [rsp + 8 * 2], 1
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; argc
	mov rax, qword [free_var_95]	; free var list->vector
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
.L_tc_recycle_frame_loop_053c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_053c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_053c
.L_tc_recycle_frame_done_053c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_0076:
	mov qword [free_var_140], rax
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
.L_lambda_simple_env_loop_0583:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0583
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0583
.L_lambda_simple_env_end_0583:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0583:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0583
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0583
.L_lambda_simple_params_end_0583:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0583
	jmp .L_lambda_simple_end_0583
.L_lambda_simple_code_0583:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0583
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0583:
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
.L_lambda_simple_env_loop_0584:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0584
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0584
.L_lambda_simple_env_end_0584:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0584:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0584
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0584
.L_lambda_simple_params_end_0584:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0584
	jmp .L_lambda_simple_end_0584
.L_lambda_simple_code_0584:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0584
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0584:
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
	je .L_if_else_0289
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
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_053d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_053d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_053d
.L_tc_recycle_frame_done_053d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0289
.L_if_else_0289:
	mov rax, L_constants + 1
.L_if_end_0289:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0584:	; new closure is in rax
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
.L_lambda_simple_env_loop_0585:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0585
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0585
.L_lambda_simple_env_end_0585:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0585:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0585
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0585
.L_lambda_simple_params_end_0585:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0585
	jmp .L_lambda_simple_end_0585
.L_lambda_simple_code_0585:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0585
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0585:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1
	mov rax, qword [free_var_127]	; free var string-length
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
	push 3	; argc
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
.L_tc_recycle_frame_loop_053e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_053e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_053e
.L_tc_recycle_frame_done_053e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0585:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0583:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_119], rax
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
.L_lambda_simple_env_loop_0586:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0586
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0586
.L_lambda_simple_env_end_0586:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0586:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0586
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0586
.L_lambda_simple_params_end_0586:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0586
	jmp .L_lambda_simple_end_0586
.L_lambda_simple_code_0586:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0586
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0586:
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
.L_lambda_simple_env_loop_0587:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0587
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0587
.L_lambda_simple_env_end_0587:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0587:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0587
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0587
.L_lambda_simple_params_end_0587:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0587
	jmp .L_lambda_simple_end_0587
.L_lambda_simple_code_0587:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0587
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0587:
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
	je .L_if_else_028a
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
	mov rax, qword [free_var_144]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_053f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_053f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_053f
.L_tc_recycle_frame_done_053f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_028a
.L_if_else_028a:
	mov rax, L_constants + 1
.L_if_end_028a:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0587:	; new closure is in rax
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
.L_lambda_simple_env_loop_0588:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0588
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0588
.L_lambda_simple_env_end_0588:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0588:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0588
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0588
.L_lambda_simple_params_end_0588:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0588
	jmp .L_lambda_simple_end_0588
.L_lambda_simple_code_0588:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0588
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0588:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param v
	push rax
	push 1
	mov rax, qword [free_var_143]	; free var vector-length
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
	push 3	; argc
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
.L_tc_recycle_frame_loop_0540:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0540
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0540
.L_tc_recycle_frame_done_0540:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0588:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0586:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_141], rax
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
.L_lambda_simple_env_loop_0589:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0589
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0589
.L_lambda_simple_env_end_0589:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0589:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0589
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0589
.L_lambda_simple_params_end_0589:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0589
	jmp .L_lambda_simple_end_0589
.L_lambda_simple_code_0589:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0589
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0589:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param n
	push rax
	; preparing a non-tail-call
	push 0
	mov rax, qword [free_var_139]	; free var trng
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; argc
	mov rax, qword [free_var_117]	; free var remainder
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
.L_tc_recycle_frame_loop_0541:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0541
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0541
.L_tc_recycle_frame_done_0541:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0589:	; new closure is in rax
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
.L_lambda_simple_env_loop_058a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_058a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_058a
.L_lambda_simple_env_end_058a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_058a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_058a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_058a
.L_lambda_simple_params_end_058a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_058a
	jmp .L_lambda_simple_end_058a
.L_lambda_simple_code_058a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_058a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_058a:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	mov rax, L_constants + 2135
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_0542:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0542
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0542
.L_tc_recycle_frame_done_0542:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_058a:	; new closure is in rax
	mov qword [free_var_112], rax
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
.L_lambda_simple_env_loop_058b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_058b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_058b
.L_lambda_simple_env_end_058b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_058b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_058b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_058b
.L_lambda_simple_params_end_058b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_058b
	jmp .L_lambda_simple_end_058b
.L_lambda_simple_code_058b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_058b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_058b:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	mov rax, PARAM(0)	; param x
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_0543:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0543
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0543
.L_tc_recycle_frame_done_0543:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_058b:	; new closure is in rax
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
.L_lambda_simple_env_loop_058c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_058c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_058c
.L_lambda_simple_env_end_058c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_058c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_058c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_058c
.L_lambda_simple_params_end_058c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_058c
	jmp .L_lambda_simple_end_058c
.L_lambda_simple_code_058c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_058c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_058c:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 3190
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2
	mov rax, qword [free_var_117]	; free var remainder
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	mov rax, qword [free_var_151]	; free var zero?
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
.L_tc_recycle_frame_loop_0544:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0544
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0544
.L_tc_recycle_frame_done_0544:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_058c:	; new closure is in rax
	mov qword [free_var_83], rax
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
.L_lambda_simple_env_loop_058d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_058d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_058d
.L_lambda_simple_env_end_058d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_058d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_058d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_058d
.L_lambda_simple_params_end_058d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_058d
	jmp .L_lambda_simple_end_058d
.L_lambda_simple_code_058d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_058d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_058d:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var even?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	mov rax, qword [free_var_106]	; free var not
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
.L_tc_recycle_frame_loop_0545:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0545
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0545
.L_tc_recycle_frame_done_0545:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_058d:	; new closure is in rax
	mov qword [free_var_109], rax
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
.L_lambda_simple_env_loop_058e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_058e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_058e
.L_lambda_simple_env_end_058e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_058e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_058e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_058e
.L_lambda_simple_params_end_058e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_058e
	jmp .L_lambda_simple_end_058e
.L_lambda_simple_code_058e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_058e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_058e:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_104]	; free var negative?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_028b
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; argc
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
.L_tc_recycle_frame_loop_0546:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0546
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0546
.L_tc_recycle_frame_done_0546:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_028b
.L_if_else_028b:
	mov rax, PARAM(0)	; param x
.L_if_end_028b:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_058e:	; new closure is in rax
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
.L_lambda_simple_env_loop_058f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_058f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_058f
.L_lambda_simple_env_end_058f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_058f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_058f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_058f
.L_lambda_simple_params_end_058f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_058f
	jmp .L_lambda_simple_end_058f
.L_lambda_simple_code_058f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_058f
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_058f:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_028c
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_028c
.L_if_else_028c:
	mov rax, L_constants + 2
.L_if_end_028c:
	cmp rax, sob_boolean_false
	je .L_if_else_0298
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
	mov rax, qword [free_var_81]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_028d
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
	push 2	; argc
	mov rax, qword [free_var_81]	; free var equal?
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
.L_tc_recycle_frame_loop_0547:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0547
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0547
.L_tc_recycle_frame_done_0547:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_028d
.L_if_else_028d:
	mov rax, L_constants + 2
.L_if_end_028d:
	jmp .L_if_end_0298
.L_if_else_0298:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_148]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_028f
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_148]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_028e
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_143]	; free var vector-length
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
	mov rax, qword [free_var_143]	; free var vector-length
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
	jmp .L_if_end_028e
.L_if_else_028e:
	mov rax, L_constants + 2
.L_if_end_028e:
	jmp .L_if_end_028f
.L_if_else_028f:
	mov rax, L_constants + 2
.L_if_end_028f:
	cmp rax, sob_boolean_false
	je .L_if_else_0297
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_141]	; free var vector->list
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
	mov rax, qword [free_var_141]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; argc
	mov rax, qword [free_var_81]	; free var equal?
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
.L_tc_recycle_frame_loop_0548:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0548
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0548
.L_tc_recycle_frame_done_0548:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0297
.L_if_else_0297:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_138]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0291
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_138]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0290
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_127]	; free var string-length
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
	mov rax, qword [free_var_127]	; free var string-length
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
	jmp .L_if_end_0290
.L_if_else_0290:
	mov rax, L_constants + 2
.L_if_end_0290:
	jmp .L_if_end_0291
.L_if_else_0291:
	mov rax, L_constants + 2
.L_if_end_0291:
	cmp rax, sob_boolean_false
	je .L_if_else_0296
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; argc
	mov rax, qword [free_var_135]	; free var string=?
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
.L_tc_recycle_frame_loop_0549:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0549
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0549
.L_tc_recycle_frame_done_0549:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0296
.L_if_else_0296:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0292
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_108]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0292
.L_if_else_0292:
	mov rax, L_constants + 2
.L_if_end_0292:
	cmp rax, sob_boolean_false
	je .L_if_else_0295
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_054a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_054a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_054a
.L_tc_recycle_frame_done_054a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0295
.L_if_else_0295:
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
	je .L_if_else_0293
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
	jmp .L_if_end_0293
.L_if_else_0293:
	mov rax, L_constants + 2
.L_if_end_0293:
	cmp rax, sob_boolean_false
	je .L_if_else_0294
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_054b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_054b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_054b
.L_tc_recycle_frame_done_054b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0294
.L_if_else_0294:
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; argc
	mov rax, qword [free_var_80]	; free var eq?
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
.L_tc_recycle_frame_loop_054c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_054c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_054c
.L_tc_recycle_frame_done_054c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0294:
.L_if_end_0295:
.L_if_end_0296:
.L_if_end_0297:
.L_if_end_0298:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_058f:	; new closure is in rax
	mov qword [free_var_81], rax
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
.L_lambda_simple_env_loop_0590:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0590
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0590
.L_lambda_simple_env_end_0590:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0590:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0590
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0590
.L_lambda_simple_params_end_0590:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0590
	jmp .L_lambda_simple_end_0590
.L_lambda_simple_code_0590:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0590
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0590:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_029a
	mov rax, L_constants + 2
	jmp .L_if_end_029a
.L_if_else_029a:
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
	mov rax, qword [free_var_80]	; free var eq?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0299
	;debug: preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; argc
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
.L_tc_recycle_frame_loop_054d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_054d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_054d
.L_tc_recycle_frame_done_054d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0299
.L_if_else_0299:
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_054e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_054e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_054e
.L_tc_recycle_frame_done_054e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0299:
.L_if_end_029a:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0590:	; new closure is in rax
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
.L_lambda_simple_env_loop_0591:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0591
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0591
.L_lambda_simple_env_end_0591:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0591:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0591
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0591
.L_lambda_simple_params_end_0591:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0591
	jmp .L_lambda_simple_end_0591
.L_lambda_simple_code_0591:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0591
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0591:
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
.L_lambda_simple_env_loop_0592:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0592
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0592
.L_lambda_simple_env_end_0592:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0592:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0592
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0592
.L_lambda_simple_params_end_0592:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0592
	jmp .L_lambda_simple_end_0592
.L_lambda_simple_code_0592:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0592
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0592:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_029b
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_029b
.L_if_else_029b:
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
	mov rax, qword [free_var_127]	; free var string-length
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
	push 1	; argc
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
.L_lambda_simple_env_loop_0593:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0593
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0593
.L_lambda_simple_env_end_0593:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0593:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_0593
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0593
.L_lambda_simple_params_end_0593:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0593
	jmp .L_lambda_simple_end_0593
.L_lambda_simple_code_0593:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0593
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0593:
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
	push 3	; argc
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
.L_tc_recycle_frame_loop_0550:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0550
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0550
.L_tc_recycle_frame_done_0550:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0593:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_054f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_054f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_054f
.L_tc_recycle_frame_done_054f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_029b:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0592:	; new closure is in rax
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
.L_lambda_simple_env_loop_0594:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0594
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0594
.L_lambda_simple_env_end_0594:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0594:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0594
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0594
.L_lambda_simple_params_end_0594:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0594
	jmp .L_lambda_simple_end_0594
.L_lambda_simple_code_0594:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0594
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0594:
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
	je .L_if_else_029c
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param str
	push rax
	push 2
	mov rax, qword [free_var_128]	; free var string-ref
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
	mov rax, qword [free_var_131]	; free var string-set!
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
	push 5	; argc
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
.L_tc_recycle_frame_loop_0551:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0551
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0551
.L_tc_recycle_frame_done_0551:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_029c
.L_if_else_029c:
	mov rax, PARAM(1)	; param i
.L_if_end_029c:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_0594:	; new closure is in rax
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
.L_lambda_opt_env_loop_0077:
	cmp rsi, 1
	je .L_lambda_opt_env_end_0077
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0077
.L_lambda_opt_env_end_0077:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0077:	; copying parameters
	cmp rsi, 2
	je .L_lambda_opt_params_end_0077
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0077
.L_lambda_opt_params_end_0077:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0077
	jmp .L_lambda_opt_end_0077
.L_lambda_opt_code_0077:	; body
	mov r8, qword [rsp + 8 * 2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_0077
	ja .L_lambda_opt_arity_check_more_0077
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0077:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0164:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0164
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0164
.L_lambda_opt_stack_shrink_loop_exit_0164:
	lea r10, [rsp + 8 * 0 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_0165:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0165
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0165
.L_lambda_opt_stack_shrink_loop_exit_0165:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0077
.L_lambda_opt_arity_check_exact_0077:
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
.L_lambda_opt_stack_shrink_loop_0163:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0163
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0163
.L_lambda_opt_stack_shrink_loop_exit_0163:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0077:
	mov qword [rsp + 8 * 2], 1
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
	mov rax, qword [free_var_127]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_103]	; free var map
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
	mov rax, qword [free_var_99]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; argc
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
.L_tc_recycle_frame_loop_0552:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0552
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0552
.L_tc_recycle_frame_done_0552:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_0077:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0591:	; new closure is in rax
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
.L_lambda_simple_env_loop_0595:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0595
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0595
.L_lambda_simple_env_end_0595:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0595:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0595
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0595
.L_lambda_simple_params_end_0595:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0595
	jmp .L_lambda_simple_end_0595
.L_lambda_simple_code_0595:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0595
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0595:
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
.L_lambda_simple_env_loop_0596:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0596
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0596
.L_lambda_simple_env_end_0596:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0596:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0596
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0596
.L_lambda_simple_params_end_0596:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0596
	jmp .L_lambda_simple_end_0596
.L_lambda_simple_code_0596:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0596
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0596:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_029d
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_029d
.L_if_else_029d:
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
	mov rax, qword [free_var_143]	; free var vector-length
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
	push 1	; argc
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
.L_lambda_simple_env_loop_0597:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0597
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0597
.L_lambda_simple_env_end_0597:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0597:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_0597
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0597
.L_lambda_simple_params_end_0597:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0597
	jmp .L_lambda_simple_end_0597
.L_lambda_simple_code_0597:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0597
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0597:
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
	push 3	; argc
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
.L_tc_recycle_frame_loop_0554:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0554
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0554
.L_tc_recycle_frame_done_0554:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0597:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0553:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0553
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0553
.L_tc_recycle_frame_done_0553:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_029d:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0596:	; new closure is in rax
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
.L_lambda_simple_env_loop_0598:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0598
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0598
.L_lambda_simple_env_end_0598:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0598:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0598
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0598
.L_lambda_simple_params_end_0598:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0598
	jmp .L_lambda_simple_end_0598
.L_lambda_simple_code_0598:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0598
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0598:
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
	je .L_if_else_029e
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	push 2
	mov rax, qword [free_var_144]	; free var vector-ref
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
	mov rax, qword [free_var_147]	; free var vector-set!
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
	push 5	; argc
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
.L_tc_recycle_frame_loop_0555:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0555
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0555
.L_tc_recycle_frame_done_0555:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_029e
.L_if_else_029e:
	mov rax, PARAM(1)	; param i
.L_if_end_029e:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_0598:	; new closure is in rax
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
.L_lambda_opt_env_loop_0078:
	cmp rsi, 1
	je .L_lambda_opt_env_end_0078
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0078
.L_lambda_opt_env_end_0078:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0078:	; copying parameters
	cmp rsi, 2
	je .L_lambda_opt_params_end_0078
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0078
.L_lambda_opt_params_end_0078:
	mov qword [rax], rbx
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0078
	jmp .L_lambda_opt_end_0078
.L_lambda_opt_code_0078:	; body
	mov r8, qword [rsp + 8 * 2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_0078
	ja .L_lambda_opt_arity_check_more_0078
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_0078:
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8 * r8 + 8 * 2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0167:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0167
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0167
.L_lambda_opt_stack_shrink_loop_exit_0167:
	lea r10, [rsp + 8 * 0 + 8 * 3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_0168:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0168
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0168
.L_lambda_opt_stack_shrink_loop_exit_0168:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_0078
.L_lambda_opt_arity_check_exact_0078:
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
.L_lambda_opt_stack_shrink_loop_0166:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0166
	mov r8, [rdx]
	mov qword [rdx - 8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0166
.L_lambda_opt_stack_shrink_loop_exit_0166:
	mov qword [rdx - 8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_0078:
	mov qword [rsp + 8 * 2], 1
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
	mov rax, qword [free_var_143]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_103]	; free var map
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
	mov rax, qword [free_var_101]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; argc
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
.L_tc_recycle_frame_loop_0556:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0556
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0556
.L_tc_recycle_frame_done_0556:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_0078:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0595:	; new closure is in rax
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
.L_lambda_simple_env_loop_0599:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0599
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0599
.L_lambda_simple_env_end_0599:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0599:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0599
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0599
.L_lambda_simple_params_end_0599:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0599
	jmp .L_lambda_simple_end_0599
.L_lambda_simple_code_0599:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0599
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0599:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1
	mov rax, qword [free_var_119]	; free var string->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_118]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	mov rax, qword [free_var_94]	; free var list->string
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
.L_tc_recycle_frame_loop_0557:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0557
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0557
.L_tc_recycle_frame_done_0557:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0599:	; new closure is in rax
	mov qword [free_var_129], rax
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
.L_lambda_simple_env_loop_059a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_059a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_059a
.L_lambda_simple_env_end_059a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_059a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_059a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_059a
.L_lambda_simple_params_end_059a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_059a
	jmp .L_lambda_simple_end_059a
.L_lambda_simple_code_059a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_059a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_059a:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param vec
	push rax
	push 1
	mov rax, qword [free_var_141]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_118]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	mov rax, qword [free_var_95]	; free var list->vector
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
.L_tc_recycle_frame_loop_0558:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0558
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0558
.L_tc_recycle_frame_done_0558:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_059a:	; new closure is in rax
	mov qword [free_var_145], rax
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
.L_lambda_simple_env_loop_059b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_059b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_059b
.L_lambda_simple_env_end_059b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_059b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_059b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_059b
.L_lambda_simple_params_end_059b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_059b
	jmp .L_lambda_simple_end_059b
.L_lambda_simple_code_059b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_059b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_059b:
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
.L_lambda_simple_env_loop_059c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_059c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_059c
.L_lambda_simple_env_end_059c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_059c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_059c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_059c
.L_lambda_simple_params_end_059c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_059c
	jmp .L_lambda_simple_end_059c
.L_lambda_simple_code_059c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_059c
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_059c:
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
	je .L_if_else_029f
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_059d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_059d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_059d
.L_lambda_simple_env_end_059d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_059d:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_059d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_059d
.L_lambda_simple_params_end_059d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_059d
	jmp .L_lambda_simple_end_059d
.L_lambda_simple_code_059d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_059d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_059d:
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
	mov rax, qword [free_var_128]	; free var string-ref
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
	mov rax, qword [free_var_131]	; free var string-set!
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
	mov rax, qword [free_var_131]	; free var string-set!
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
	push 3	; argc
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
.L_tc_recycle_frame_loop_055a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_055a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_055a
.L_tc_recycle_frame_done_055a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_059d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0559:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0559
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0559
.L_tc_recycle_frame_done_0559:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_029f
.L_if_else_029f:
	mov rax, PARAM(0)	; param str
.L_if_end_029f:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_059c:	; new closure is in rax
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
.L_lambda_simple_env_loop_059e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_059e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_059e
.L_lambda_simple_env_end_059e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_059e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_059e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_059e
.L_lambda_simple_params_end_059e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_059e
	jmp .L_lambda_simple_end_059e
.L_lambda_simple_code_059e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_059e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_059e:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1
	mov rax, qword [free_var_127]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_059f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_059f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_059f
.L_lambda_simple_env_end_059f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_059f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_059f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_059f
.L_lambda_simple_params_end_059f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_059f
	jmp .L_lambda_simple_end_059f
.L_lambda_simple_code_059f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_059f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_059f:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1
	mov rax, qword [free_var_151]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02a0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	jmp .L_if_end_02a0
.L_if_else_02a0:
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
	push 3	; argc
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
.L_tc_recycle_frame_loop_055c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_055c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_055c
.L_tc_recycle_frame_done_055c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02a0:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_059f:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_055b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_055b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_055b
.L_tc_recycle_frame_done_055b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_059e:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_059b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_130], rax
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
.L_lambda_simple_env_loop_05a0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05a0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a0
.L_lambda_simple_env_end_05a0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05a0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a0
.L_lambda_simple_params_end_05a0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a0
	jmp .L_lambda_simple_end_05a0
.L_lambda_simple_code_05a0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05a0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a0:
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
.L_lambda_simple_env_loop_05a1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05a1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a1
.L_lambda_simple_env_end_05a1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05a1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a1
.L_lambda_simple_params_end_05a1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a1
	jmp .L_lambda_simple_end_05a1
.L_lambda_simple_code_05a1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_05a1
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a1:
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
	je .L_if_else_02a1
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param vec
	push rax
	push 2
	mov rax, qword [free_var_144]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_05a2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05a2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a2
.L_lambda_simple_env_end_05a2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a2:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_05a2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a2
.L_lambda_simple_params_end_05a2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a2
	jmp .L_lambda_simple_end_05a2
.L_lambda_simple_code_05a2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05a2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a2:
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
	mov rax, qword [free_var_144]	; free var vector-ref
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
	mov rax, qword [free_var_147]	; free var vector-set!
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
	mov rax, qword [free_var_147]	; free var vector-set!
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
	push 3	; argc
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
.L_tc_recycle_frame_loop_055e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_055e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_055e
.L_tc_recycle_frame_done_055e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05a2:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_055d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_055d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_055d
.L_tc_recycle_frame_done_055d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02a1
.L_if_else_02a1:
	mov rax, PARAM(0)	; param vec
.L_if_end_02a1:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_05a1:	; new closure is in rax
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
.L_lambda_simple_env_loop_05a3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05a3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a3
.L_lambda_simple_env_end_05a3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05a3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a3
.L_lambda_simple_params_end_05a3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a3
	jmp .L_lambda_simple_end_05a3
.L_lambda_simple_code_05a3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05a3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a3:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param vec
	push rax
	push 1
	mov rax, qword [free_var_143]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_05a4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05a4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a4
.L_lambda_simple_env_end_05a4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05a4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a4
.L_lambda_simple_params_end_05a4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a4
	jmp .L_lambda_simple_end_05a4
.L_lambda_simple_code_05a4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05a4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a4:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1
	mov rax, qword [free_var_151]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02a2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	jmp .L_if_end_02a2
.L_if_else_02a2:
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
	push 3	; argc
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
.L_tc_recycle_frame_loop_0560:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0560
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0560
.L_tc_recycle_frame_done_0560:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02a2:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05a4:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_055f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_055f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_055f
.L_tc_recycle_frame_done_055f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05a3:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05a0:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_146], rax
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
.L_lambda_simple_env_loop_05a5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05a5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a5
.L_lambda_simple_env_end_05a5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05a5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a5
.L_lambda_simple_params_end_05a5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a5
	jmp .L_lambda_simple_end_05a5
.L_lambda_simple_code_05a5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_05a5
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a5:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_05a6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05a6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a6
.L_lambda_simple_env_end_05a6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a6:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_05a6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a6
.L_lambda_simple_params_end_05a6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a6
	jmp .L_lambda_simple_end_05a6
.L_lambda_simple_code_05a6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05a6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a6:
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
.L_lambda_simple_env_loop_05a7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05a7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a7
.L_lambda_simple_env_end_05a7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05a7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a7
.L_lambda_simple_params_end_05a7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a7
	jmp .L_lambda_simple_end_05a7
.L_lambda_simple_code_05a7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05a7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a7:
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
	je .L_if_else_02a3
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
	push 2	; argc
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
.L_tc_recycle_frame_loop_0562:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0562
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0562
.L_tc_recycle_frame_done_0562:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02a3
.L_if_else_02a3:
	mov rax, L_constants + 1
.L_if_end_02a3:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05a7:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	;debug: preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	push 1	; argc
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
.L_tc_recycle_frame_loop_0563:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0563
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0563
.L_tc_recycle_frame_done_0563:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05a6:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0561:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0561
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0561
.L_tc_recycle_frame_done_0561:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_05a5:	; new closure is in rax
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
.L_lambda_simple_env_loop_05a8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05a8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a8
.L_lambda_simple_env_end_05a8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05a8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a8
.L_lambda_simple_params_end_05a8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a8
	jmp .L_lambda_simple_end_05a8
.L_lambda_simple_code_05a8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_05a8
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a8:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1
	mov rax, qword [free_var_99]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_05a9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05a9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a9
.L_lambda_simple_env_end_05a9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a9:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_05a9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a9
.L_lambda_simple_params_end_05a9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a9
	jmp .L_lambda_simple_end_05a9
.L_lambda_simple_code_05a9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05a9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a9:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_05aa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05aa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05aa
.L_lambda_simple_env_end_05aa:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05aa:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05aa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05aa
.L_lambda_simple_params_end_05aa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05aa
	jmp .L_lambda_simple_end_05aa
.L_lambda_simple_code_05aa:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05aa
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05aa:
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
.L_lambda_simple_env_loop_05ab:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_05ab
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ab
.L_lambda_simple_env_end_05ab:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ab:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05ab
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ab
.L_lambda_simple_params_end_05ab:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ab
	jmp .L_lambda_simple_end_05ab
.L_lambda_simple_code_05ab:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05ab
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ab:
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
	je .L_if_else_02a4
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
	mov rax, qword [free_var_131]	; free var string-set!
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_0566:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0566
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0566
.L_tc_recycle_frame_done_0566:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02a4
.L_if_else_02a4:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
.L_if_end_02a4:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05ab:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	;debug: preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	push 1	; argc
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
.L_tc_recycle_frame_loop_0567:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0567
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0567
.L_tc_recycle_frame_done_0567:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05aa:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0565:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0565
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0565
.L_tc_recycle_frame_done_0565:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05a9:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0564:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0564
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0564
.L_tc_recycle_frame_done_0564:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_05a8:	; new closure is in rax
	mov qword [free_var_100], rax
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
.L_lambda_simple_env_loop_05ac:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05ac
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ac
.L_lambda_simple_env_end_05ac:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ac:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05ac
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ac
.L_lambda_simple_params_end_05ac:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ac
	jmp .L_lambda_simple_end_05ac
.L_lambda_simple_code_05ac:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_05ac
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ac:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_05ad:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05ad
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ad
.L_lambda_simple_env_end_05ad:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ad:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_05ad
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ad
.L_lambda_simple_params_end_05ad:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ad
	jmp .L_lambda_simple_end_05ad
.L_lambda_simple_code_05ad:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05ad
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ad:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_05ae:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05ae
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ae
.L_lambda_simple_env_end_05ae:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ae:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05ae
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ae
.L_lambda_simple_params_end_05ae:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ae
	jmp .L_lambda_simple_end_05ae
.L_lambda_simple_code_05ae:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05ae
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ae:
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
.L_lambda_simple_env_loop_05af:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_05af
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05af
.L_lambda_simple_env_end_05af:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05af:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05af
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05af
.L_lambda_simple_params_end_05af:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05af
	jmp .L_lambda_simple_end_05af
.L_lambda_simple_code_05af:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05af
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05af:
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
	je .L_if_else_02a5
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
	mov rax, qword [free_var_147]	; free var vector-set!
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
	push 1	; argc
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
.L_tc_recycle_frame_loop_056a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_056a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_056a
.L_tc_recycle_frame_done_056a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02a5
.L_if_else_02a5:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
.L_if_end_02a5:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05af:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	;debug: preparing a tail-call
	mov rax, L_constants + 2135
	push rax
	push 1	; argc
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
.L_tc_recycle_frame_loop_056b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_056b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_056b
.L_tc_recycle_frame_done_056b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05ae:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0569:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0569
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0569
.L_tc_recycle_frame_done_0569:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05ad:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0568:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0568
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0568
.L_tc_recycle_frame_done_0568:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_05ac:	; new closure is in rax
	mov qword [free_var_102], rax
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
.L_lambda_simple_env_loop_05b0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05b0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b0
.L_lambda_simple_env_end_05b0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05b0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b0
.L_lambda_simple_params_end_05b0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b0
	jmp .L_lambda_simple_end_05b0
.L_lambda_simple_code_05b0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_05b0
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b0:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	push 1
	mov rax, qword [free_var_151]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02a8
	mov rax, L_constants + 3485
	jmp .L_if_end_02a8
.L_if_else_02a8:
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
	je .L_if_else_02a7
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
	mov rax, qword [free_var_97]	; free var logarithm
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 3485
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_056c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_056c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_056c
.L_tc_recycle_frame_done_056c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02a7
.L_if_else_02a7:
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
	je .L_if_else_02a6
	mov rax, L_constants + 3485
	jmp .L_if_end_02a6
.L_if_else_02a6:
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
	mov rax, qword [free_var_97]	; free var logarithm
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 3485
	push rax
	push 2	; argc
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
.L_tc_recycle_frame_loop_056d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_056d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_056d
.L_tc_recycle_frame_done_056d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02a6:
.L_if_end_02a7:
.L_if_end_02a8:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_05b0:	; new closure is in rax
	mov qword [free_var_97], rax
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
.L_lambda_simple_env_loop_05b1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05b1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b1
.L_lambda_simple_env_end_05b1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b1:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05b1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b1
.L_lambda_simple_params_end_05b1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b1
	jmp .L_lambda_simple_end_05b1
.L_lambda_simple_code_05b1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_05b1
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b1:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, L_constants + 3510
	push rax
	push 1	; argc
	mov rax, qword [free_var_150]	; free var write-char
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
.L_tc_recycle_frame_loop_056e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_056e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_056e
.L_tc_recycle_frame_done_056e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_05b1:	; new closure is in rax
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
.L_lambda_simple_env_loop_05b2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05b2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b2
.L_lambda_simple_env_end_05b2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b2:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05b2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b2
.L_lambda_simple_params_end_05b2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b2
	jmp .L_lambda_simple_end_05b2
.L_lambda_simple_code_05b2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_05b2
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b2:
	enter 0, 0
	mov rax, L_constants + 0
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_05b2:	; new closure is in rax
	mov qword [free_var_149], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 2
	push rax
	push 1
	; preparing a non-tail-call
	mov rax, L_constants + 3
	push rax
	push 1
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_05b3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05b3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b3
.L_lambda_simple_env_end_05b3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b3:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05b3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b3
.L_lambda_simple_params_end_05b3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b3
	jmp .L_lambda_simple_end_05b3
.L_lambda_simple_code_05b3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05b3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b3:
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
.L_lambda_simple_env_loop_05b4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05b4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b4
.L_lambda_simple_env_end_05b4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05b4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b4
.L_lambda_simple_params_end_05b4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b4
	jmp .L_lambda_simple_end_05b4
.L_lambda_simple_code_05b4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05b4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b4:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param y
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_056f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_056f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_056f
.L_tc_recycle_frame_done_056f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05b4:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05b3:	; new closure is in rax
	push rax
	push 1
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_05b5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05b5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b5
.L_lambda_simple_env_end_05b5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05b5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b5
.L_lambda_simple_params_end_05b5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b5
	jmp .L_lambda_simple_end_05b5
.L_lambda_simple_code_05b5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05b5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b5:
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
.L_lambda_simple_env_loop_05b6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05b6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b6
.L_lambda_simple_env_end_05b6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05b6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b6
.L_lambda_simple_params_end_05b6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b6
	jmp .L_lambda_simple_end_05b6
.L_lambda_simple_code_05b6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05b6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b6:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param y
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0570:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0570
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0570
.L_tc_recycle_frame_done_0570:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05b6:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05b5:	; new closure is in rax
	push rax
	push 1
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_05b7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05b7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b7
.L_lambda_simple_env_end_05b7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b7:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05b7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b7
.L_lambda_simple_params_end_05b7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b7
	jmp .L_lambda_simple_end_05b7
.L_lambda_simple_code_05b7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05b7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b7:
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
.L_lambda_simple_env_loop_05b8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05b8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b8
.L_lambda_simple_env_end_05b8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b8:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05b8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b8
.L_lambda_simple_params_end_05b8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b8
	jmp .L_lambda_simple_end_05b8
.L_lambda_simple_code_05b8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05b8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b8:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param y
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0571:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0571
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0571
.L_tc_recycle_frame_done_0571:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05b8:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05b7:	; new closure is in rax
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
.L_lambda_simple_env_loop_05b9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05b9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b9
.L_lambda_simple_env_end_05b9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05b9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b9
.L_lambda_simple_params_end_05b9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b9
	jmp .L_lambda_simple_end_05b9
.L_lambda_simple_code_05b9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05b9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b9:
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
.L_lambda_simple_env_loop_05ba:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05ba
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ba
.L_lambda_simple_env_end_05ba:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ba:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05ba
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ba
.L_lambda_simple_params_end_05ba:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ba
	jmp .L_lambda_simple_end_05ba
.L_lambda_simple_code_05ba:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05ba
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ba:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param y
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0572:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0572
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0572
.L_tc_recycle_frame_done_0572:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05ba:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05b9:	; new closure is in rax
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
.L_lambda_simple_env_loop_05bb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05bb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05bb
.L_lambda_simple_env_end_05bb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05bb:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05bb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05bb
.L_lambda_simple_params_end_05bb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05bb
	jmp .L_lambda_simple_end_05bb
.L_lambda_simple_code_05bb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05bb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05bb:
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
.L_lambda_simple_env_loop_05bc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05bc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05bc
.L_lambda_simple_env_end_05bc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05bc:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05bc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05bc
.L_lambda_simple_params_end_05bc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05bc
	jmp .L_lambda_simple_end_05bc
.L_lambda_simple_code_05bc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05bc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05bc:
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
.L_lambda_simple_env_loop_05bd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05bd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05bd
.L_lambda_simple_env_end_05bd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05bd:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05bd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05bd
.L_lambda_simple_params_end_05bd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05bd
	jmp .L_lambda_simple_end_05bd
.L_lambda_simple_code_05bd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05bd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05bd:
	enter 0, 0
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
.L_lambda_simple_env_loop_05be:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_05be
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05be
.L_lambda_simple_env_end_05be:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05be:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05be
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05be
.L_lambda_simple_params_end_05be:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05be
	jmp .L_lambda_simple_end_05be
.L_lambda_simple_code_05be:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05be
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05be:
	enter 0, 0
	mov rax, PARAM(0)	; param y
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05be:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05bd:	; new closure is in rax
	push rax
	push 1	; argc
	; preparing a non-tail-call
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_05bf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05bf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05bf
.L_lambda_simple_env_end_05bf:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05bf:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05bf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05bf
.L_lambda_simple_params_end_05bf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05bf
	jmp .L_lambda_simple_end_05bf
.L_lambda_simple_code_05bf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05bf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05bf:
	enter 0, 0
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
.L_lambda_simple_env_loop_05c0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_05c0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c0
.L_lambda_simple_env_end_05c0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c0:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05c0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c0
.L_lambda_simple_params_end_05c0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c0
	jmp .L_lambda_simple_end_05c0
.L_lambda_simple_code_05c0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05c0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c0:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param b
	push rax
	push 1	; argc
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_05c1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_05c1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c1
.L_lambda_simple_env_end_05c1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05c1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c1
.L_lambda_simple_params_end_05c1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c1
	jmp .L_lambda_simple_end_05c1
.L_lambda_simple_code_05c1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05c1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c1:
	enter 0, 0
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
.L_lambda_simple_env_loop_05c2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_05c2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c2
.L_lambda_simple_env_end_05c2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05c2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c2
.L_lambda_simple_params_end_05c2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c2
	jmp .L_lambda_simple_end_05c2
.L_lambda_simple_code_05c2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05c2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c2:
	enter 0, 0
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
.L_lambda_simple_env_loop_05c3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_05c3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c3
.L_lambda_simple_env_end_05c3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05c3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c3
.L_lambda_simple_params_end_05c3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c3
	jmp .L_lambda_simple_end_05c3
.L_lambda_simple_code_05c3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05c3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c3:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param z
	push rax
	push 1
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var n
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0575:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0575
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0575
.L_tc_recycle_frame_done_0575:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05c3:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05c2:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05c1:	; new closure is in rax
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0574:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0574
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0574
.L_tc_recycle_frame_done_0574:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05c0:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05bf:	; new closure is in rax
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, PARAM(0)	; param b
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0573:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0573
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0573
.L_tc_recycle_frame_done_0573:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05bc:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05bb:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
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
.L_lambda_simple_env_loop_05c4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05c4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c4
.L_lambda_simple_env_end_05c4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05c4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c4
.L_lambda_simple_params_end_05c4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c4
	jmp .L_lambda_simple_end_05c4
.L_lambda_simple_code_05c4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05c4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c4:
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
.L_lambda_simple_env_loop_05c5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05c5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c5
.L_lambda_simple_env_end_05c5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c5:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05c5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c5
.L_lambda_simple_params_end_05c5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c5
	jmp .L_lambda_simple_end_05c5
.L_lambda_simple_code_05c5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05c5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c5:
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
.L_lambda_simple_env_loop_05c6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05c6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c6
.L_lambda_simple_env_end_05c6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05c6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c6
.L_lambda_simple_params_end_05c6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c6
	jmp .L_lambda_simple_end_05c6
.L_lambda_simple_code_05c6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05c6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c6:
	enter 0, 0
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
.L_lambda_simple_env_loop_05c7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_05c7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c7
.L_lambda_simple_env_end_05c7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05c7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c7
.L_lambda_simple_params_end_05c7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c7
	jmp .L_lambda_simple_end_05c7
.L_lambda_simple_code_05c7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05c7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c7:
	enter 0, 0
	mov rax, PARAM(0)	; param y
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05c7:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05c6:	; new closure is in rax
	push rax
	push 1	; argc
	; preparing a non-tail-call
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_05c8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05c8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c8
.L_lambda_simple_env_end_05c8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c8:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05c8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c8
.L_lambda_simple_params_end_05c8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c8
	jmp .L_lambda_simple_end_05c8
.L_lambda_simple_code_05c8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05c8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c8:
	enter 0, 0
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
.L_lambda_simple_env_loop_05c9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_05c9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c9
.L_lambda_simple_env_end_05c9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05c9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c9
.L_lambda_simple_params_end_05c9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c9
	jmp .L_lambda_simple_end_05c9
.L_lambda_simple_code_05c9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05c9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c9:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param b
	push rax
	push 1	; argc
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_05ca:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_05ca
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ca
.L_lambda_simple_env_end_05ca:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ca:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05ca
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ca
.L_lambda_simple_params_end_05ca:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ca
	jmp .L_lambda_simple_end_05ca
.L_lambda_simple_code_05ca:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05ca
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ca:
	enter 0, 0
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
.L_lambda_simple_env_loop_05cb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_05cb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05cb
.L_lambda_simple_env_end_05cb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05cb:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05cb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05cb
.L_lambda_simple_params_end_05cb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05cb
	jmp .L_lambda_simple_end_05cb
.L_lambda_simple_code_05cb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05cb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05cb:
	enter 0, 0
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
.L_lambda_simple_env_loop_05cc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_05cc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05cc
.L_lambda_simple_env_end_05cc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05cc:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05cc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05cc
.L_lambda_simple_params_end_05cc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05cc
	jmp .L_lambda_simple_end_05cc
.L_lambda_simple_code_05cc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05cc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05cc:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param z
	push rax
	push 1
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var n
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0578:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0578
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0578
.L_tc_recycle_frame_done_0578:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05cc:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05cb:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05ca:	; new closure is in rax
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0577:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0577
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0577
.L_tc_recycle_frame_done_0577:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05c9:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05c8:	; new closure is in rax
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, PARAM(0)	; param b
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0576:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0576
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0576
.L_tc_recycle_frame_done_0576:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05c5:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05c4:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_05cd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05cd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05cd
.L_lambda_simple_env_end_05cd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05cd:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05cd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05cd
.L_lambda_simple_params_end_05cd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05cd
	jmp .L_lambda_simple_end_05cd
.L_lambda_simple_code_05cd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05cd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05cd:
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
.L_lambda_simple_env_loop_05ce:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05ce
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ce
.L_lambda_simple_env_end_05ce:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ce:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05ce
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ce
.L_lambda_simple_params_end_05ce:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ce
	jmp .L_lambda_simple_end_05ce
.L_lambda_simple_code_05ce:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05ce
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ce:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param y
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0579:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0579
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0579
.L_tc_recycle_frame_done_0579:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05ce:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05cd:	; new closure is in rax
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
.L_lambda_simple_env_loop_05cf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05cf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05cf
.L_lambda_simple_env_end_05cf:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05cf:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05cf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05cf
.L_lambda_simple_params_end_05cf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05cf
	jmp .L_lambda_simple_end_05cf
.L_lambda_simple_code_05cf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05cf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05cf:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_05d0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05d0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d0
.L_lambda_simple_env_end_05d0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d0:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05d0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d0
.L_lambda_simple_params_end_05d0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d0
	jmp .L_lambda_simple_end_05d0
.L_lambda_simple_code_05d0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05d0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d0:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05d0:	; new closure is in rax
	push rax
	push 1
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_05d1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05d1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d1
.L_lambda_simple_env_end_05d1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05d1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d1
.L_lambda_simple_params_end_05d1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d1
	jmp .L_lambda_simple_end_05d1
.L_lambda_simple_code_05d1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05d1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d1:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05d1:	; new closure is in rax
	push rax
	push 1
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
.L_lambda_simple_env_loop_05d2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05d2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d2
.L_lambda_simple_env_end_05d2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05d2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d2
.L_lambda_simple_params_end_05d2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d2
	jmp .L_lambda_simple_end_05d2
.L_lambda_simple_code_05d2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05d2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d2:
	enter 0, 0
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
.L_lambda_simple_env_loop_05d3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05d3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d3
.L_lambda_simple_env_end_05d3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05d3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d3
.L_lambda_simple_params_end_05d3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d3
	jmp .L_lambda_simple_end_05d3
.L_lambda_simple_code_05d3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05d3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d3:
	enter 0, 0
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
.L_lambda_simple_env_loop_05d4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_05d4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d4
.L_lambda_simple_env_end_05d4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05d4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d4
.L_lambda_simple_params_end_05d4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d4
	jmp .L_lambda_simple_end_05d4
.L_lambda_simple_code_05d4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05d4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d4:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var b
	push rax
	push 1	; argc
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 1
	mov rax, PARAM(0)	; param c
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_057b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_057b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_057b
.L_tc_recycle_frame_done_057b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05d4:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05d3:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05d2:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_05d5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05d5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d5
.L_lambda_simple_env_end_05d5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d5:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05d5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d5
.L_lambda_simple_params_end_05d5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d5
	jmp .L_lambda_simple_end_05d5
.L_lambda_simple_code_05d5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05d5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d5:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param p
	push rax
	push 1
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
.L_lambda_simple_env_loop_05d6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05d6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d6
.L_lambda_simple_env_end_05d6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05d6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d6
.L_lambda_simple_params_end_05d6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d6
	jmp .L_lambda_simple_end_05d6
.L_lambda_simple_code_05d6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05d6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d6:
	enter 0, 0
	;debug: preparing a tail-call
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
.L_lambda_simple_env_loop_05d7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_05d7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d7
.L_lambda_simple_env_end_05d7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05d7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d7
.L_lambda_simple_params_end_05d7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d7
	jmp .L_lambda_simple_end_05d7
.L_lambda_simple_code_05d7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05d7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d7:
	enter 0, 0
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
.L_lambda_simple_env_loop_05d8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_05d8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d8
.L_lambda_simple_env_end_05d8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d8:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05d8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d8
.L_lambda_simple_params_end_05d8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d8
	jmp .L_lambda_simple_end_05d8
.L_lambda_simple_code_05d8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05d8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d8:
	enter 0, 0
	mov rax, PARAM(0)	; param b
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05d8:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05d7:	; new closure is in rax
	push rax
	push 1	; argc
	mov rax, PARAM(0)	; param p
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_057d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_057d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_057d
.L_tc_recycle_frame_done_057d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05d6:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param p
	push rax
	push 1
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
.L_lambda_simple_env_loop_05d9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05d9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d9
.L_lambda_simple_env_end_05d9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05d9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d9
.L_lambda_simple_params_end_05d9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d9
	jmp .L_lambda_simple_end_05d9
.L_lambda_simple_code_05d9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05d9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d9:
	enter 0, 0
	;debug: preparing a tail-call
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
.L_lambda_simple_env_loop_05da:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_05da
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05da
.L_lambda_simple_env_end_05da:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05da:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05da
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05da
.L_lambda_simple_params_end_05da:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05da
	jmp .L_lambda_simple_end_05da
.L_lambda_simple_code_05da:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05da
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05da:
	enter 0, 0
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
.L_lambda_simple_env_loop_05db:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_05db
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05db
.L_lambda_simple_env_end_05db:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05db:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05db
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05db
.L_lambda_simple_params_end_05db:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05db
	jmp .L_lambda_simple_end_05db
.L_lambda_simple_code_05db:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05db
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05db:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05db:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05da:	; new closure is in rax
	push rax
	push 1	; argc
	mov rax, PARAM(0)	; param p
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_057e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_057e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_057e
.L_tc_recycle_frame_done_057e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05d9:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
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
.L_lambda_simple_env_loop_05dc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05dc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05dc
.L_lambda_simple_env_end_05dc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05dc:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05dc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05dc
.L_lambda_simple_params_end_05dc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05dc
	jmp .L_lambda_simple_end_05dc
.L_lambda_simple_code_05dc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05dc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05dc:
	enter 0, 0
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
.L_lambda_simple_env_loop_05dd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_05dd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05dd
.L_lambda_simple_env_end_05dd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05dd:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05dd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05dd
.L_lambda_simple_params_end_05dd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05dd
	jmp .L_lambda_simple_end_05dd
.L_lambda_simple_code_05dd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05dd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05dd:
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
.L_lambda_simple_env_loop_05de:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_05de
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05de
.L_lambda_simple_env_end_05de:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05de:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05de
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05de
.L_lambda_simple_params_end_05de:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05de
	jmp .L_lambda_simple_end_05de
.L_lambda_simple_code_05de:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05de
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05de:
	enter 0, 0
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
.L_lambda_simple_env_loop_05df:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_05df
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05df
.L_lambda_simple_env_end_05df:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05df:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05df
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05df
.L_lambda_simple_params_end_05df:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05df
	jmp .L_lambda_simple_end_05df
.L_lambda_simple_code_05df:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05df
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05df:
	enter 0, 0
	mov rax, PARAM(0)	; param y
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05df:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05de:	; new closure is in rax
	push rax
	push 1	; argc
	; preparing a non-tail-call
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_05e0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_05e0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05e0
.L_lambda_simple_env_end_05e0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05e0:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05e0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05e0
.L_lambda_simple_params_end_05e0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05e0
	jmp .L_lambda_simple_end_05e0
.L_lambda_simple_code_05e0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05e0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05e0:
	enter 0, 0
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
.L_lambda_simple_env_loop_05e1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_05e1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05e1
.L_lambda_simple_env_end_05e1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05e1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05e1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05e1
.L_lambda_simple_params_end_05e1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05e1
	jmp .L_lambda_simple_end_05e1
.L_lambda_simple_code_05e1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05e1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05e1:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, PARAM(0)	; param b
	push rax
	push 1	; argc
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_05e2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_05e2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05e2
.L_lambda_simple_env_end_05e2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05e2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05e2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05e2
.L_lambda_simple_params_end_05e2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05e2
	jmp .L_lambda_simple_end_05e2
.L_lambda_simple_code_05e2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05e2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05e2:
	enter 0, 0
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
.L_lambda_simple_env_loop_05e3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_05e3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05e3
.L_lambda_simple_env_end_05e3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05e3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05e3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05e3
.L_lambda_simple_params_end_05e3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05e3
	jmp .L_lambda_simple_end_05e3
.L_lambda_simple_code_05e3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05e3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05e3:
	enter 0, 0
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
.L_lambda_simple_env_loop_05e4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_05e4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05e4
.L_lambda_simple_env_end_05e4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05e4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05e4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05e4
.L_lambda_simple_params_end_05e4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05e4
	jmp .L_lambda_simple_end_05e4
.L_lambda_simple_code_05e4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05e4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05e4:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param z
	push rax
	push 1
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var n
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0581:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0581
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0581
.L_tc_recycle_frame_done_0581:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05e4:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05e3:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05e2:	; new closure is in rax
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0580:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0580
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0580
.L_tc_recycle_frame_done_0580:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05e1:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05e0:	; new closure is in rax
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, PARAM(0)	; param b
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_057f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_057f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_057f
.L_tc_recycle_frame_done_057f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05dd:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05dc:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param p
	push rax
	push 1
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
.L_lambda_simple_env_loop_05e5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05e5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05e5
.L_lambda_simple_env_end_05e5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05e5:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05e5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05e5
.L_lambda_simple_params_end_05e5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05e5
	jmp .L_lambda_simple_end_05e5
.L_lambda_simple_code_05e5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05e5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05e5:
	enter 0, 0
	;debug: preparing a tail-call
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
.L_lambda_simple_env_loop_05e6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_05e6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05e6
.L_lambda_simple_env_end_05e6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05e6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05e6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05e6
.L_lambda_simple_params_end_05e6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05e6
	jmp .L_lambda_simple_end_05e6
.L_lambda_simple_code_05e6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05e6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05e6:
	enter 0, 0
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
.L_lambda_simple_env_loop_05e7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_05e7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05e7
.L_lambda_simple_env_end_05e7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05e7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05e7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05e7
.L_lambda_simple_params_end_05e7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05e7
	jmp .L_lambda_simple_end_05e7
.L_lambda_simple_code_05e7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05e7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05e7:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05e7:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05e6:	; new closure is in rax
	push rax
	push 1	; argc
	mov rax, PARAM(0)	; param p
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0582:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0582
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0582
.L_tc_recycle_frame_done_0582:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05e5:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
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
.L_lambda_simple_env_loop_05e8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05e8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05e8
.L_lambda_simple_env_end_05e8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05e8:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05e8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05e8
.L_lambda_simple_params_end_05e8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05e8
	jmp .L_lambda_simple_end_05e8
.L_lambda_simple_code_05e8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05e8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05e8:
	enter 0, 0
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
.L_lambda_simple_env_loop_05e9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_05e9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05e9
.L_lambda_simple_env_end_05e9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05e9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05e9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05e9
.L_lambda_simple_params_end_05e9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05e9
	jmp .L_lambda_simple_end_05e9
.L_lambda_simple_code_05e9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05e9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05e9:
	enter 0, 0
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
.L_lambda_simple_env_loop_05ea:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_05ea
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ea
.L_lambda_simple_env_end_05ea:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ea:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05ea
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ea
.L_lambda_simple_params_end_05ea:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ea
	jmp .L_lambda_simple_end_05ea
.L_lambda_simple_code_05ea:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05ea
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ea:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param z
	push rax
	push 1
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var n
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0583:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0583
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0583
.L_tc_recycle_frame_done_0583:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05ea:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05e9:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05e8:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
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
.L_lambda_simple_env_loop_05eb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05eb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05eb
.L_lambda_simple_env_end_05eb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05eb:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05eb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05eb
.L_lambda_simple_params_end_05eb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05eb
	jmp .L_lambda_simple_end_05eb
.L_lambda_simple_code_05eb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05eb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05eb:
	enter 0, 0
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
.L_lambda_simple_env_loop_05ec:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_05ec
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ec
.L_lambda_simple_env_end_05ec:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ec:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05ec
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ec
.L_lambda_simple_params_end_05ec:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ec
	jmp .L_lambda_simple_end_05ec
.L_lambda_simple_code_05ec:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05ec
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ec:
	enter 0, 0
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
.L_lambda_simple_env_loop_05ed:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_05ed
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ed
.L_lambda_simple_env_end_05ed:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ed:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05ed
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ed
.L_lambda_simple_params_end_05ed:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ed
	jmp .L_lambda_simple_end_05ed
.L_lambda_simple_code_05ed:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05ed
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ed:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var b
	push rax
	push 1	; argc
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 1
	mov rax, PARAM(0)	; param c
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0584:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0584
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0584
.L_tc_recycle_frame_done_0584:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05ed:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05ec:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05eb:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_057c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_057c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_057c
.L_tc_recycle_frame_done_057c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05d5:	; new closure is in rax
	push rax
	push 1
	mov rax, PARAM(0)	; param n
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_05ee:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05ee
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ee
.L_lambda_simple_env_end_05ee:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ee:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05ee
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ee
.L_lambda_simple_params_end_05ee:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ee
	jmp .L_lambda_simple_end_05ee
.L_lambda_simple_code_05ee:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05ee
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ee:
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
.L_lambda_simple_env_loop_05ef:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05ef
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ef
.L_lambda_simple_env_end_05ef:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ef:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05ef
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ef
.L_lambda_simple_params_end_05ef:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ef
	jmp .L_lambda_simple_end_05ef
.L_lambda_simple_code_05ef:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05ef
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ef:
	enter 0, 0
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
.L_lambda_simple_env_loop_05f0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_05f0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05f0
.L_lambda_simple_env_end_05f0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05f0:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05f0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05f0
.L_lambda_simple_params_end_05f0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05f0
	jmp .L_lambda_simple_end_05f0
.L_lambda_simple_code_05f0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05f0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05f0:
	enter 0, 0
	mov rax, PARAM(0)	; param b
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05f0:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05ef:	; new closure is in rax
	push rax
	push 1	; argc
	mov rax, PARAM(0)	; param p
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0585:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0585
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0585
.L_tc_recycle_frame_done_0585:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05ee:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_057a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_057a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_057a
.L_tc_recycle_frame_done_057a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05cf:	; new closure is in rax
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
.L_lambda_simple_env_loop_05f1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05f1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05f1
.L_lambda_simple_env_end_05f1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05f1:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05f1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05f1
.L_lambda_simple_params_end_05f1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05f1
	jmp .L_lambda_simple_end_05f1
.L_lambda_simple_code_05f1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05f1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05f1:
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
.L_lambda_simple_env_loop_05f2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05f2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05f2
.L_lambda_simple_env_end_05f2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05f2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05f2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05f2
.L_lambda_simple_params_end_05f2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05f2
	jmp .L_lambda_simple_end_05f2
.L_lambda_simple_code_05f2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05f2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05f2:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 1
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param b
	push rax
	push 1
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
.L_lambda_simple_env_loop_05f3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05f3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05f3
.L_lambda_simple_env_end_05f3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05f3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05f3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05f3
.L_lambda_simple_params_end_05f3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05f3
	jmp .L_lambda_simple_end_05f3
.L_lambda_simple_code_05f3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05f3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05f3:
	enter 0, 0
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
.L_lambda_simple_env_loop_05f4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_05f4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05f4
.L_lambda_simple_env_end_05f4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05f4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05f4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05f4
.L_lambda_simple_params_end_05f4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05f4
	jmp .L_lambda_simple_end_05f4
.L_lambda_simple_code_05f4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05f4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05f4:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 1	; argc
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_05f5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_05f5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05f5
.L_lambda_simple_env_end_05f5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05f5:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05f5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05f5
.L_lambda_simple_params_end_05f5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05f5
	jmp .L_lambda_simple_end_05f5
.L_lambda_simple_code_05f5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05f5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05f5:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_05f6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_05f6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05f6
.L_lambda_simple_env_end_05f6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05f6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05f6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05f6
.L_lambda_simple_params_end_05f6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05f6
	jmp .L_lambda_simple_end_05f6
.L_lambda_simple_code_05f6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05f6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05f6:
	enter 0, 0
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
.L_lambda_simple_env_loop_05f7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_05f7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05f7
.L_lambda_simple_env_end_05f7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05f7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05f7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05f7
.L_lambda_simple_params_end_05f7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05f7
	jmp .L_lambda_simple_end_05f7
.L_lambda_simple_code_05f7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05f7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05f7:
	enter 0, 0
	mov rax, PARAM(0)	; param y
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05f7:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05f6:	; new closure is in rax
	push rax
	push 1
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_05f8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_05f8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05f8
.L_lambda_simple_env_end_05f8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05f8:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05f8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05f8
.L_lambda_simple_params_end_05f8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05f8
	jmp .L_lambda_simple_end_05f8
.L_lambda_simple_code_05f8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05f8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05f8:
	enter 0, 0
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
.L_lambda_simple_env_loop_05f9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_05f9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05f9
.L_lambda_simple_env_end_05f9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05f9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05f9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05f9
.L_lambda_simple_params_end_05f9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05f9
	jmp .L_lambda_simple_end_05f9
.L_lambda_simple_code_05f9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05f9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05f9:
	enter 0, 0
	mov rax, PARAM(0)	; param y
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05f9:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05f8:	; new closure is in rax
	push rax
	push 1
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
.L_lambda_simple_env_loop_05fa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_05fa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05fa
.L_lambda_simple_env_end_05fa:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05fa:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05fa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05fa
.L_lambda_simple_params_end_05fa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05fa
	jmp .L_lambda_simple_end_05fa
.L_lambda_simple_code_05fa:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05fa
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05fa:
	enter 0, 0
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
.L_lambda_simple_env_loop_05fb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_05fb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05fb
.L_lambda_simple_env_end_05fb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05fb:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05fb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05fb
.L_lambda_simple_params_end_05fb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05fb
	jmp .L_lambda_simple_end_05fb
.L_lambda_simple_code_05fb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05fb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05fb:
	enter 0, 0
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
.L_lambda_simple_env_loop_05fc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_05fc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05fc
.L_lambda_simple_env_end_05fc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05fc:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05fc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05fc
.L_lambda_simple_params_end_05fc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05fc
	jmp .L_lambda_simple_end_05fc
.L_lambda_simple_code_05fc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05fc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05fc:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var b
	push rax
	push 1	; argc
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 1
	mov rax, PARAM(0)	; param c
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0589:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0589
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0589
.L_tc_recycle_frame_done_0589:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05fc:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05fb:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05fa:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_05fd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_05fd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05fd
.L_lambda_simple_env_end_05fd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05fd:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05fd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05fd
.L_lambda_simple_params_end_05fd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05fd
	jmp .L_lambda_simple_end_05fd
.L_lambda_simple_code_05fd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05fd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05fd:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param p
	push rax
	push 1
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
.L_lambda_simple_env_loop_05fe:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_05fe
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05fe
.L_lambda_simple_env_end_05fe:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05fe:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05fe
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05fe
.L_lambda_simple_params_end_05fe:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05fe
	jmp .L_lambda_simple_end_05fe
.L_lambda_simple_code_05fe:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05fe
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05fe:
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
.L_lambda_simple_env_loop_05ff:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_05ff
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ff
.L_lambda_simple_env_end_05ff:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ff:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05ff
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ff
.L_lambda_simple_params_end_05ff:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ff
	jmp .L_lambda_simple_end_05ff
.L_lambda_simple_code_05ff:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05ff
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ff:
	enter 0, 0
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
.L_lambda_simple_env_loop_0600:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_0600
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0600
.L_lambda_simple_env_end_0600:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0600:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0600
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0600
.L_lambda_simple_params_end_0600:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0600
	jmp .L_lambda_simple_end_0600
.L_lambda_simple_code_0600:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0600
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0600:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0600:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05ff:	; new closure is in rax
	push rax
	push 1	; argc
	mov rax, PARAM(0)	; param p
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_058b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_058b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_058b
.L_tc_recycle_frame_done_058b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05fe:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param p
	push rax
	push 1
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
.L_lambda_simple_env_loop_0601:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_0601
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0601
.L_lambda_simple_env_end_0601:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0601:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0601
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0601
.L_lambda_simple_params_end_0601:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0601
	jmp .L_lambda_simple_end_0601
.L_lambda_simple_code_0601:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0601
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0601:
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
.L_lambda_simple_env_loop_0602:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_0602
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0602
.L_lambda_simple_env_end_0602:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0602:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0602
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0602
.L_lambda_simple_params_end_0602:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0602
	jmp .L_lambda_simple_end_0602
.L_lambda_simple_code_0602:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0602
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0602:
	enter 0, 0
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
.L_lambda_simple_env_loop_0603:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_0603
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0603
.L_lambda_simple_env_end_0603:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0603:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0603
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0603
.L_lambda_simple_params_end_0603:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0603
	jmp .L_lambda_simple_end_0603
.L_lambda_simple_code_0603:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0603
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0603:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0603:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0602:	; new closure is in rax
	push rax
	push 1	; argc
	mov rax, PARAM(0)	; param p
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_058c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_058c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_058c
.L_tc_recycle_frame_done_058c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0601:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
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
.L_lambda_simple_env_loop_0604:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_0604
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0604
.L_lambda_simple_env_end_0604:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0604:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0604
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0604
.L_lambda_simple_params_end_0604:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0604
	jmp .L_lambda_simple_end_0604
.L_lambda_simple_code_0604:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0604
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0604:
	enter 0, 0
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
.L_lambda_simple_env_loop_0605:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_0605
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0605
.L_lambda_simple_env_end_0605:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0605:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0605
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0605
.L_lambda_simple_params_end_0605:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0605
	jmp .L_lambda_simple_end_0605
.L_lambda_simple_code_0605:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0605
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0605:
	enter 0, 0
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
.L_lambda_simple_env_loop_0606:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_0606
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0606
.L_lambda_simple_env_end_0606:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0606:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0606
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0606
.L_lambda_simple_params_end_0606:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0606
	jmp .L_lambda_simple_end_0606
.L_lambda_simple_code_0606:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0606
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0606:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param z
	push rax
	push 1
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var n
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_058d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_058d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_058d
.L_tc_recycle_frame_done_058d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0606:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0605:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0604:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
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
.L_lambda_simple_env_loop_0607:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_0607
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0607
.L_lambda_simple_env_end_0607:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0607:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0607
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0607
.L_lambda_simple_params_end_0607:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0607
	jmp .L_lambda_simple_end_0607
.L_lambda_simple_code_0607:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0607
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0607:
	enter 0, 0
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
.L_lambda_simple_env_loop_0608:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_0608
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0608
.L_lambda_simple_env_end_0608:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0608:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0608
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0608
.L_lambda_simple_params_end_0608:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0608
	jmp .L_lambda_simple_end_0608
.L_lambda_simple_code_0608:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0608
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0608:
	enter 0, 0
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
.L_lambda_simple_env_loop_0609:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_0609
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0609
.L_lambda_simple_env_end_0609:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0609:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0609
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0609
.L_lambda_simple_params_end_0609:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0609
	jmp .L_lambda_simple_end_0609
.L_lambda_simple_code_0609:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0609
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0609:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var b
	push rax
	push 1	; argc
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 1
	mov rax, PARAM(0)	; param c
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_058e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_058e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_058e
.L_tc_recycle_frame_done_058e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0609:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0608:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0607:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_058a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_058a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_058a
.L_tc_recycle_frame_done_058a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05fd:	; new closure is in rax
	push rax
	push 1
	mov rax, PARAM(0)	; param n
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_060a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_060a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_060a
.L_lambda_simple_env_end_060a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_060a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_060a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_060a
.L_lambda_simple_params_end_060a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_060a
	jmp .L_lambda_simple_end_060a
.L_lambda_simple_code_060a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_060a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_060a:
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
.L_lambda_simple_env_loop_060b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_060b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_060b
.L_lambda_simple_env_end_060b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_060b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_060b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_060b
.L_lambda_simple_params_end_060b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_060b
	jmp .L_lambda_simple_end_060b
.L_lambda_simple_code_060b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_060b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_060b:
	enter 0, 0
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
.L_lambda_simple_env_loop_060c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_060c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_060c
.L_lambda_simple_env_end_060c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_060c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_060c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_060c
.L_lambda_simple_params_end_060c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_060c
	jmp .L_lambda_simple_end_060c
.L_lambda_simple_code_060c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_060c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_060c:
	enter 0, 0
	mov rax, PARAM(0)	; param b
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_060c:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_060b:	; new closure is in rax
	push rax
	push 1	; argc
	mov rax, PARAM(0)	; param p
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_058f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_058f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_058f
.L_tc_recycle_frame_done_058f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_060a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0588:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0588
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0588
.L_tc_recycle_frame_done_0588:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05f5:	; new closure is in rax
	push rax
	push 1
	mov rax, PARAM(0)	; param b
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0587:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0587
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0587
.L_tc_recycle_frame_done_0587:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05f4:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05f3:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
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
.L_lambda_simple_env_loop_060d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_060d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_060d
.L_lambda_simple_env_end_060d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_060d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_060d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_060d
.L_lambda_simple_params_end_060d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_060d
	jmp .L_lambda_simple_end_060d
.L_lambda_simple_code_060d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_060d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_060d:
	enter 0, 0
	;debug: preparing a tail-call
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
.L_lambda_simple_env_loop_060e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_060e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_060e
.L_lambda_simple_env_end_060e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_060e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_060e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_060e
.L_lambda_simple_params_end_060e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_060e
	jmp .L_lambda_simple_end_060e
.L_lambda_simple_code_060e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_060e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_060e:
	enter 0, 0
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
.L_lambda_simple_env_loop_060f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_060f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_060f
.L_lambda_simple_env_end_060f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_060f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_060f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_060f
.L_lambda_simple_params_end_060f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_060f
	jmp .L_lambda_simple_end_060f
.L_lambda_simple_code_060f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_060f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_060f:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_060f:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_060e:	; new closure is in rax
	push rax
	push 1	; argc
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_0610:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0610
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0610
.L_lambda_simple_env_end_0610:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0610:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0610
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0610
.L_lambda_simple_params_end_0610:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0610
	jmp .L_lambda_simple_end_0610
.L_lambda_simple_code_0610:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0610
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0610:
	enter 0, 0
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
.L_lambda_simple_env_loop_0611:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_0611
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0611
.L_lambda_simple_env_end_0611:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0611:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0611
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0611
.L_lambda_simple_params_end_0611:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0611
	jmp .L_lambda_simple_end_0611
.L_lambda_simple_code_0611:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0611
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0611:
	enter 0, 0
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
.L_lambda_simple_env_loop_0612:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_0612
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0612
.L_lambda_simple_env_end_0612:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0612:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0612
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0612
.L_lambda_simple_params_end_0612:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0612
	jmp .L_lambda_simple_end_0612
.L_lambda_simple_code_0612:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0612
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0612:
	enter 0, 0
	mov rax, PARAM(0)	; param y
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0612:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0611:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0610:	; new closure is in rax
	push rax
	push 1
	mov rax, PARAM(0)	; param n
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0590:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0590
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0590
.L_tc_recycle_frame_done_0590:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_060d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param b
	push rax
	push 1
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 1
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
.L_lambda_simple_env_loop_0613:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0613
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0613
.L_lambda_simple_env_end_0613:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0613:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0613
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0613
.L_lambda_simple_params_end_0613:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0613
	jmp .L_lambda_simple_end_0613
.L_lambda_simple_code_0613:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0613
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0613:
	enter 0, 0
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
.L_lambda_simple_env_loop_0614:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0614
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0614
.L_lambda_simple_env_end_0614:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0614:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0614
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0614
.L_lambda_simple_params_end_0614:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0614
	jmp .L_lambda_simple_end_0614
.L_lambda_simple_code_0614:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0614
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0614:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 1	; argc
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_0615:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_0615
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0615
.L_lambda_simple_env_end_0615:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0615:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0615
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0615
.L_lambda_simple_params_end_0615:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0615
	jmp .L_lambda_simple_end_0615
.L_lambda_simple_code_0615:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0615
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0615:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_0616:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_0616
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0616
.L_lambda_simple_env_end_0616:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0616:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0616
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0616
.L_lambda_simple_params_end_0616:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0616
	jmp .L_lambda_simple_end_0616
.L_lambda_simple_code_0616:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0616
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0616:
	enter 0, 0
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
.L_lambda_simple_env_loop_0617:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_0617
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0617
.L_lambda_simple_env_end_0617:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0617:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0617
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0617
.L_lambda_simple_params_end_0617:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0617
	jmp .L_lambda_simple_end_0617
.L_lambda_simple_code_0617:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0617
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0617:
	enter 0, 0
	mov rax, PARAM(0)	; param y
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0617:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0616:	; new closure is in rax
	push rax
	push 1
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_0618:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_0618
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0618
.L_lambda_simple_env_end_0618:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0618:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0618
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0618
.L_lambda_simple_params_end_0618:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0618
	jmp .L_lambda_simple_end_0618
.L_lambda_simple_code_0618:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0618
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0618:
	enter 0, 0
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
.L_lambda_simple_env_loop_0619:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_0619
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0619
.L_lambda_simple_env_end_0619:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0619:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0619
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0619
.L_lambda_simple_params_end_0619:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0619
	jmp .L_lambda_simple_end_0619
.L_lambda_simple_code_0619:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0619
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0619:
	enter 0, 0
	mov rax, PARAM(0)	; param y
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0619:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0618:	; new closure is in rax
	push rax
	push 1
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
.L_lambda_simple_env_loop_061a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_061a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_061a
.L_lambda_simple_env_end_061a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_061a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_061a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_061a
.L_lambda_simple_params_end_061a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_061a
	jmp .L_lambda_simple_end_061a
.L_lambda_simple_code_061a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_061a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_061a:
	enter 0, 0
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
.L_lambda_simple_env_loop_061b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_061b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_061b
.L_lambda_simple_env_end_061b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_061b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_061b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_061b
.L_lambda_simple_params_end_061b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_061b
	jmp .L_lambda_simple_end_061b
.L_lambda_simple_code_061b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_061b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_061b:
	enter 0, 0
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
.L_lambda_simple_env_loop_061c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_061c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_061c
.L_lambda_simple_env_end_061c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_061c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_061c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_061c
.L_lambda_simple_params_end_061c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_061c
	jmp .L_lambda_simple_end_061c
.L_lambda_simple_code_061c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_061c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_061c:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var b
	push rax
	push 1	; argc
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 1
	mov rax, PARAM(0)	; param c
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0593:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0593
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0593
.L_tc_recycle_frame_done_0593:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_061c:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_061b:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_061a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_061d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_061d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_061d
.L_lambda_simple_env_end_061d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_061d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_061d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_061d
.L_lambda_simple_params_end_061d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_061d
	jmp .L_lambda_simple_end_061d
.L_lambda_simple_code_061d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_061d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_061d:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param p
	push rax
	push 1
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
.L_lambda_simple_env_loop_061e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_061e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_061e
.L_lambda_simple_env_end_061e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_061e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_061e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_061e
.L_lambda_simple_params_end_061e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_061e
	jmp .L_lambda_simple_end_061e
.L_lambda_simple_code_061e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_061e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_061e:
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
.L_lambda_simple_env_loop_061f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_061f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_061f
.L_lambda_simple_env_end_061f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_061f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_061f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_061f
.L_lambda_simple_params_end_061f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_061f
	jmp .L_lambda_simple_end_061f
.L_lambda_simple_code_061f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_061f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_061f:
	enter 0, 0
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
.L_lambda_simple_env_loop_0620:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_0620
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0620
.L_lambda_simple_env_end_0620:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0620:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0620
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0620
.L_lambda_simple_params_end_0620:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0620
	jmp .L_lambda_simple_end_0620
.L_lambda_simple_code_0620:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0620
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0620:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0620:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_061f:	; new closure is in rax
	push rax
	push 1	; argc
	mov rax, PARAM(0)	; param p
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0595:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0595
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0595
.L_tc_recycle_frame_done_0595:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_061e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param p
	push rax
	push 1
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
.L_lambda_simple_env_loop_0621:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_0621
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0621
.L_lambda_simple_env_end_0621:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0621:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0621
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0621
.L_lambda_simple_params_end_0621:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0621
	jmp .L_lambda_simple_end_0621
.L_lambda_simple_code_0621:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0621
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0621:
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
.L_lambda_simple_env_loop_0622:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_0622
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0622
.L_lambda_simple_env_end_0622:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0622:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0622
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0622
.L_lambda_simple_params_end_0622:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0622
	jmp .L_lambda_simple_end_0622
.L_lambda_simple_code_0622:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0622
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0622:
	enter 0, 0
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
.L_lambda_simple_env_loop_0623:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_0623
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0623
.L_lambda_simple_env_end_0623:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0623:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0623
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0623
.L_lambda_simple_params_end_0623:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0623
	jmp .L_lambda_simple_end_0623
.L_lambda_simple_code_0623:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0623
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0623:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0623:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0622:	; new closure is in rax
	push rax
	push 1	; argc
	mov rax, PARAM(0)	; param p
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0596:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0596
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0596
.L_tc_recycle_frame_done_0596:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0621:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
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
.L_lambda_simple_env_loop_0624:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_0624
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0624
.L_lambda_simple_env_end_0624:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0624:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0624
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0624
.L_lambda_simple_params_end_0624:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0624
	jmp .L_lambda_simple_end_0624
.L_lambda_simple_code_0624:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0624
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0624:
	enter 0, 0
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
.L_lambda_simple_env_loop_0625:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_0625
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0625
.L_lambda_simple_env_end_0625:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0625:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0625
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0625
.L_lambda_simple_params_end_0625:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0625
	jmp .L_lambda_simple_end_0625
.L_lambda_simple_code_0625:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0625
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0625:
	enter 0, 0
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
.L_lambda_simple_env_loop_0626:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_0626
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0626
.L_lambda_simple_env_end_0626:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0626:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0626
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0626
.L_lambda_simple_params_end_0626:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0626
	jmp .L_lambda_simple_end_0626
.L_lambda_simple_code_0626:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0626
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0626:
	enter 0, 0
	;debug: preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param z
	push rax
	push 1
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var n
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0597:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0597
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0597
.L_tc_recycle_frame_done_0597:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0626:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0625:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0624:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
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
.L_lambda_simple_env_loop_0627:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_0627
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0627
.L_lambda_simple_env_end_0627:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0627:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0627
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0627
.L_lambda_simple_params_end_0627:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0627
	jmp .L_lambda_simple_end_0627
.L_lambda_simple_code_0627:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0627
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0627:
	enter 0, 0
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
.L_lambda_simple_env_loop_0628:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_0628
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0628
.L_lambda_simple_env_end_0628:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0628:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0628
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0628
.L_lambda_simple_params_end_0628:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0628
	jmp .L_lambda_simple_end_0628
.L_lambda_simple_code_0628:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0628
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0628:
	enter 0, 0
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
.L_lambda_simple_env_loop_0629:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_0629
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0629
.L_lambda_simple_env_end_0629:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0629:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0629
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0629
.L_lambda_simple_params_end_0629:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0629
	jmp .L_lambda_simple_end_0629
.L_lambda_simple_code_0629:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0629
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0629:
	enter 0, 0
	;debug: preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var b
	push rax
	push 1	; argc
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 1
	mov rax, PARAM(0)	; param c
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0598:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0598
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0598
.L_tc_recycle_frame_done_0598:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0629:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0628:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0627:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0594:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0594
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0594
.L_tc_recycle_frame_done_0594:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_061d:	; new closure is in rax
	push rax
	push 1
	mov rax, PARAM(0)	; param n
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; argc
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
.L_lambda_simple_env_loop_062a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_062a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_062a
.L_lambda_simple_env_end_062a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_062a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_062a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_062a
.L_lambda_simple_params_end_062a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_062a
	jmp .L_lambda_simple_end_062a
.L_lambda_simple_code_062a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_062a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_062a:
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
.L_lambda_simple_env_loop_062b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_062b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_062b
.L_lambda_simple_env_end_062b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_062b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_062b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_062b
.L_lambda_simple_params_end_062b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_062b
	jmp .L_lambda_simple_end_062b
.L_lambda_simple_code_062b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_062b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_062b:
	enter 0, 0
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
.L_lambda_simple_env_loop_062c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_062c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_062c
.L_lambda_simple_env_end_062c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_062c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_062c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_062c
.L_lambda_simple_params_end_062c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_062c
	jmp .L_lambda_simple_end_062c
.L_lambda_simple_code_062c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_062c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_062c:
	enter 0, 0
	mov rax, PARAM(0)	; param b
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_062c:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_062b:	; new closure is in rax
	push rax
	push 1	; argc
	mov rax, PARAM(0)	; param p
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0599:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0599
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0599
.L_tc_recycle_frame_done_0599:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_062a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0592:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0592
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0592
.L_tc_recycle_frame_done_0592:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0615:	; new closure is in rax
	push rax
	push 1
	mov rax, PARAM(0)	; param b
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0591:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0591
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0591
.L_tc_recycle_frame_done_0591:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0614:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0613:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
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
.L_lambda_simple_env_loop_062d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_062d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_062d
.L_lambda_simple_env_end_062d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_062d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_062d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_062d
.L_lambda_simple_params_end_062d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_062d
	jmp .L_lambda_simple_end_062d
.L_lambda_simple_code_062d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_062d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_062d:
	enter 0, 0
	;debug: preparing a tail-call
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
.L_lambda_simple_env_loop_062e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_062e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_062e
.L_lambda_simple_env_end_062e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_062e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_062e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_062e
.L_lambda_simple_params_end_062e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_062e
	jmp .L_lambda_simple_end_062e
.L_lambda_simple_code_062e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_062e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_062e:
	enter 0, 0
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
.L_lambda_simple_env_loop_062f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_062f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_062f
.L_lambda_simple_env_end_062f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_062f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_062f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_062f
.L_lambda_simple_params_end_062f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_062f
	jmp .L_lambda_simple_end_062f
.L_lambda_simple_code_062f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_062f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_062f:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_062f:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_062e:	; new closure is in rax
	push rax
	push 1	; argc
	; preparing a non-tail-call
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
.L_lambda_simple_env_loop_0630:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0630
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0630
.L_lambda_simple_env_end_0630:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0630:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0630
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0630
.L_lambda_simple_params_end_0630:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0630
	jmp .L_lambda_simple_end_0630
.L_lambda_simple_code_0630:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0630
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0630:
	enter 0, 0
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
.L_lambda_simple_env_loop_0631:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_0631
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0631
.L_lambda_simple_env_end_0631:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0631:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0631
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0631
.L_lambda_simple_params_end_0631:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0631
	jmp .L_lambda_simple_end_0631
.L_lambda_simple_code_0631:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0631
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0631:
	enter 0, 0
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
.L_lambda_simple_env_loop_0632:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_0632
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0632
.L_lambda_simple_env_end_0632:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0632:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0632
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0632
.L_lambda_simple_params_end_0632:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0632
	jmp .L_lambda_simple_end_0632
.L_lambda_simple_code_0632:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0632
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0632:
	enter 0, 0
	mov rax, PARAM(0)	; param y
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0632:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0631:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0630:	; new closure is in rax
	push rax
	push 1
	mov rax, PARAM(0)	; param n
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_059a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_059a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_059a
.L_tc_recycle_frame_done_059a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_062d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
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
.L_lambda_simple_env_loop_0633:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0633
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0633
.L_lambda_simple_env_end_0633:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0633:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0633
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0633
.L_lambda_simple_params_end_0633:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0633
	jmp .L_lambda_simple_end_0633
.L_lambda_simple_code_0633:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0633
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0633:
	enter 0, 0
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
.L_lambda_simple_env_loop_0634:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0634
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0634
.L_lambda_simple_env_end_0634:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0634:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0634
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0634
.L_lambda_simple_params_end_0634:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0634
	jmp .L_lambda_simple_end_0634
.L_lambda_simple_code_0634:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0634
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0634:
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
.L_lambda_simple_env_loop_0635:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_0635
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0635
.L_lambda_simple_env_end_0635:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0635:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0635
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0635
.L_lambda_simple_params_end_0635:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0635
	jmp .L_lambda_simple_end_0635
.L_lambda_simple_code_0635:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0635
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0635:
	enter 0, 0
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
.L_lambda_simple_env_loop_0636:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_0636
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0636
.L_lambda_simple_env_end_0636:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0636:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0636
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0636
.L_lambda_simple_params_end_0636:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0636
	jmp .L_lambda_simple_end_0636
.L_lambda_simple_code_0636:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0636
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0636:
	enter 0, 0
	mov rax, PARAM(0)	; param y
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0636:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0635:	; new closure is in rax
	push rax
	push 1	; argc
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param b
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_059b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_059b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_059b
.L_tc_recycle_frame_done_059b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0634:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0633:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0586:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0586
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0586
.L_tc_recycle_frame_done_0586:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05f2:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05f1:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
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
        mov  r8, rbp
        push qword [rbp]
        mov rbp, rsp                    ; Saves the old stack pointer
        
        ; calculate argc
        mov rsi, PARAM(1)
	mov rdi, rsi                    ; rdi -> car list
	mov rcx, 0                      ; argc

L_bin_apply_calc_argc_loop:
	cmp rdi, sob_nil                
	je L_bin_apply_calc_argc_end_loop
	cmp byte [rdi], T_pair          ; validate if the list is a pair
        jne L_error_incorrect_type
	mov rdi, qword [rdi + 1 + 8]    ; rdi -> cdr list
	inc rcx
	jmp L_bin_apply_calc_argc_loop

L_bin_apply_calc_argc_end_loop:
        lea r11, [8 * (rcx - 3)]        ; Setup stack frame
        sub rsp, r11
        mov r10, qword [rbp + 8 * 1]    ; r10 points to return address
        mov qword [rsp], r10
        mov r10, PARAM(0)               ; Save environment of the closure
        cmp byte [r10], T_closure       ; validate if it's a closure
        jne L_error_incorrect_type
        mov rax, qword [r10 + 1]        ; rax -> env of closure
        mov qword [rsp + 8 * 1], rax    ; push env
        mov qword [rsp + 8 * 2], rcx    ; push argc
        ; Push all args into the stack
        lea r9, [rsp + 8 * 3]           ; r9 points to the address of the last arg pushed into the stack
	mov rdi, rsi                    ; rdi -> pointer to the list

L_bin_apply_args_push_loop:
	cmp rdi, sob_nil
	je L_bin_apply_call_and_exit
        mov rax, qword [rdi + 1]        ; rax -> car list
        mov qword [r9], rax
        add r9, 8                       ; point to the next address in the stack (where cdr list will be stored)
        mov rdi, qword [rdi + 1 + 8]    ; rax -> cdr list
	jmp L_bin_apply_args_push_loop
        
L_bin_apply_call_and_exit:
        mov  rbp, r8
        jmp SOB_CLOSURE_CODE(r10)       ; tail call the function to all elements
        

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
