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
.L_lambda_simple_env_loop_0458:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0458
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0458
.L_lambda_simple_env_end_0458:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0458:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0458
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0458
.L_lambda_simple_params_end_0458:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0458
	jmp .L_lambda_simple_end_0458
.L_lambda_simple_code_0458:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0458
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0458:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_069e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_069e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_069e
.L_tc_recycle_frame_done_069e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0458:	; new closure is in rax
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
.L_lambda_simple_env_loop_0459:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0459
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0459
.L_lambda_simple_env_end_0459:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0459:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0459
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0459
.L_lambda_simple_params_end_0459:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0459
	jmp .L_lambda_simple_end_0459
.L_lambda_simple_code_0459:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0459
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0459:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_069f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_069f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_069f
.L_tc_recycle_frame_done_069f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0459:	; new closure is in rax
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
.L_lambda_simple_env_loop_045a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_045a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_045a
.L_lambda_simple_env_end_045a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_045a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_045a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_045a
.L_lambda_simple_params_end_045a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_045a
	jmp .L_lambda_simple_end_045a
.L_lambda_simple_code_045a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_045a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_045a:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06a0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06a0
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06a0
.L_tc_recycle_frame_done_06a0:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_045a:	; new closure is in rax
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
.L_lambda_simple_env_loop_045b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_045b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_045b
.L_lambda_simple_env_end_045b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_045b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_045b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_045b
.L_lambda_simple_params_end_045b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_045b
	jmp .L_lambda_simple_end_045b
.L_lambda_simple_code_045b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_045b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_045b:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06a1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06a1
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06a1
.L_tc_recycle_frame_done_06a1:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_045b:	; new closure is in rax
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
.L_lambda_simple_env_loop_045c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_045c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_045c
.L_lambda_simple_env_end_045c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_045c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_045c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_045c
.L_lambda_simple_params_end_045c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_045c
	jmp .L_lambda_simple_end_045c
.L_lambda_simple_code_045c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_045c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_045c:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06a2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06a2
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06a2
.L_tc_recycle_frame_done_06a2:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_045c:	; new closure is in rax
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
.L_lambda_simple_env_loop_045d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_045d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_045d
.L_lambda_simple_env_end_045d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_045d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_045d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_045d
.L_lambda_simple_params_end_045d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_045d
	jmp .L_lambda_simple_end_045d
.L_lambda_simple_code_045d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_045d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_045d:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06a3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06a3
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06a3
.L_tc_recycle_frame_done_06a3:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_045d:	; new closure is in rax
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
.L_lambda_simple_env_loop_045e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_045e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_045e
.L_lambda_simple_env_end_045e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_045e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_045e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_045e
.L_lambda_simple_params_end_045e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_045e
	jmp .L_lambda_simple_end_045e
.L_lambda_simple_code_045e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_045e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_045e:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06a4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06a4
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06a4
.L_tc_recycle_frame_done_06a4:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_045e:	; new closure is in rax
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
.L_lambda_simple_env_loop_045f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_045f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_045f
.L_lambda_simple_env_end_045f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_045f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_045f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_045f
.L_lambda_simple_params_end_045f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_045f
	jmp .L_lambda_simple_end_045f
.L_lambda_simple_code_045f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_045f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_045f:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06a5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06a5
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06a5
.L_tc_recycle_frame_done_06a5:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_045f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0460:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0460
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0460
.L_lambda_simple_env_end_0460:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0460:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0460
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0460
.L_lambda_simple_params_end_0460:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0460
	jmp .L_lambda_simple_end_0460
.L_lambda_simple_code_0460:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0460
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0460:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06a6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06a6
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06a6
.L_tc_recycle_frame_done_06a6:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0460:	; new closure is in rax
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
.L_lambda_simple_env_loop_0461:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0461
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0461
.L_lambda_simple_env_end_0461:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0461:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0461
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0461
.L_lambda_simple_params_end_0461:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0461
	jmp .L_lambda_simple_end_0461
.L_lambda_simple_code_0461:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0461
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0461:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06a7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06a7
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06a7
.L_tc_recycle_frame_done_06a7:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0461:	; new closure is in rax
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
.L_lambda_simple_env_loop_0462:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0462
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0462
.L_lambda_simple_env_end_0462:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0462:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0462
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0462
.L_lambda_simple_params_end_0462:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0462
	jmp .L_lambda_simple_end_0462
.L_lambda_simple_code_0462:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0462
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0462:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06a8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06a8
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06a8
.L_tc_recycle_frame_done_06a8:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0462:	; new closure is in rax
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
.L_lambda_simple_env_loop_0463:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0463
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0463
.L_lambda_simple_env_end_0463:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0463:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0463
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0463
.L_lambda_simple_params_end_0463:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0463
	jmp .L_lambda_simple_end_0463
.L_lambda_simple_code_0463:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0463
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0463:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06a9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06a9
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06a9
.L_tc_recycle_frame_done_06a9:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0463:	; new closure is in rax
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
.L_lambda_simple_env_loop_0464:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0464
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0464
.L_lambda_simple_env_end_0464:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0464:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0464
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0464
.L_lambda_simple_params_end_0464:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0464
	jmp .L_lambda_simple_end_0464
.L_lambda_simple_code_0464:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0464
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0464:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06aa:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06aa
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06aa
.L_tc_recycle_frame_done_06aa:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0464:	; new closure is in rax
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
.L_lambda_simple_env_loop_0465:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0465
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0465
.L_lambda_simple_env_end_0465:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0465:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0465
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0465
.L_lambda_simple_params_end_0465:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0465
	jmp .L_lambda_simple_end_0465
.L_lambda_simple_code_0465:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0465
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0465:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06ab:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ab
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06ab
.L_tc_recycle_frame_done_06ab:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0465:	; new closure is in rax
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
.L_lambda_simple_env_loop_0466:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0466
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0466
.L_lambda_simple_env_end_0466:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0466:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0466
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0466
.L_lambda_simple_params_end_0466:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0466
	jmp .L_lambda_simple_end_0466
.L_lambda_simple_code_0466:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0466
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0466:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06ac:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ac
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06ac
.L_tc_recycle_frame_done_06ac:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0466:	; new closure is in rax
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
.L_lambda_simple_env_loop_0467:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0467
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0467
.L_lambda_simple_env_end_0467:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0467:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0467
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0467
.L_lambda_simple_params_end_0467:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0467
	jmp .L_lambda_simple_end_0467
.L_lambda_simple_code_0467:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0467
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0467:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06ad:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ad
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06ad
.L_tc_recycle_frame_done_06ad:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0467:	; new closure is in rax
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
.L_lambda_simple_env_loop_0468:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0468
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0468
.L_lambda_simple_env_end_0468:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0468:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0468
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0468
.L_lambda_simple_params_end_0468:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0468
	jmp .L_lambda_simple_end_0468
.L_lambda_simple_code_0468:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0468
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0468:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06ae:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ae
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06ae
.L_tc_recycle_frame_done_06ae:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0468:	; new closure is in rax
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
.L_lambda_simple_env_loop_0469:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0469
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0469
.L_lambda_simple_env_end_0469:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0469:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0469
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0469
.L_lambda_simple_params_end_0469:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0469
	jmp .L_lambda_simple_end_0469
.L_lambda_simple_code_0469:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0469
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0469:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06af:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06af
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06af
.L_tc_recycle_frame_done_06af:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0469:	; new closure is in rax
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
.L_lambda_simple_env_loop_046a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_046a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_046a
.L_lambda_simple_env_end_046a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_046a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_046a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_046a
.L_lambda_simple_params_end_046a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_046a
	jmp .L_lambda_simple_end_046a
.L_lambda_simple_code_046a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_046a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_046a:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06b0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06b0
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06b0
.L_tc_recycle_frame_done_06b0:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_046a:	; new closure is in rax
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
.L_lambda_simple_env_loop_046b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_046b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_046b
.L_lambda_simple_env_end_046b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_046b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_046b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_046b
.L_lambda_simple_params_end_046b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_046b
	jmp .L_lambda_simple_end_046b
.L_lambda_simple_code_046b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_046b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_046b:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06b1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06b1
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06b1
.L_tc_recycle_frame_done_06b1:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_046b:	; new closure is in rax
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
.L_lambda_simple_env_loop_046c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_046c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_046c
.L_lambda_simple_env_end_046c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_046c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_046c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_046c
.L_lambda_simple_params_end_046c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_046c
	jmp .L_lambda_simple_end_046c
.L_lambda_simple_code_046c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_046c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_046c:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06b2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06b2
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06b2
.L_tc_recycle_frame_done_06b2:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_046c:	; new closure is in rax
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
.L_lambda_simple_env_loop_046d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_046d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_046d
.L_lambda_simple_env_end_046d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_046d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_046d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_046d
.L_lambda_simple_params_end_046d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_046d
	jmp .L_lambda_simple_end_046d
.L_lambda_simple_code_046d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_046d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_046d:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06b3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06b3
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06b3
.L_tc_recycle_frame_done_06b3:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_046d:	; new closure is in rax
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
.L_lambda_simple_env_loop_046e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_046e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_046e
.L_lambda_simple_env_end_046e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_046e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_046e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_046e
.L_lambda_simple_params_end_046e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_046e
	jmp .L_lambda_simple_end_046e
.L_lambda_simple_code_046e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_046e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_046e:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06b4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06b4
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06b4
.L_tc_recycle_frame_done_06b4:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_046e:	; new closure is in rax
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
.L_lambda_simple_env_loop_046f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_046f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_046f
.L_lambda_simple_env_end_046f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_046f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_046f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_046f
.L_lambda_simple_params_end_046f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_046f
	jmp .L_lambda_simple_end_046f
.L_lambda_simple_code_046f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_046f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_046f:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06b5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06b5
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06b5
.L_tc_recycle_frame_done_06b5:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_046f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0470:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0470
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0470
.L_lambda_simple_env_end_0470:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0470:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0470
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0470
.L_lambda_simple_params_end_0470:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0470
	jmp .L_lambda_simple_end_0470
.L_lambda_simple_code_0470:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0470
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0470:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06b6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06b6
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06b6
.L_tc_recycle_frame_done_06b6:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0470:	; new closure is in rax
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
.L_lambda_simple_env_loop_0471:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0471
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0471
.L_lambda_simple_env_end_0471:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0471:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0471
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0471
.L_lambda_simple_params_end_0471:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0471
	jmp .L_lambda_simple_end_0471
.L_lambda_simple_code_0471:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0471
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0471:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06b7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06b7
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06b7
.L_tc_recycle_frame_done_06b7:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0471:	; new closure is in rax
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
.L_lambda_simple_env_loop_0472:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0472
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0472
.L_lambda_simple_env_end_0472:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0472:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0472
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0472
.L_lambda_simple_params_end_0472:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0472
	jmp .L_lambda_simple_end_0472
.L_lambda_simple_code_0472:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0472
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0472:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06b8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06b8
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06b8
.L_tc_recycle_frame_done_06b8:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0472:	; new closure is in rax
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
.L_lambda_simple_env_loop_0473:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0473
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0473
.L_lambda_simple_env_end_0473:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0473:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0473
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0473
.L_lambda_simple_params_end_0473:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0473
	jmp .L_lambda_simple_end_0473
.L_lambda_simple_code_0473:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0473
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0473:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06b9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06b9
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06b9
.L_tc_recycle_frame_done_06b9:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0473:	; new closure is in rax
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
.L_lambda_simple_env_loop_0474:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0474
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0474
.L_lambda_simple_env_end_0474:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0474:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0474
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0474
.L_lambda_simple_params_end_0474:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0474
	jmp .L_lambda_simple_end_0474
.L_lambda_simple_code_0474:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0474
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0474:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_004d
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03a1
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06ba:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ba
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06ba
.L_tc_recycle_frame_done_06ba:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03a1
.L_if_else_03a1:
	mov rax, L_constants + 2
.L_if_end_03a1:
.L_or_end_004d:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0474:	; new closure is in rax
	mov qword [free_var_96], rax
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
.L_lambda_opt_env_loop_00a9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_00a9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00a9
.L_lambda_opt_env_end_00a9:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00a9:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_00a9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00a9
.L_lambda_opt_params_end_00a9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00a9
	jmp .L_lambda_opt_end_00a9
.L_lambda_opt_code_00a9:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_00a9
	ja .L_lambda_opt_arity_check_more_00a9
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00a9: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_01fa:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_01fa
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_01fa
.L_lambda_opt_stack_shrink_loop_exit_01fa:
	lea r10, [rsp + 8* 0 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_01fb:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_01fb
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_01fb
.L_lambda_opt_stack_shrink_loop_exit_01fb:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00a9
.L_lambda_opt_arity_check_exact_00a9: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_01f9:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_01f9
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_01f9
.L_lambda_opt_stack_shrink_loop_exit_01f9:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00a9:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	mov rax, PARAM(0)	; param args
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_00a9:	; new closure is in rax
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
.L_lambda_simple_env_loop_0475:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0475
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0475
.L_lambda_simple_env_end_0475:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0475:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0475
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0475
.L_lambda_simple_params_end_0475:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0475
	jmp .L_lambda_simple_end_0475
.L_lambda_simple_code_0475:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0475
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0475:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	cmp rax, sob_boolean_false
	je .L_if_else_03a2
	mov rax, L_constants + 2
	jmp .L_if_end_03a2
.L_if_else_03a2:
	mov rax, L_constants + 3
.L_if_end_03a2:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0475:	; new closure is in rax
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
.L_lambda_simple_env_loop_0476:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0476
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0476
.L_lambda_simple_env_end_0476:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0476:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0476
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0476
.L_lambda_simple_params_end_0476:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0476
	jmp .L_lambda_simple_end_0476
.L_lambda_simple_code_0476:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0476
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0476:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param q
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_004e
	; preparing a tail-call
	mov rax, PARAM(0)	; param q
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06bb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06bb
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06bb
.L_tc_recycle_frame_done_06bb:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_004e:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0476:	; new closure is in rax
	mov qword [free_var_114], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_0477:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0477
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0477
.L_lambda_simple_env_end_0477:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0477:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0477
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0477
.L_lambda_simple_params_end_0477:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0477
	jmp .L_lambda_simple_end_0477
.L_lambda_simple_code_0477:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0477
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0477:
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
.L_lambda_simple_env_loop_0478:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0478
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0478
.L_lambda_simple_env_end_0478:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0478:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0478
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0478
.L_lambda_simple_params_end_0478:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0478
	jmp .L_lambda_simple_end_0478
.L_lambda_simple_code_0478:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0478
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0478:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03a3
	mov rax, PARAM(0)	; param a
	jmp .L_if_end_03a3
.L_if_else_03a3:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
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
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06bc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06bc
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06bc
.L_tc_recycle_frame_done_06bc:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03a3:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0478:	; new closure is in rax
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
.L_lambda_opt_env_loop_00aa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00aa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00aa
.L_lambda_opt_env_end_00aa:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00aa:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00aa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00aa
.L_lambda_opt_params_end_00aa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00aa
	jmp .L_lambda_opt_end_00aa
.L_lambda_opt_code_00aa:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_00aa
	ja .L_lambda_opt_arity_check_more_00aa
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00aa: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_01fd:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_01fd
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_01fd
.L_lambda_opt_stack_shrink_loop_exit_01fd:
	lea r10, [rsp + 8* 1 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_01fe:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_01fe
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_01fe
.L_lambda_opt_stack_shrink_loop_exit_01fe:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00aa
.L_lambda_opt_arity_check_exact_00aa: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_01fc:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_01fc
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_01fc
.L_lambda_opt_stack_shrink_loop_exit_01fc:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00aa:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06bd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06bd
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06bd
.L_tc_recycle_frame_done_06bd:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_00aa:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0477:	; new closure is in rax
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
	push 1	; arg count
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
.L_lambda_simple_env_loop_0479:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0479
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0479
.L_lambda_simple_env_end_0479:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0479:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0479
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0479
.L_lambda_simple_params_end_0479:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0479
	jmp .L_lambda_simple_end_0479
.L_lambda_simple_code_0479:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0479
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0479:
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
.L_lambda_simple_env_loop_047a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_047a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_047a
.L_lambda_simple_env_end_047a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_047a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_047a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_047a
.L_lambda_simple_params_end_047a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_047a
	jmp .L_lambda_simple_end_047a
.L_lambda_simple_code_047a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_047a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_047a:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03a4
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
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
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06be:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06be
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06be
.L_tc_recycle_frame_done_06be:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03a4
.L_if_else_03a4:
	mov rax, PARAM(0)	; param a
.L_if_end_03a4:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_047a:	; new closure is in rax
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
.L_lambda_opt_env_loop_00ab:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00ab
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00ab
.L_lambda_opt_env_end_00ab:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00ab:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00ab
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00ab
.L_lambda_opt_params_end_00ab:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00ab
	jmp .L_lambda_opt_end_00ab
.L_lambda_opt_code_00ab:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_00ab
	ja .L_lambda_opt_arity_check_more_00ab
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00ab: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0200:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0200
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0200
.L_lambda_opt_stack_shrink_loop_exit_0200:
	lea r10, [rsp + 8* 1 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_0201:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0201
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0201
.L_lambda_opt_stack_shrink_loop_exit_0201:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00ab
.L_lambda_opt_arity_check_exact_00ab: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_01ff:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_01ff
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_01ff
.L_lambda_opt_stack_shrink_loop_exit_01ff:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00ab:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
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
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06bf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06bf
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06bf
.L_tc_recycle_frame_done_06bf:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_00ab:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0479:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_33], rax
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
.L_lambda_opt_env_loop_00ac:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_00ac
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00ac
.L_lambda_opt_env_end_00ac:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00ac:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_00ac
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00ac
.L_lambda_opt_params_end_00ac:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00ac
	jmp .L_lambda_opt_end_00ac
.L_lambda_opt_code_00ac:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_00ac
	ja .L_lambda_opt_arity_check_more_00ac
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00ac: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0203:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0203
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0203
.L_lambda_opt_stack_shrink_loop_exit_0203:
	lea r10, [rsp + 8* 1 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_0204:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0204
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0204
.L_lambda_opt_stack_shrink_loop_exit_0204:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00ac
.L_lambda_opt_arity_check_exact_00ac: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0202:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0202
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0202
.L_lambda_opt_stack_shrink_loop_exit_0202:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00ac:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_047b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_047b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_047b
.L_lambda_simple_env_end_047b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_047b:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_047b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_047b
.L_lambda_simple_params_end_047b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_047b
	jmp .L_lambda_simple_end_047b
.L_lambda_simple_code_047b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_047b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_047b:
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
.L_lambda_simple_env_loop_047c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_047c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_047c
.L_lambda_simple_env_end_047c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_047c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_047c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_047c
.L_lambda_simple_params_end_047c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_047c
	jmp .L_lambda_simple_end_047c
.L_lambda_simple_code_047c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_047c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_047c:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03a5
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
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
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_004f
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_103]	; free var map
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
.L_tc_recycle_frame_loop_06c1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06c1
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06c1
.L_tc_recycle_frame_done_06c1:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_004f:
	jmp .L_if_end_03a5
.L_if_else_03a5:
	mov rax, L_constants + 2
.L_if_end_03a5:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_047c:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param loop
	pop qword [rax]
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03a6
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06c2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06c2
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06c2
.L_tc_recycle_frame_done_06c2:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03a6
.L_if_else_03a6:
	mov rax, L_constants + 2
.L_if_end_03a6:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_047b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_06c0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06c0
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06c0
.L_tc_recycle_frame_done_06c0:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_00ac:	; new closure is in rax
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
.L_lambda_opt_env_loop_00ad:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_00ad
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00ad
.L_lambda_opt_env_end_00ad:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00ad:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_00ad
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00ad
.L_lambda_opt_params_end_00ad:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00ad
	jmp .L_lambda_opt_end_00ad
.L_lambda_opt_code_00ad:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_00ad
	ja .L_lambda_opt_arity_check_more_00ad
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00ad: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0206:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0206
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0206
.L_lambda_opt_stack_shrink_loop_exit_0206:
	lea r10, [rsp + 8* 1 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_0207:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0207
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0207
.L_lambda_opt_stack_shrink_loop_exit_0207:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00ad
.L_lambda_opt_arity_check_exact_00ad: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0205:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0205
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0205
.L_lambda_opt_stack_shrink_loop_exit_0205:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00ad:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_047d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_047d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_047d
.L_lambda_simple_env_end_047d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_047d:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_047d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_047d
.L_lambda_simple_params_end_047d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_047d
	jmp .L_lambda_simple_end_047d
.L_lambda_simple_code_047d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_047d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_047d:
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
.L_lambda_simple_env_loop_047e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_047e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_047e
.L_lambda_simple_env_end_047e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_047e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_047e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_047e
.L_lambda_simple_params_end_047e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_047e
	jmp .L_lambda_simple_end_047e
.L_lambda_simple_code_047e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_047e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_047e:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0050
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
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
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03a7
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_103]	; free var map
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
.L_tc_recycle_frame_loop_06c4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06c4
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06c4
.L_tc_recycle_frame_done_06c4:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03a7
.L_if_else_03a7:
	mov rax, L_constants + 2
.L_if_end_03a7:
.L_or_end_0050:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_047e:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param loop
	pop qword [rax]
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0051
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03a8
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06c5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06c5
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06c5
.L_tc_recycle_frame_done_06c5:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03a8
.L_if_else_03a8:
	mov rax, L_constants + 2
.L_if_end_03a8:
.L_or_end_0051:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_047d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_06c3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06c3
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06c3
.L_tc_recycle_frame_done_06c3:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_00ad:	; new closure is in rax
	mov qword [free_var_31], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2	; arg count
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
.L_lambda_simple_env_loop_047f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_047f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_047f
.L_lambda_simple_env_end_047f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_047f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_047f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_047f
.L_lambda_simple_params_end_047f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_047f
	jmp .L_lambda_simple_end_047f
.L_lambda_simple_code_047f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_047f
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_047f:
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
.L_lambda_simple_env_loop_0480:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0480
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0480
.L_lambda_simple_env_end_0480:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0480:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0480
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0480
.L_lambda_simple_params_end_0480:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0480
	jmp .L_lambda_simple_end_0480
.L_lambda_simple_code_0480:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0480
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0480:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03a9
	mov rax, L_constants + 1
	jmp .L_if_end_03a9
.L_if_else_03a9:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
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
	push 2	; arg count
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
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06c6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06c6
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06c6
.L_tc_recycle_frame_done_06c6:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03a9:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0480:	; new closure is in rax
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
.L_lambda_simple_env_loop_0481:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0481
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0481
.L_lambda_simple_env_end_0481:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0481:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0481
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0481
.L_lambda_simple_params_end_0481:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0481
	jmp .L_lambda_simple_end_0481
.L_lambda_simple_code_0481:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0481
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0481:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03aa
	mov rax, L_constants + 1
	jmp .L_if_end_03aa
.L_if_else_03aa:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
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
	push 2	; arg count
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
	push 2	; arg count
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
	push 2	; arg count
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
.L_tc_recycle_frame_loop_06c7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06c7
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06c7
.L_tc_recycle_frame_done_06c7:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03aa:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0481:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param map-list
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
.L_lambda_opt_env_loop_00ae:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00ae
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00ae
.L_lambda_opt_env_end_00ae:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00ae:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_00ae
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00ae
.L_lambda_opt_params_end_00ae:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00ae
	jmp .L_lambda_opt_end_00ae
.L_lambda_opt_code_00ae:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_00ae
	ja .L_lambda_opt_arity_check_more_00ae
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00ae: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0209:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0209
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0209
.L_lambda_opt_stack_shrink_loop_exit_0209:
	lea r10, [rsp + 8* 1 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_020a:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_020a
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_020a
.L_lambda_opt_stack_shrink_loop_exit_020a:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00ae
.L_lambda_opt_arity_check_exact_00ae: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0208:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0208
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0208
.L_lambda_opt_stack_shrink_loop_exit_0208:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00ae:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ab
	mov rax, L_constants + 1
	jmp .L_if_end_03ab
.L_if_else_03ab:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06c8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06c8
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06c8
.L_tc_recycle_frame_done_06c8:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03ab:
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_00ae:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_047f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0482:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0482
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0482
.L_lambda_simple_env_end_0482:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0482:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0482
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0482
.L_lambda_simple_params_end_0482:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0482
	jmp .L_lambda_simple_end_0482
.L_lambda_simple_code_0482:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0482
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0482:
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_0483:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0483
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0483
.L_lambda_simple_env_end_0483:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0483:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0483
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0483
.L_lambda_simple_params_end_0483:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0483
	jmp .L_lambda_simple_end_0483
.L_lambda_simple_code_0483:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0483
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0483:
	enter 0, 0
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06ca:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ca
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06ca
.L_tc_recycle_frame_done_06ca:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0483:	; new closure is in rax
	push rax
	push 3	; arg count
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
.L_tc_recycle_frame_loop_06c9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06c9
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06c9
.L_tc_recycle_frame_done_06c9:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0482:	; new closure is in rax
	mov qword [free_var_118], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2	; arg count
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
.L_lambda_simple_env_loop_0484:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0484
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0484
.L_lambda_simple_env_end_0484:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0484:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0484
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0484
.L_lambda_simple_params_end_0484:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0484
	jmp .L_lambda_simple_end_0484
.L_lambda_simple_code_0484:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0484
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0484:
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
.L_lambda_simple_env_loop_0485:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0485
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0485
.L_lambda_simple_env_end_0485:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0485:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0485
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0485
.L_lambda_simple_params_end_0485:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0485
	jmp .L_lambda_simple_end_0485
.L_lambda_simple_code_0485:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0485
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0485:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ac
	mov rax, PARAM(0)	; param s1
	jmp .L_if_end_03ac
.L_if_else_03ac:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1	; arg count
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
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06cb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06cb
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06cb
.L_tc_recycle_frame_done_06cb:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03ac:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0485:	; new closure is in rax
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
.L_lambda_simple_env_loop_0486:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0486
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0486
.L_lambda_simple_env_end_0486:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0486:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0486
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0486
.L_lambda_simple_params_end_0486:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0486
	jmp .L_lambda_simple_end_0486
.L_lambda_simple_code_0486:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0486
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0486:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ad
	mov rax, PARAM(1)	; param s2
	jmp .L_if_end_03ad
.L_if_else_03ad:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s2
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
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
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06cc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06cc
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06cc
.L_tc_recycle_frame_done_06cc:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03ad:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0486:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param run-2
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
.L_lambda_opt_env_loop_00af:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00af
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00af
.L_lambda_opt_env_end_00af:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00af:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_00af
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00af
.L_lambda_opt_params_end_00af:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00af
	jmp .L_lambda_opt_end_00af
.L_lambda_opt_code_00af:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_00af
	ja .L_lambda_opt_arity_check_more_00af
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00af: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_020c:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_020c
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_020c
.L_lambda_opt_stack_shrink_loop_exit_020c:
	lea r10, [rsp + 8* 0 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_020d:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_020d
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_020d
.L_lambda_opt_stack_shrink_loop_exit_020d:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00af
.L_lambda_opt_arity_check_exact_00af: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_020b:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_020b
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_020b
.L_lambda_opt_stack_shrink_loop_exit_020b:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00af:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ae
	mov rax, L_constants + 1
	jmp .L_if_end_03ae
.L_if_else_03ae:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
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
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06cd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06cd
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06cd
.L_tc_recycle_frame_done_06cd:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03ae:
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_00af:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0484:	; new closure is in rax
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
	push 1	; arg count
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
.L_lambda_simple_env_loop_0487:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0487
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0487
.L_lambda_simple_env_end_0487:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0487:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0487
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0487
.L_lambda_simple_params_end_0487:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0487
	jmp .L_lambda_simple_end_0487
.L_lambda_simple_code_0487:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0487
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0487:
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
.L_lambda_simple_env_loop_0488:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0488
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0488
.L_lambda_simple_env_end_0488:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0488:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0488
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0488
.L_lambda_simple_params_end_0488:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0488
	jmp .L_lambda_simple_end_0488
.L_lambda_simple_code_0488:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0488
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0488:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_110]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03af
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_03af
.L_if_else_03af:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
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
	push 2	; arg count
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
	push 3	; arg count
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
.L_tc_recycle_frame_loop_06ce:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ce
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06ce
.L_tc_recycle_frame_done_06ce:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03af:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0488:	; new closure is in rax
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
.L_lambda_opt_env_loop_00b0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00b0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b0
.L_lambda_opt_env_end_00b0:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b0:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00b0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b0
.L_lambda_opt_params_end_00b0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b0
	jmp .L_lambda_opt_end_00b0
.L_lambda_opt_code_00b0:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 3
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_arity_check_exact_00b0
	ja .L_lambda_opt_arity_check_more_00b0
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00b0: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_020f:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_020f
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_020f
.L_lambda_opt_stack_shrink_loop_exit_020f:
	lea r10, [rsp + 8* 2 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 5
	mov rcx, 4 + 2
.L_lambda_opt_stack_shrink_loop_0210:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0210
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0210
.L_lambda_opt_stack_shrink_loop_exit_0210:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00b0
.L_lambda_opt_arity_check_exact_00b0: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_020e:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_020e
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_020e
.L_lambda_opt_stack_shrink_loop_exit_020e:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00b0:
	mov qword [rsp + 8*2], 3
	enter 0, 0
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06cf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06cf
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06cf
.L_tc_recycle_frame_done_06cf:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 3)
.L_lambda_opt_end_00b0:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0487:	; new closure is in rax
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
	push 1	; arg count
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
.L_lambda_simple_env_loop_0489:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0489
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0489
.L_lambda_simple_env_end_0489:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0489:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0489
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0489
.L_lambda_simple_params_end_0489:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0489
	jmp .L_lambda_simple_end_0489
.L_lambda_simple_code_0489:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0489
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0489:
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
.L_lambda_simple_env_loop_048a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_048a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_048a
.L_lambda_simple_env_end_048a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_048a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_048a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_048a
.L_lambda_simple_params_end_048a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_048a
	jmp .L_lambda_simple_end_048a
.L_lambda_simple_code_048a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_048a
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_048a:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_110]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03b0
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_03b0
.L_if_else_03b0:
	; preparing a tail-call
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
	push 2	; arg count
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
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
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
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_103]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_06d0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d0
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06d0
.L_tc_recycle_frame_done_06d0:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03b0:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_048a:	; new closure is in rax
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
.L_lambda_opt_env_loop_00b1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00b1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b1
.L_lambda_opt_env_end_00b1:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b1:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00b1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b1
.L_lambda_opt_params_end_00b1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b1
	jmp .L_lambda_opt_end_00b1
.L_lambda_opt_code_00b1:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 3
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_arity_check_exact_00b1
	ja .L_lambda_opt_arity_check_more_00b1
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00b1: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0212:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0212
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0212
.L_lambda_opt_stack_shrink_loop_exit_0212:
	lea r10, [rsp + 8* 2 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 5
	mov rcx, 4 + 2
.L_lambda_opt_stack_shrink_loop_0213:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0213
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0213
.L_lambda_opt_stack_shrink_loop_exit_0213:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00b1
.L_lambda_opt_arity_check_exact_00b1: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0211:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0211
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0211
.L_lambda_opt_stack_shrink_loop_exit_0211:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00b1:
	mov qword [rsp + 8*2], 3
	enter 0, 0
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06d1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d1
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06d1
.L_tc_recycle_frame_done_06d1:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 3)
.L_lambda_opt_end_00b1:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0489:	; new closure is in rax
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
.L_lambda_simple_env_loop_048b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_048b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_048b
.L_lambda_simple_env_end_048b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_048b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_048b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_048b
.L_lambda_simple_params_end_048b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_048b
	jmp .L_lambda_simple_end_048b
.L_lambda_simple_code_048b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_048b
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_048b:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2187
	push rax
	mov rax, L_constants + 2178
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_06d2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d2
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06d2
.L_tc_recycle_frame_done_06d2:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_048b:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_048c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_048c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_048c
.L_lambda_simple_env_end_048c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_048c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_048c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_048c
.L_lambda_simple_params_end_048c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_048c
	jmp .L_lambda_simple_end_048c
.L_lambda_simple_code_048c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_048c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_048c:
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_048d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_048d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_048d
.L_lambda_simple_env_end_048d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_048d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_048d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_048d
.L_lambda_simple_params_end_048d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_048d
	jmp .L_lambda_simple_end_048d
.L_lambda_simple_code_048d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_048d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_048d:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03bc
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03b3
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06d4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d4
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06d4
.L_tc_recycle_frame_done_06d4:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03b3
.L_if_else_03b3:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03b2
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06d5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d5
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06d5
.L_tc_recycle_frame_done_06d5:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03b2
.L_if_else_03b2:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03b1
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_90]	; free var integer->real
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
.L_tc_recycle_frame_loop_06d6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d6
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06d6
.L_tc_recycle_frame_done_06d6:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03b1
.L_if_else_03b1:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06d7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d7
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06d7
.L_tc_recycle_frame_done_06d7:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03b1:
.L_if_end_03b2:
.L_if_end_03b3:
	jmp .L_if_end_03bc
.L_if_else_03bc:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03bb
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03b6
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06d8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d8
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06d8
.L_tc_recycle_frame_done_06d8:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03b6
.L_if_else_03b6:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03b5
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06d9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d9
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06d9
.L_tc_recycle_frame_done_06d9:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03b5
.L_if_else_03b5:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03b4
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_87]	; free var fraction->real
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
.L_tc_recycle_frame_loop_06da:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06da
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06da
.L_tc_recycle_frame_done_06da:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03b4
.L_if_else_03b4:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06db:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06db
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06db
.L_tc_recycle_frame_done_06db:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03b4:
.L_if_end_03b5:
.L_if_end_03b6:
	jmp .L_if_end_03bb
.L_if_else_03bb:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ba
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03b9
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06dc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06dc
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06dc
.L_tc_recycle_frame_done_06dc:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03b9
.L_if_else_03b9:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03b8
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06dd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06dd
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06dd
.L_tc_recycle_frame_done_06dd:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03b8
.L_if_else_03b8:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03b7
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06de:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06de
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06de
.L_tc_recycle_frame_done_06de:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03b7
.L_if_else_03b7:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06df:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06df
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06df
.L_tc_recycle_frame_done_06df:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03b7:
.L_if_end_03b8:
.L_if_end_03b9:
	jmp .L_if_end_03ba
.L_if_else_03ba:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06e0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e0
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06e0
.L_tc_recycle_frame_done_06e0:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03ba:
.L_if_end_03bb:
.L_if_end_03bc:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_048d:	; new closure is in rax
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
.L_lambda_simple_env_loop_048e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_048e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_048e
.L_lambda_simple_env_end_048e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_048e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_048e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_048e
.L_lambda_simple_params_end_048e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_048e
	jmp .L_lambda_simple_end_048e
.L_lambda_simple_code_048e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_048e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_048e:
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
.L_lambda_opt_env_loop_00b2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_00b2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b2
.L_lambda_opt_env_end_00b2:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b2:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00b2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b2
.L_lambda_opt_params_end_00b2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b2
	jmp .L_lambda_opt_end_00b2
.L_lambda_opt_code_00b2:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_00b2
	ja .L_lambda_opt_arity_check_more_00b2
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00b2: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0215:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0215
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0215
.L_lambda_opt_stack_shrink_loop_exit_0215:
	lea r10, [rsp + 8* 0 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_0216:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0216
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0216
.L_lambda_opt_stack_shrink_loop_exit_0216:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00b2
.L_lambda_opt_arity_check_exact_00b2: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0214:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0214
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0214
.L_lambda_opt_stack_shrink_loop_exit_0214:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00b2:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2135
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin+
	push rax
	push 3	; arg count
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
.L_tc_recycle_frame_loop_06e1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e1
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06e1
.L_tc_recycle_frame_done_06e1:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_00b2:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_048e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_06d3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d3
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06d3
.L_tc_recycle_frame_done_06d3:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_048c:	; new closure is in rax
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
.L_lambda_simple_env_loop_048f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_048f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_048f
.L_lambda_simple_env_end_048f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_048f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_048f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_048f
.L_lambda_simple_params_end_048f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_048f
	jmp .L_lambda_simple_end_048f
.L_lambda_simple_code_048f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_048f
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_048f:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2187
	push rax
	mov rax, L_constants + 2251
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_06e2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e2
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06e2
.L_tc_recycle_frame_done_06e2:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_048f:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_0490:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0490
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0490
.L_lambda_simple_env_end_0490:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0490:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0490
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0490
.L_lambda_simple_params_end_0490:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0490
	jmp .L_lambda_simple_end_0490
.L_lambda_simple_code_0490:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0490
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0490:
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_0491:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0491
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0491
.L_lambda_simple_env_end_0491:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0491:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0491
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0491
.L_lambda_simple_params_end_0491:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0491
	jmp .L_lambda_simple_end_0491
.L_lambda_simple_code_0491:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0491
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0491:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03c8
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03bf
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06e4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e4
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06e4
.L_tc_recycle_frame_done_06e4:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03bf
.L_if_else_03bf:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03be
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06e5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e5
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06e5
.L_tc_recycle_frame_done_06e5:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03be
.L_if_else_03be:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_115]	; free var real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03bd
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_90]	; free var integer->real
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
.L_tc_recycle_frame_loop_06e6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e6
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06e6
.L_tc_recycle_frame_done_06e6:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03bd
.L_if_else_03bd:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06e7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e7
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06e7
.L_tc_recycle_frame_done_06e7:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03bd:
.L_if_end_03be:
.L_if_end_03bf:
	jmp .L_if_end_03c8
.L_if_else_03c8:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03c7
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03c2
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06e8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e8
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06e8
.L_tc_recycle_frame_done_06e8:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03c2
.L_if_else_03c2:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03c1
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06e9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e9
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06e9
.L_tc_recycle_frame_done_06e9:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03c1
.L_if_else_03c1:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03c0
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_87]	; free var fraction->real
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
.L_tc_recycle_frame_loop_06ea:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ea
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06ea
.L_tc_recycle_frame_done_06ea:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03c0
.L_if_else_03c0:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06eb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06eb
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06eb
.L_tc_recycle_frame_done_06eb:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03c0:
.L_if_end_03c1:
.L_if_end_03c2:
	jmp .L_if_end_03c7
.L_if_else_03c7:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03c6
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03c5
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06ec:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ec
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06ec
.L_tc_recycle_frame_done_06ec:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03c5
.L_if_else_03c5:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03c4
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06ed:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ed
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06ed
.L_tc_recycle_frame_done_06ed:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03c4
.L_if_else_03c4:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03c3
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06ee:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ee
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06ee
.L_tc_recycle_frame_done_06ee:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03c3
.L_if_else_03c3:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06ef:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ef
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06ef
.L_tc_recycle_frame_done_06ef:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03c3:
.L_if_end_03c4:
.L_if_end_03c5:
	jmp .L_if_end_03c6
.L_if_else_03c6:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06f0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f0
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06f0
.L_tc_recycle_frame_done_06f0:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03c6:
.L_if_end_03c7:
.L_if_end_03c8:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0491:	; new closure is in rax
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
.L_lambda_simple_env_loop_0492:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0492
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0492
.L_lambda_simple_env_end_0492:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0492:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0492
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0492
.L_lambda_simple_params_end_0492:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0492
	jmp .L_lambda_simple_end_0492
.L_lambda_simple_code_0492:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0492
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0492:
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
.L_lambda_opt_env_loop_00b3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_00b3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b3
.L_lambda_opt_env_end_00b3:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b3:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00b3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b3
.L_lambda_opt_params_end_00b3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b3
	jmp .L_lambda_opt_end_00b3
.L_lambda_opt_code_00b3:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_00b3
	ja .L_lambda_opt_arity_check_more_00b3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00b3: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0218:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0218
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0218
.L_lambda_opt_stack_shrink_loop_exit_0218:
	lea r10, [rsp + 8* 1 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_0219:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0219
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0219
.L_lambda_opt_stack_shrink_loop_exit_0219:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00b3
.L_lambda_opt_arity_check_exact_00b3: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0217:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0217
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0217
.L_lambda_opt_stack_shrink_loop_exit_0217:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00b3:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03c9
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06f1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f1
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06f1
.L_tc_recycle_frame_done_06f1:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03c9
.L_if_else_03c9:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, L_constants + 2135
	push rax
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3	; arg count
	mov rax, qword [free_var_85]	; free var fold-left
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
.L_lambda_simple_env_loop_0493:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0493
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0493
.L_lambda_simple_env_end_0493:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0493:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0493
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0493
.L_lambda_simple_params_end_0493:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0493
	jmp .L_lambda_simple_end_0493
.L_lambda_simple_code_0493:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0493
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0493:
	enter 0, 0
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06f3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f3
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06f3
.L_tc_recycle_frame_done_06f3:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0493:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_06f2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f2
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06f2
.L_tc_recycle_frame_done_06f2:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03c9:
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_00b3:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0492:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_06e3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e3
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06e3
.L_tc_recycle_frame_done_06e3:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0490:	; new closure is in rax
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
.L_lambda_simple_env_loop_0494:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0494
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0494
.L_lambda_simple_env_end_0494:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0494:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0494
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0494
.L_lambda_simple_params_end_0494:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0494
	jmp .L_lambda_simple_end_0494
.L_lambda_simple_code_0494:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0494
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0494:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2187
	push rax
	mov rax, L_constants + 2279
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_06f4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f4
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06f4
.L_tc_recycle_frame_done_06f4:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0494:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_0495:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0495
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0495
.L_lambda_simple_env_end_0495:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0495:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0495
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0495
.L_lambda_simple_params_end_0495:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0495
	jmp .L_lambda_simple_end_0495
.L_lambda_simple_code_0495:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0495
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0495:
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_0496:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0496
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0496
.L_lambda_simple_env_end_0496:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0496:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0496
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0496
.L_lambda_simple_params_end_0496:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0496
	jmp .L_lambda_simple_end_0496
.L_lambda_simple_code_0496:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0496
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0496:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d5
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03cc
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06f6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f6
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06f6
.L_tc_recycle_frame_done_06f6:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03cc
.L_if_else_03cc:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03cb
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06f7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f7
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06f7
.L_tc_recycle_frame_done_06f7:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03cb
.L_if_else_03cb:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ca
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_90]	; free var integer->real
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
.L_tc_recycle_frame_loop_06f8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f8
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06f8
.L_tc_recycle_frame_done_06f8:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03ca
.L_if_else_03ca:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06f9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f9
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06f9
.L_tc_recycle_frame_done_06f9:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03ca:
.L_if_end_03cb:
.L_if_end_03cc:
	jmp .L_if_end_03d5
.L_if_else_03d5:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d4
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03cf
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06fa:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06fa
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06fa
.L_tc_recycle_frame_done_06fa:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03cf
.L_if_else_03cf:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ce
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06fb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06fb
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06fb
.L_tc_recycle_frame_done_06fb:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03ce
.L_if_else_03ce:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03cd
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_87]	; free var fraction->real
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
.L_tc_recycle_frame_loop_06fc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06fc
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06fc
.L_tc_recycle_frame_done_06fc:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03cd
.L_if_else_03cd:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_06fd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06fd
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06fd
.L_tc_recycle_frame_done_06fd:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03cd:
.L_if_end_03ce:
.L_if_end_03cf:
	jmp .L_if_end_03d4
.L_if_else_03d4:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d3
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d2
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06fe:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06fe
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06fe
.L_tc_recycle_frame_done_06fe:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03d2
.L_if_else_03d2:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d1
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_06ff:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ff
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06ff
.L_tc_recycle_frame_done_06ff:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03d1
.L_if_else_03d1:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d0
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0700:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0700
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0700
.L_tc_recycle_frame_done_0700:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03d0
.L_if_else_03d0:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0701:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0701
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0701
.L_tc_recycle_frame_done_0701:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03d0:
.L_if_end_03d1:
.L_if_end_03d2:
	jmp .L_if_end_03d3
.L_if_else_03d3:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0702:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0702
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0702
.L_tc_recycle_frame_done_0702:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03d3:
.L_if_end_03d4:
.L_if_end_03d5:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0496:	; new closure is in rax
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
.L_lambda_simple_env_loop_0497:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0497
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0497
.L_lambda_simple_env_end_0497:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0497:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0497
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0497
.L_lambda_simple_params_end_0497:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0497
	jmp .L_lambda_simple_end_0497
.L_lambda_simple_code_0497:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0497
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0497:
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
.L_lambda_opt_env_loop_00b4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_00b4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b4
.L_lambda_opt_env_end_00b4:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b4:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00b4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b4
.L_lambda_opt_params_end_00b4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b4
	jmp .L_lambda_opt_end_00b4
.L_lambda_opt_code_00b4:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_00b4
	ja .L_lambda_opt_arity_check_more_00b4
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00b4: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_021b:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_021b
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_021b
.L_lambda_opt_stack_shrink_loop_exit_021b:
	lea r10, [rsp + 8* 0 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_021c:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_021c
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_021c
.L_lambda_opt_stack_shrink_loop_exit_021c:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00b4
.L_lambda_opt_arity_check_exact_00b4: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_021a:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_021a
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_021a
.L_lambda_opt_stack_shrink_loop_exit_021a:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00b4:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2270
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin*
	push rax
	push 3	; arg count
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
.L_tc_recycle_frame_loop_0703:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0703
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0703
.L_tc_recycle_frame_done_0703:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_00b4:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0497:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_06f5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f5
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_06f5
.L_tc_recycle_frame_done_06f5:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0495:	; new closure is in rax
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
.L_lambda_simple_env_loop_0498:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0498
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0498
.L_lambda_simple_env_end_0498:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0498:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0498
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0498
.L_lambda_simple_params_end_0498:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0498
	jmp .L_lambda_simple_end_0498
.L_lambda_simple_code_0498:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0498
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0498:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2187
	push rax
	mov rax, L_constants + 2298
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_0704:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0704
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0704
.L_tc_recycle_frame_done_0704:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0498:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_0499:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0499
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0499
.L_lambda_simple_env_end_0499:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0499:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0499
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0499
.L_lambda_simple_params_end_0499:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0499
	jmp .L_lambda_simple_end_0499
.L_lambda_simple_code_0499:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0499
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0499:
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_049a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_049a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_049a
.L_lambda_simple_env_end_049a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_049a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_049a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_049a
.L_lambda_simple_params_end_049a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_049a
	jmp .L_lambda_simple_end_049a
.L_lambda_simple_code_049a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_049a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_049a:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e1
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d8
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0706:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0706
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0706
.L_tc_recycle_frame_done_0706:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03d8
.L_if_else_03d8:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d7
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0707:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0707
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0707
.L_tc_recycle_frame_done_0707:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03d7
.L_if_else_03d7:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d6
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_90]	; free var integer->real
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
.L_tc_recycle_frame_loop_0708:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0708
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0708
.L_tc_recycle_frame_done_0708:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03d6
.L_if_else_03d6:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0709:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0709
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0709
.L_tc_recycle_frame_done_0709:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03d6:
.L_if_end_03d7:
.L_if_end_03d8:
	jmp .L_if_end_03e1
.L_if_else_03e1:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03db
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_070a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_070a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_070a
.L_tc_recycle_frame_done_070a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03db
.L_if_else_03db:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03da
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_070b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_070b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_070b
.L_tc_recycle_frame_done_070b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03da
.L_if_else_03da:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d9
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_87]	; free var fraction->real
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
.L_tc_recycle_frame_loop_070c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_070c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_070c
.L_tc_recycle_frame_done_070c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03d9
.L_if_else_03d9:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_070d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_070d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_070d
.L_tc_recycle_frame_done_070d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03d9:
.L_if_end_03da:
.L_if_end_03db:
	jmp .L_if_end_03e0
.L_if_else_03e0:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03df
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03de
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_070e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_070e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_070e
.L_tc_recycle_frame_done_070e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03de
.L_if_else_03de:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03dd
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_070f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_070f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_070f
.L_tc_recycle_frame_done_070f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03dd
.L_if_else_03dd:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03dc
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0710:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0710
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0710
.L_tc_recycle_frame_done_0710:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03dc
.L_if_else_03dc:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0711:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0711
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0711
.L_tc_recycle_frame_done_0711:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03dc:
.L_if_end_03dd:
.L_if_end_03de:
	jmp .L_if_end_03df
.L_if_else_03df:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0712:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0712
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0712
.L_tc_recycle_frame_done_0712:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03df:
.L_if_end_03e0:
.L_if_end_03e1:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_049a:	; new closure is in rax
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
.L_lambda_simple_env_loop_049b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_049b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_049b
.L_lambda_simple_env_end_049b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_049b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_049b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_049b
.L_lambda_simple_params_end_049b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_049b
	jmp .L_lambda_simple_end_049b
.L_lambda_simple_code_049b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_049b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_049b:
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
.L_lambda_opt_env_loop_00b5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_00b5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b5
.L_lambda_opt_env_end_00b5:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b5:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00b5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b5
.L_lambda_opt_params_end_00b5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b5
	jmp .L_lambda_opt_end_00b5
.L_lambda_opt_code_00b5:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_00b5
	ja .L_lambda_opt_arity_check_more_00b5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00b5: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_021e:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_021e
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_021e
.L_lambda_opt_stack_shrink_loop_exit_021e:
	lea r10, [rsp + 8* 1 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_021f:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_021f
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_021f
.L_lambda_opt_stack_shrink_loop_exit_021f:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00b5
.L_lambda_opt_arity_check_exact_00b5: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_021d:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_021d
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_021d
.L_lambda_opt_stack_shrink_loop_exit_021d:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00b5:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e2
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0713:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0713
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0713
.L_tc_recycle_frame_done_0713:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03e2
.L_if_else_03e2:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, L_constants + 2270
	push rax
	mov rax, qword [free_var_0]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3	; arg count
	mov rax, qword [free_var_85]	; free var fold-left
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
.L_lambda_simple_env_loop_049c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_049c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_049c
.L_lambda_simple_env_end_049c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_049c:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_049c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_049c
.L_lambda_simple_params_end_049c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_049c
	jmp .L_lambda_simple_end_049c
.L_lambda_simple_code_049c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_049c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_049c:
	enter 0, 0
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0715:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0715
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0715
.L_tc_recycle_frame_done_0715:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_049c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0714:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0714
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0714
.L_tc_recycle_frame_done_0714:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03e2:
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_00b5:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_049b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0705:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0705
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0705
.L_tc_recycle_frame_done_0705:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0499:	; new closure is in rax
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
.L_lambda_simple_env_loop_049d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_049d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_049d
.L_lambda_simple_env_end_049d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_049d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_049d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_049d
.L_lambda_simple_params_end_049d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_049d
	jmp .L_lambda_simple_end_049d
.L_lambda_simple_code_049d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_049d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_049d:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_151]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e3
	mov rax, L_constants + 2270
	jmp .L_if_end_03e3
.L_if_else_03e3:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0716:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0716
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0716
.L_tc_recycle_frame_done_0716:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03e3:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_049d:	; new closure is in rax
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
.L_lambda_simple_env_loop_049e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_049e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_049e
.L_lambda_simple_env_end_049e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_049e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_049e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_049e
.L_lambda_simple_params_end_049e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_049e
	jmp .L_lambda_simple_end_049e
.L_lambda_simple_code_049e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_049e
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_049e:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2408
	push rax
	mov rax, L_constants + 2399
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_0717:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0717
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0717
.L_tc_recycle_frame_done_0717:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_049e:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_049f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_049f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_049f
.L_lambda_simple_env_end_049f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_049f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_049f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_049f
.L_lambda_simple_params_end_049f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_049f
	jmp .L_lambda_simple_end_049f
.L_lambda_simple_code_049f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_049f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_049f:
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_04a0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04a0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04a0
.L_lambda_simple_env_end_04a0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04a0:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04a0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04a0
.L_lambda_simple_params_end_04a0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04a0
	jmp .L_lambda_simple_end_04a0
.L_lambda_simple_code_04a0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_04a0
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04a0:
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
.L_lambda_simple_env_loop_04a1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_04a1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04a1
.L_lambda_simple_env_end_04a1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04a1:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_04a1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04a1
.L_lambda_simple_params_end_04a1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04a1
	jmp .L_lambda_simple_end_04a1
.L_lambda_simple_code_04a1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04a1
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04a1:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ef
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e6
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0719:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0719
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0719
.L_tc_recycle_frame_done_0719:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03e6
.L_if_else_03e6:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e5
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_071a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_071a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_071a
.L_tc_recycle_frame_done_071a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03e5
.L_if_else_03e5:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e4
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_90]	; free var integer->real
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
.L_tc_recycle_frame_loop_071b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_071b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_071b
.L_tc_recycle_frame_done_071b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03e4
.L_if_else_03e4:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_071c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_071c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_071c
.L_tc_recycle_frame_done_071c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03e4:
.L_if_end_03e5:
.L_if_end_03e6:
	jmp .L_if_end_03ef
.L_if_else_03ef:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ee
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e9
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_071d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_071d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_071d
.L_tc_recycle_frame_done_071d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03e9
.L_if_else_03e9:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e8
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_071e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_071e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_071e
.L_tc_recycle_frame_done_071e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03e8
.L_if_else_03e8:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e7
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_87]	; free var fraction->real
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
.L_tc_recycle_frame_loop_071f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_071f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_071f
.L_tc_recycle_frame_done_071f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03e7
.L_if_else_03e7:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0720:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0720
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0720
.L_tc_recycle_frame_done_0720:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03e7:
.L_if_end_03e8:
.L_if_end_03e9:
	jmp .L_if_end_03ee
.L_if_else_03ee:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ed
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ec
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0721:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0721
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0721
.L_tc_recycle_frame_done_0721:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03ec
.L_if_else_03ec:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_88]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03eb
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0722:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0722
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0722
.L_tc_recycle_frame_done_0722:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03eb
.L_if_else_03eb:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ea
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0723:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0723
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0723
.L_tc_recycle_frame_done_0723:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03ea
.L_if_else_03ea:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0724:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0724
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0724
.L_tc_recycle_frame_done_0724:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03ea:
.L_if_end_03eb:
.L_if_end_03ec:
	jmp .L_if_end_03ed
.L_if_else_03ed:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0725:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0725
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0725
.L_tc_recycle_frame_done_0725:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03ed:
.L_if_end_03ee:
.L_if_end_03ef:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04a1:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_04a0:	; new closure is in rax
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
.L_lambda_simple_env_loop_04a2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04a2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04a2
.L_lambda_simple_env_end_04a2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04a2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04a2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04a2
.L_lambda_simple_params_end_04a2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04a2
	jmp .L_lambda_simple_end_04a2
.L_lambda_simple_code_04a2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04a2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04a2:
	enter 0, 0
	; preparing a tail-call
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
	push 3	; arg count
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
.L_lambda_simple_env_loop_04a3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_04a3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04a3
.L_lambda_simple_env_end_04a3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04a3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04a3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04a3
.L_lambda_simple_params_end_04a3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04a3
	jmp .L_lambda_simple_end_04a3
.L_lambda_simple_code_04a3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04a3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04a3:
	enter 0, 0
	; preparing a tail-call
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
	push 3	; arg count
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
.L_lambda_simple_env_loop_04a4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_04a4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04a4
.L_lambda_simple_env_end_04a4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04a4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04a4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04a4
.L_lambda_simple_params_end_04a4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04a4
	jmp .L_lambda_simple_end_04a4
.L_lambda_simple_code_04a4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04a4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04a4:
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_04a5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_04a5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04a5
.L_lambda_simple_env_end_04a5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04a5:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04a5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04a5
.L_lambda_simple_params_end_04a5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04a5
	jmp .L_lambda_simple_end_04a5
.L_lambda_simple_code_04a5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04a5
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04a5:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0729:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0729
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0729
.L_tc_recycle_frame_done_0729:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04a5:	; new closure is in rax
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
.L_lambda_simple_env_loop_04a6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_04a6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04a6
.L_lambda_simple_env_end_04a6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04a6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04a6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04a6
.L_lambda_simple_params_end_04a6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04a6
	jmp .L_lambda_simple_end_04a6
.L_lambda_simple_code_04a6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04a6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04a6:
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_04a7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_04a7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04a7
.L_lambda_simple_env_end_04a7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04a7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04a7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04a7
.L_lambda_simple_params_end_04a7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04a7
	jmp .L_lambda_simple_end_04a7
.L_lambda_simple_code_04a7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04a7
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04a7:
	enter 0, 0
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_072b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_072b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_072b
.L_tc_recycle_frame_done_072b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04a7:	; new closure is in rax
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
.L_lambda_simple_env_loop_04a8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_04a8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04a8
.L_lambda_simple_env_end_04a8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04a8:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04a8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04a8
.L_lambda_simple_params_end_04a8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04a8
	jmp .L_lambda_simple_end_04a8
.L_lambda_simple_code_04a8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04a8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04a8:
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_04a9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_04a9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04a9
.L_lambda_simple_env_end_04a9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04a9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04a9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04a9
.L_lambda_simple_params_end_04a9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04a9
	jmp .L_lambda_simple_end_04a9
.L_lambda_simple_code_04a9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04a9
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04a9:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin>?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_072d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_072d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_072d
.L_tc_recycle_frame_done_072d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04a9:	; new closure is in rax
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
.L_lambda_simple_env_loop_04aa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_04aa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04aa
.L_lambda_simple_env_end_04aa:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04aa:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04aa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04aa
.L_lambda_simple_params_end_04aa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04aa
	jmp .L_lambda_simple_end_04aa
.L_lambda_simple_code_04aa:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04aa
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04aa:
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_04ab:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_04ab
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04ab
.L_lambda_simple_env_end_04ab:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04ab:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04ab
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04ab
.L_lambda_simple_params_end_04ab:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04ab
	jmp .L_lambda_simple_end_04ab
.L_lambda_simple_code_04ab:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04ab
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ab:
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_04ac:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_04ac
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04ac
.L_lambda_simple_env_end_04ac:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04ac:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04ac
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04ac
.L_lambda_simple_params_end_04ac:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04ac
	jmp .L_lambda_simple_end_04ac
.L_lambda_simple_code_04ac:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04ac
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ac:
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
.L_lambda_simple_env_loop_04ad:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 9
	je .L_lambda_simple_env_end_04ad
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04ad
.L_lambda_simple_env_end_04ad:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04ad:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04ad
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04ad
.L_lambda_simple_params_end_04ad:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04ad
	jmp .L_lambda_simple_end_04ad
.L_lambda_simple_code_04ad:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04ad
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ad:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0052
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
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
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin-ordering
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
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
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0730:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0730
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0730
.L_tc_recycle_frame_done_0730:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03f0
.L_if_else_03f0:
	mov rax, L_constants + 2
.L_if_end_03f0:
.L_or_end_0052:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04ad:	; new closure is in rax
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
	mov rdi, 8 * 10	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00b6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 9
	je .L_lambda_opt_env_end_00b6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b6
.L_lambda_opt_env_end_00b6:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b6:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00b6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b6
.L_lambda_opt_params_end_00b6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b6
	jmp .L_lambda_opt_end_00b6
.L_lambda_opt_code_00b6:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_00b6
	ja .L_lambda_opt_arity_check_more_00b6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00b6: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0221:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0221
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0221
.L_lambda_opt_stack_shrink_loop_exit_0221:
	lea r10, [rsp + 8* 1 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_0222:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0222
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0222
.L_lambda_opt_stack_shrink_loop_exit_0222:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00b6
.L_lambda_opt_arity_check_exact_00b6: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0220:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0220
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0220
.L_lambda_opt_stack_shrink_loop_exit_0220:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00b6:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0731:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0731
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0731
.L_tc_recycle_frame_done_0731:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_00b6:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04ac:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_072f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_072f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_072f
.L_tc_recycle_frame_done_072f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04ab:	; new closure is in rax
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
.L_lambda_simple_env_loop_04ae:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_04ae
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04ae
.L_lambda_simple_env_end_04ae:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04ae:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04ae
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04ae
.L_lambda_simple_params_end_04ae:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04ae
	jmp .L_lambda_simple_end_04ae
.L_lambda_simple_code_04ae:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04ae
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ae:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 4]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	push rax
	push 1	; arg count
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
	push 1	; arg count
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
	push 1	; arg count
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
	push 1	; arg count
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
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_6], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04ae:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_072e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_072e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_072e
.L_tc_recycle_frame_done_072e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04aa:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_072c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_072c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_072c
.L_tc_recycle_frame_done_072c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04a8:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_072a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_072a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_072a
.L_tc_recycle_frame_done_072a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04a6:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0728:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0728
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0728
.L_tc_recycle_frame_done_0728:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04a4:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0727:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0727
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0727
.L_tc_recycle_frame_done_0727:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04a3:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0726:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0726
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0726
.L_tc_recycle_frame_done_0726:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04a2:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0718:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0718
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0718
.L_tc_recycle_frame_done_0718:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_049f:	; new closure is in rax
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
.L_lambda_simple_env_loop_04af:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04af
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04af
.L_lambda_simple_env_end_04af:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04af:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04af
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04af
.L_lambda_simple_params_end_04af:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04af
	jmp .L_lambda_simple_end_04af
.L_lambda_simple_code_04af:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04af
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04af:
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
.L_lambda_opt_env_loop_00b7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00b7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b7
.L_lambda_opt_env_end_00b7:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b7:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00b7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b7
.L_lambda_opt_params_end_00b7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b7
	jmp .L_lambda_opt_end_00b7
.L_lambda_opt_code_00b7:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_00b7
	ja .L_lambda_opt_arity_check_more_00b7
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00b7: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0224:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0224
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0224
.L_lambda_opt_stack_shrink_loop_exit_0224:
	lea r10, [rsp + 8* 0 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_0225:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0225
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0225
.L_lambda_opt_stack_shrink_loop_exit_0225:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00b7
.L_lambda_opt_arity_check_exact_00b7: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0223:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0223
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0223
.L_lambda_opt_stack_shrink_loop_exit_0223:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00b7:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_0732:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0732
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0732
.L_tc_recycle_frame_done_0732:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_00b7:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04af:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_04b0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04b0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04b0
.L_lambda_simple_env_end_04b0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04b0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04b0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04b0
.L_lambda_simple_params_end_04b0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04b0
	jmp .L_lambda_simple_end_04b0
.L_lambda_simple_code_04b0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04b0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04b0:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
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
	push 1	; arg count
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
	push 1	; arg count
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
	push 1	; arg count
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
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_76], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04b0:	; new closure is in rax
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
	push 1	; arg count
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
	push 1	; arg count
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
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
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_04b1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04b1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04b1
.L_lambda_simple_env_end_04b1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04b1:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04b1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04b1
.L_lambda_simple_params_end_04b1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04b1
	jmp .L_lambda_simple_end_04b1
.L_lambda_simple_code_04b1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04b1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04b1:
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
.L_lambda_simple_env_loop_04b2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04b2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04b2
.L_lambda_simple_env_end_04b2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04b2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04b2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04b2
.L_lambda_simple_params_end_04b2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04b2
	jmp .L_lambda_simple_end_04b2
.L_lambda_simple_code_04b2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04b2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04b2:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, L_constants + 2571
	push rax
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, L_constants + 2569
	push rax
	push 3	; arg count
	mov rax, qword [free_var_73]	; free var char<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f1
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var delta
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	push 1	; arg count
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0733:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0733
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0733
.L_tc_recycle_frame_done_0733:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03f1
.L_if_else_03f1:
	mov rax, PARAM(0)	; param ch
.L_if_end_03f1:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04b2:	; new closure is in rax
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
.L_lambda_simple_env_loop_04b3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04b3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04b3
.L_lambda_simple_env_end_04b3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04b3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04b3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04b3
.L_lambda_simple_params_end_04b3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04b3
	jmp .L_lambda_simple_end_04b3
.L_lambda_simple_code_04b3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04b3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04b3:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, L_constants + 2575
	push rax
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, L_constants + 2573
	push rax
	push 3	; arg count
	mov rax, qword [free_var_73]	; free var char<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f2
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var delta
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	push 1	; arg count
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0734:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0734
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0734
.L_tc_recycle_frame_done_0734:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03f2
.L_if_else_03f2:
	mov rax, PARAM(0)	; param ch
.L_if_end_03f2:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04b3:	; new closure is in rax
	mov qword [free_var_72], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04b1:	; new closure is in rax
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
.L_lambda_simple_env_loop_04b4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04b4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04b4
.L_lambda_simple_env_end_04b4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04b4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04b4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04b4
.L_lambda_simple_params_end_04b4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04b4
	jmp .L_lambda_simple_end_04b4
.L_lambda_simple_code_04b4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04b4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04b4:
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
.L_lambda_opt_env_loop_00b8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00b8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b8
.L_lambda_opt_env_end_00b8:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b8:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00b8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b8
.L_lambda_opt_params_end_00b8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b8
	jmp .L_lambda_opt_end_00b8
.L_lambda_opt_code_00b8:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_00b8
	ja .L_lambda_opt_arity_check_more_00b8
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00b8: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0227:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0227
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0227
.L_lambda_opt_stack_shrink_loop_exit_0227:
	lea r10, [rsp + 8* 0 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_0228:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0228
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0228
.L_lambda_opt_stack_shrink_loop_exit_0228:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00b8
.L_lambda_opt_arity_check_exact_00b8: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0226:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0226
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0226
.L_lambda_opt_stack_shrink_loop_exit_0226:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00b8:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_04b5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_04b5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04b5
.L_lambda_simple_env_end_04b5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04b5:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04b5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04b5
.L_lambda_simple_params_end_04b5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04b5
	jmp .L_lambda_simple_end_04b5
.L_lambda_simple_code_04b5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04b5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04b5:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0736:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0736
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0736
.L_tc_recycle_frame_done_0736:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04b5:	; new closure is in rax
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_0735:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0735
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0735
.L_tc_recycle_frame_done_0735:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_00b8:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04b4:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_04b6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04b6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04b6
.L_lambda_simple_env_end_04b6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04b6:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04b6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04b6
.L_lambda_simple_params_end_04b6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04b6
	jmp .L_lambda_simple_end_04b6
.L_lambda_simple_code_04b6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04b6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04b6:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
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
	push 1	; arg count
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
	push 1	; arg count
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
	push 1	; arg count
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
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_69], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04b6:	; new closure is in rax
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
.L_lambda_simple_env_loop_04b7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04b7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04b7
.L_lambda_simple_env_end_04b7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04b7:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04b7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04b7
.L_lambda_simple_params_end_04b7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04b7
	jmp .L_lambda_simple_end_04b7
.L_lambda_simple_code_04b7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04b7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04b7:
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
.L_lambda_simple_env_loop_04b8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04b8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04b8
.L_lambda_simple_env_end_04b8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04b8:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04b8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04b8
.L_lambda_simple_params_end_04b8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04b8
	jmp .L_lambda_simple_end_04b8
.L_lambda_simple_code_04b8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04b8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04b8:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
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
	push 2	; arg count
	mov rax, qword [free_var_103]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0737:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0737
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0737
.L_tc_recycle_frame_done_0737:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04b8:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04b7:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_04b9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04b9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04b9
.L_lambda_simple_env_end_04b9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04b9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04b9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04b9
.L_lambda_simple_params_end_04b9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04b9
	jmp .L_lambda_simple_end_04b9
.L_lambda_simple_code_04b9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04b9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04b9:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_71]	; free var char-downcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
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
	push 1	; arg count
	mov rax, PARAM(0)	; param make-string-case-converter
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_132], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04b9:	; new closure is in rax
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
.L_lambda_simple_env_loop_04ba:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04ba
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04ba
.L_lambda_simple_env_end_04ba:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04ba:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04ba
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04ba
.L_lambda_simple_params_end_04ba:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04ba
	jmp .L_lambda_simple_end_04ba
.L_lambda_simple_code_04ba:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04ba
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ba:
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_04bb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04bb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04bb
.L_lambda_simple_env_end_04bb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04bb:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_04bb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04bb
.L_lambda_simple_params_end_04bb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04bb
	jmp .L_lambda_simple_end_04bb
.L_lambda_simple_code_04bb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04bb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04bb:
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
.L_lambda_simple_env_loop_04bc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_04bc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04bc
.L_lambda_simple_env_end_04bc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04bc:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04bc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04bc
.L_lambda_simple_params_end_04bc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04bc
	jmp .L_lambda_simple_end_04bc
.L_lambda_simple_code_04bc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_04bc
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04bc:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f3
	; preparing a non-tail-call
	mov rax, PARAM(4)	; param len2
	push rax
	mov rax, PARAM(2)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03f3
.L_if_else_03f3:
	mov rax, L_constants + 2
.L_if_end_03f3:
	cmp rax, sob_boolean_false
	jne .L_or_end_0053
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f5
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
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
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var char<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0054
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
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
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var char=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f4
	; preparing a tail-call
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
	push 2	; arg count
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
.L_tc_recycle_frame_loop_0739:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0739
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0739
.L_tc_recycle_frame_done_0739:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03f4
.L_if_else_03f4:
	mov rax, L_constants + 2
.L_if_end_03f4:
.L_or_end_0054:
	jmp .L_if_end_03f5
.L_if_else_03f5:
	mov rax, L_constants + 2
.L_if_end_03f5:
.L_or_end_0053:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_04bc:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
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
.L_lambda_simple_env_loop_04bd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_04bd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04bd
.L_lambda_simple_env_end_04bd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04bd:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04bd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04bd
.L_lambda_simple_params_end_04bd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04bd
	jmp .L_lambda_simple_end_04bd
.L_lambda_simple_code_04bd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04bd
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04bd:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1	; arg count
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
	push 1	; arg count
	mov rax, qword [free_var_127]	; free var string-length
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
.L_lambda_simple_env_loop_04be:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_04be
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04be
.L_lambda_simple_env_end_04be:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04be:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_04be
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04be
.L_lambda_simple_params_end_04be:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04be
	jmp .L_lambda_simple_end_04be
.L_lambda_simple_code_04be:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04be
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04be:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_5]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f6
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_073c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_073c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_073c
.L_tc_recycle_frame_done_073c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03f6
.L_if_else_03f6:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_073d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_073d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_073d
.L_tc_recycle_frame_done_073d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03f6:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04be:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_073b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_073b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_073b
.L_tc_recycle_frame_done_073b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04bd:	; new closure is in rax
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
.L_lambda_simple_env_loop_04bf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_04bf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04bf
.L_lambda_simple_env_end_04bf:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04bf:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04bf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04bf
.L_lambda_simple_params_end_04bf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04bf
	jmp .L_lambda_simple_end_04bf
.L_lambda_simple_code_04bf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04bf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04bf:
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_04c0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_04c0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04c0
.L_lambda_simple_env_end_04c0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04c0:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04c0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04c0
.L_lambda_simple_params_end_04c0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04c0
	jmp .L_lambda_simple_end_04c0
.L_lambda_simple_code_04c0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04c0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c0:
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
.L_lambda_simple_env_loop_04c1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_04c1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04c1
.L_lambda_simple_env_end_04c1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04c1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04c1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04c1
.L_lambda_simple_params_end_04c1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04c1
	jmp .L_lambda_simple_end_04c1
.L_lambda_simple_code_04c1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04c1
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c1:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0055
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
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
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var binary-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f7
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
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
	push 1	; arg count
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
.L_tc_recycle_frame_loop_073f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_073f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_073f
.L_tc_recycle_frame_done_073f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03f7
.L_if_else_03f7:
	mov rax, L_constants + 2
.L_if_end_03f7:
.L_or_end_0055:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04c1:	; new closure is in rax
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
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00b9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_opt_env_end_00b9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b9
.L_lambda_opt_env_end_00b9:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b9:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00b9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b9
.L_lambda_opt_params_end_00b9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b9
	jmp .L_lambda_opt_end_00b9
.L_lambda_opt_code_00b9:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_00b9
	ja .L_lambda_opt_arity_check_more_00b9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00b9: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_022a:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_022a
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_022a
.L_lambda_opt_stack_shrink_loop_exit_022a:
	lea r10, [rsp + 8* 1 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_022b:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_022b
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_022b
.L_lambda_opt_stack_shrink_loop_exit_022b:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00b9
.L_lambda_opt_arity_check_exact_00b9: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0229:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0229
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0229
.L_lambda_opt_stack_shrink_loop_exit_0229:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00b9:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0740:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0740
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0740
.L_tc_recycle_frame_done_0740:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_00b9:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04c0:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_073e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_073e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_073e
.L_tc_recycle_frame_done_073e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04bf:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_073a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_073a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_073a
.L_tc_recycle_frame_done_073a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04bb:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0738:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0738
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0738
.L_tc_recycle_frame_done_0738:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04ba:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_04c2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04c2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04c2
.L_lambda_simple_env_end_04c2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04c2:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04c2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04c2
.L_lambda_simple_params_end_04c2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04c2
	jmp .L_lambda_simple_end_04c2
.L_lambda_simple_code_04c2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04c2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c2:
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
	push 2	; arg count
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
	push 2	; arg count
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
	push 2	; arg count
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
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_125], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04c2:	; new closure is in rax
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
.L_lambda_simple_env_loop_04c3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04c3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04c3
.L_lambda_simple_env_end_04c3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04c3:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04c3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04c3
.L_lambda_simple_params_end_04c3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04c3
	jmp .L_lambda_simple_end_04c3
.L_lambda_simple_code_04c3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04c3
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c3:
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_04c4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04c4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04c4
.L_lambda_simple_env_end_04c4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04c4:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_04c4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04c4
.L_lambda_simple_params_end_04c4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04c4
	jmp .L_lambda_simple_end_04c4
.L_lambda_simple_code_04c4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04c4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c4:
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
.L_lambda_simple_env_loop_04c5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_04c5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04c5
.L_lambda_simple_env_end_04c5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04c5:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04c5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04c5
.L_lambda_simple_params_end_04c5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04c5
	jmp .L_lambda_simple_end_04c5
.L_lambda_simple_code_04c5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_04c5
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c5:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0056
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
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
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var char<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0056
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f9
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
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
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var char=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f8
	; preparing a tail-call
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
	push 2	; arg count
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
.L_tc_recycle_frame_loop_0742:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0742
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0742
.L_tc_recycle_frame_done_0742:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03f8
.L_if_else_03f8:
	mov rax, L_constants + 2
.L_if_end_03f8:
	jmp .L_if_end_03f9
.L_if_else_03f9:
	mov rax, L_constants + 2
.L_if_end_03f9:
.L_or_end_0056:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_04c5:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
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
.L_lambda_simple_env_loop_04c6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_04c6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04c6
.L_lambda_simple_env_end_04c6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04c6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04c6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04c6
.L_lambda_simple_params_end_04c6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04c6
	jmp .L_lambda_simple_end_04c6
.L_lambda_simple_code_04c6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04c6
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c6:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1	; arg count
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
	push 1	; arg count
	mov rax, qword [free_var_127]	; free var string-length
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
.L_lambda_simple_env_loop_04c7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_04c7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04c7
.L_lambda_simple_env_end_04c7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04c7:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_04c7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04c7
.L_lambda_simple_params_end_04c7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04c7
	jmp .L_lambda_simple_end_04c7
.L_lambda_simple_code_04c7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04c7
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c7:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_5]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03fa
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0745:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0745
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0745
.L_tc_recycle_frame_done_0745:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03fa
.L_if_else_03fa:
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0746:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0746
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0746
.L_tc_recycle_frame_done_0746:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03fa:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04c7:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0744:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0744
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0744
.L_tc_recycle_frame_done_0744:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04c6:	; new closure is in rax
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
.L_lambda_simple_env_loop_04c8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_04c8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04c8
.L_lambda_simple_env_end_04c8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04c8:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04c8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04c8
.L_lambda_simple_params_end_04c8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04c8
	jmp .L_lambda_simple_end_04c8
.L_lambda_simple_code_04c8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04c8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c8:
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_04c9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_04c9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04c9
.L_lambda_simple_env_end_04c9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04c9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04c9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04c9
.L_lambda_simple_params_end_04c9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04c9
	jmp .L_lambda_simple_end_04c9
.L_lambda_simple_code_04c9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04c9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c9:
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
.L_lambda_simple_env_loop_04ca:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_04ca
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04ca
.L_lambda_simple_env_end_04ca:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04ca:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04ca
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04ca
.L_lambda_simple_params_end_04ca:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04ca
	jmp .L_lambda_simple_end_04ca
.L_lambda_simple_code_04ca:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04ca
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ca:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0057
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
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
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var binary-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03fb
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
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
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0748:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0748
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0748
.L_tc_recycle_frame_done_0748:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03fb
.L_if_else_03fb:
	mov rax, L_constants + 2
.L_if_end_03fb:
.L_or_end_0057:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04ca:	; new closure is in rax
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
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00ba:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_opt_env_end_00ba
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00ba
.L_lambda_opt_env_end_00ba:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00ba:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00ba
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00ba
.L_lambda_opt_params_end_00ba:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00ba
	jmp .L_lambda_opt_end_00ba
.L_lambda_opt_code_00ba:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_00ba
	ja .L_lambda_opt_arity_check_more_00ba
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00ba: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_022d:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_022d
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_022d
.L_lambda_opt_stack_shrink_loop_exit_022d:
	lea r10, [rsp + 8* 1 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_022e:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_022e
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_022e
.L_lambda_opt_stack_shrink_loop_exit_022e:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00ba
.L_lambda_opt_arity_check_exact_00ba: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_022c:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_022c
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_022c
.L_lambda_opt_stack_shrink_loop_exit_022c:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00ba:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0749:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0749
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0749
.L_tc_recycle_frame_done_0749:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_00ba:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04c9:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0747:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0747
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0747
.L_tc_recycle_frame_done_0747:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04c8:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0743:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0743
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0743
.L_tc_recycle_frame_done_0743:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04c4:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0741:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0741
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0741
.L_tc_recycle_frame_done_0741:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04c3:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_04cb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04cb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04cb
.L_lambda_simple_env_end_04cb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04cb:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04cb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04cb
.L_lambda_simple_params_end_04cb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04cb
	jmp .L_lambda_simple_end_04cb
.L_lambda_simple_code_04cb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04cb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04cb:
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
	push 2	; arg count
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
	push 2	; arg count
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
	push 2	; arg count
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
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_124], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04cb:	; new closure is in rax
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
.L_lambda_simple_env_loop_04cc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04cc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04cc
.L_lambda_simple_env_end_04cc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04cc:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04cc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04cc
.L_lambda_simple_params_end_04cc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04cc
	jmp .L_lambda_simple_end_04cc
.L_lambda_simple_code_04cc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04cc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04cc:
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_04cd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04cd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04cd
.L_lambda_simple_env_end_04cd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04cd:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04cd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04cd
.L_lambda_simple_params_end_04cd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04cd
	jmp .L_lambda_simple_end_04cd
.L_lambda_simple_code_04cd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04cd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04cd:
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
.L_lambda_simple_env_loop_04ce:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_04ce
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04ce
.L_lambda_simple_env_end_04ce:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04ce:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04ce
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04ce
.L_lambda_simple_params_end_04ce:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04ce
	jmp .L_lambda_simple_end_04ce
.L_lambda_simple_code_04ce:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 4
	je .L_lambda_simple_arity_check_ok_04ce
	push qword [rsp + 8 * 2]
	push 4
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ce:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param len
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0058
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param len
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03fd
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(2)	; param str2
	push rax
	push 2	; arg count
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
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var char=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03fc
	; preparing a tail-call
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
	push 2	; arg count
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
.L_tc_recycle_frame_loop_074b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_074b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_074b
.L_tc_recycle_frame_done_074b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03fc
.L_if_else_03fc:
	mov rax, L_constants + 2
.L_if_end_03fc:
	jmp .L_if_end_03fd
.L_if_else_03fd:
	mov rax, L_constants + 2
.L_if_end_03fd:
.L_or_end_0058:
	leave
	ret AND_KILL_FRAME(4)
.L_lambda_simple_end_04ce:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
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
.L_lambda_simple_env_loop_04cf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_04cf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04cf
.L_lambda_simple_env_end_04cf:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04cf:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04cf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04cf
.L_lambda_simple_params_end_04cf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04cf
	jmp .L_lambda_simple_end_04cf
.L_lambda_simple_code_04cf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04cf
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04cf:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1	; arg count
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
	push 1	; arg count
	mov rax, qword [free_var_127]	; free var string-length
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
.L_lambda_simple_env_loop_04d0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_04d0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04d0
.L_lambda_simple_env_end_04d0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04d0:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_04d0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04d0
.L_lambda_simple_params_end_04d0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04d0
	jmp .L_lambda_simple_end_04d0
.L_lambda_simple_code_04d0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04d0
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d0:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03fe
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_074e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_074e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_074e
.L_tc_recycle_frame_done_074e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03fe
.L_if_else_03fe:
	mov rax, L_constants + 2
.L_if_end_03fe:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04d0:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 2
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_074d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_074d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_074d
.L_tc_recycle_frame_done_074d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04cf:	; new closure is in rax
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
.L_lambda_simple_env_loop_04d1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_04d1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04d1
.L_lambda_simple_env_end_04d1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04d1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04d1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04d1
.L_lambda_simple_params_end_04d1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04d1
	jmp .L_lambda_simple_end_04d1
.L_lambda_simple_code_04d1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04d1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d1:
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_04d2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_04d2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04d2
.L_lambda_simple_env_end_04d2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04d2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04d2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04d2
.L_lambda_simple_params_end_04d2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04d2
	jmp .L_lambda_simple_end_04d2
.L_lambda_simple_code_04d2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04d2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d2:
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
.L_lambda_simple_env_loop_04d3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_04d3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04d3
.L_lambda_simple_env_end_04d3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04d3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04d3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04d3
.L_lambda_simple_params_end_04d3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04d3
	jmp .L_lambda_simple_end_04d3
.L_lambda_simple_code_04d3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04d3
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d3:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0059
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
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
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var binary-string=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ff
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
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
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0750:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0750
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0750
.L_tc_recycle_frame_done_0750:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03ff
.L_if_else_03ff:
	mov rax, L_constants + 2
.L_if_end_03ff:
.L_or_end_0059:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04d3:	; new closure is in rax
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
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_00bb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_opt_env_end_00bb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00bb
.L_lambda_opt_env_end_00bb:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00bb:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00bb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00bb
.L_lambda_opt_params_end_00bb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00bb
	jmp .L_lambda_opt_end_00bb
.L_lambda_opt_code_00bb:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_00bb
	ja .L_lambda_opt_arity_check_more_00bb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00bb: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0230:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0230
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0230
.L_lambda_opt_stack_shrink_loop_exit_0230:
	lea r10, [rsp + 8* 1 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_0231:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0231
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0231
.L_lambda_opt_stack_shrink_loop_exit_0231:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00bb
.L_lambda_opt_arity_check_exact_00bb: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_022f:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_022f
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_022f
.L_lambda_opt_stack_shrink_loop_exit_022f:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00bb:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0751:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0751
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0751
.L_tc_recycle_frame_done_0751:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_00bb:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04d2:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_074f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_074f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_074f
.L_tc_recycle_frame_done_074f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04d1:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_074c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_074c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_074c
.L_tc_recycle_frame_done_074c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04cd:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_074a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_074a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_074a
.L_tc_recycle_frame_done_074a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04cc:	; new closure is in rax
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_04d4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04d4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04d4
.L_lambda_simple_env_end_04d4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04d4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04d4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04d4
.L_lambda_simple_params_end_04d4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04d4
	jmp .L_lambda_simple_end_04d4
.L_lambda_simple_code_04d4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04d4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d4:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_75]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
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
	push 1	; arg count
	mov rax, PARAM(0)	; param make-string=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_123], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04d4:	; new closure is in rax
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
.L_lambda_simple_env_loop_04d5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04d5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04d5
.L_lambda_simple_env_end_04d5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04d5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04d5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04d5
.L_lambda_simple_params_end_04d5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04d5
	jmp .L_lambda_simple_end_04d5
.L_lambda_simple_code_04d5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04d5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d5:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_005a
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0400
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0752:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0752
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0752
.L_tc_recycle_frame_done_0752:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0400
.L_if_else_0400:
	mov rax, L_constants + 2
.L_if_end_0400:
.L_or_end_005a:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04d5:	; new closure is in rax
	mov qword [free_var_96], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, qword [free_var_101]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_04d6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04d6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04d6
.L_lambda_simple_env_end_04d6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04d6:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04d6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04d6
.L_lambda_simple_params_end_04d6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04d6
	jmp .L_lambda_simple_end_04d6
.L_lambda_simple_code_04d6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04d6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d6:
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
.L_lambda_opt_env_loop_00bc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00bc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00bc
.L_lambda_opt_env_end_00bc:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00bc:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00bc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00bc
.L_lambda_opt_params_end_00bc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00bc
	jmp .L_lambda_opt_end_00bc
.L_lambda_opt_code_00bc:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_00bc
	ja .L_lambda_opt_arity_check_more_00bc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00bc: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0233:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0233
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0233
.L_lambda_opt_stack_shrink_loop_exit_0233:
	lea r10, [rsp + 8* 1 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_0234:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0234
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0234
.L_lambda_opt_stack_shrink_loop_exit_0234:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00bc
.L_lambda_opt_arity_check_exact_00bc: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0232:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0232
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0232
.L_lambda_opt_stack_shrink_loop_exit_0232:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00bc:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0403
	mov rax, L_constants + 0
	jmp .L_if_end_0403
.L_if_else_0403:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0401
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0401
.L_if_else_0401:
	mov rax, L_constants + 2
.L_if_end_0401:
	cmp rax, sob_boolean_false
	je .L_if_else_0402
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0402
.L_if_else_0402:
	; preparing a non-tail-call
	mov rax, L_constants + 2955
	push rax
	mov rax, L_constants + 2946
	push rax
	push 2	; arg count
	mov rax, qword [free_var_82]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
.L_if_end_0402:
.L_if_end_0403:
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
.L_lambda_simple_env_loop_04d7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_04d7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04d7
.L_lambda_simple_env_end_04d7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04d7:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_04d7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04d7
.L_lambda_simple_params_end_04d7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04d7
	jmp .L_lambda_simple_end_04d7
.L_lambda_simple_code_04d7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04d7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d7:
	enter 0, 0
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0754:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0754
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0754
.L_tc_recycle_frame_done_0754:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04d7:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0753:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0753
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0753
.L_tc_recycle_frame_done_0753:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_00bc:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04d6:	; new closure is in rax
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
	push 1	; arg count
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
.L_lambda_simple_env_loop_04d8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04d8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04d8
.L_lambda_simple_env_end_04d8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04d8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04d8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04d8
.L_lambda_simple_params_end_04d8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04d8
	jmp .L_lambda_simple_end_04d8
.L_lambda_simple_code_04d8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04d8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d8:
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
.L_lambda_opt_env_loop_00bd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00bd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00bd
.L_lambda_opt_env_end_00bd:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00bd:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00bd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00bd
.L_lambda_opt_params_end_00bd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00bd
	jmp .L_lambda_opt_end_00bd
.L_lambda_opt_code_00bd:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 2
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_00bd
	ja .L_lambda_opt_arity_check_more_00bd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00bd: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0236:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0236
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0236
.L_lambda_opt_stack_shrink_loop_exit_0236:
	lea r10, [rsp + 8* 1 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 4
	mov rcx, 4 + 1
.L_lambda_opt_stack_shrink_loop_0237:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0237
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0237
.L_lambda_opt_stack_shrink_loop_exit_0237:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00bd
.L_lambda_opt_arity_check_exact_00bd: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0235:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0235
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0235
.L_lambda_opt_stack_shrink_loop_exit_0235:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00bd:
	mov qword [rsp + 8*2], 2
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0406
	mov rax, L_constants + 4
	jmp .L_if_end_0406
.L_if_else_0406:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0404
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0404
.L_if_else_0404:
	mov rax, L_constants + 2
.L_if_end_0404:
	cmp rax, sob_boolean_false
	je .L_if_else_0405
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0405
.L_if_else_0405:
	; preparing a non-tail-call
	mov rax, L_constants + 3016
	push rax
	mov rax, L_constants + 3007
	push rax
	push 2	; arg count
	mov rax, qword [free_var_82]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
.L_if_end_0405:
.L_if_end_0406:
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
.L_lambda_simple_env_loop_04d9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_04d9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04d9
.L_lambda_simple_env_end_04d9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04d9:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_04d9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04d9
.L_lambda_simple_params_end_04d9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04d9
	jmp .L_lambda_simple_end_04d9
.L_lambda_simple_code_04d9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04d9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d9:
	enter 0, 0
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0756:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0756
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0756
.L_tc_recycle_frame_done_0756:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04d9:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0755:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0755
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0755
.L_tc_recycle_frame_done_0755:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 2)
.L_lambda_opt_end_00bd:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04d8:	; new closure is in rax
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
	push 1	; arg count
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
.L_lambda_simple_env_loop_04da:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04da
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04da
.L_lambda_simple_env_end_04da:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04da:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04da
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04da
.L_lambda_simple_params_end_04da:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04da
	jmp .L_lambda_simple_end_04da
.L_lambda_simple_code_04da:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04da
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04da:
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
.L_lambda_simple_env_loop_04db:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04db
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04db
.L_lambda_simple_env_end_04db:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04db:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04db
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04db
.L_lambda_simple_params_end_04db:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04db
	jmp .L_lambda_simple_end_04db
.L_lambda_simple_code_04db:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04db
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04db:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0407
	; preparing a tail-call
	mov rax, L_constants + 0
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_0757:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0757
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0757
.L_tc_recycle_frame_done_0757:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0407
.L_if_else_0407:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
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
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
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
.L_lambda_simple_env_loop_04dc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_04dc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04dc
.L_lambda_simple_env_end_04dc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04dc:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_04dc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04dc
.L_lambda_simple_params_end_04dc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04dc
	jmp .L_lambda_simple_end_04dc
.L_lambda_simple_code_04dc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04dc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04dc:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1	; arg count
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
	push 3	; arg count
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
.L_lambda_simple_end_04dc:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0758:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0758
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0758
.L_tc_recycle_frame_done_0758:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0407:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04db:	; new closure is in rax
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
.L_lambda_simple_env_loop_04dd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04dd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04dd
.L_lambda_simple_env_end_04dd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04dd:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04dd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04dd
.L_lambda_simple_params_end_04dd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04dd
	jmp .L_lambda_simple_end_04dd
.L_lambda_simple_code_04dd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04dd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04dd:
	enter 0, 0
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0759:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0759
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0759
.L_tc_recycle_frame_done_0759:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04dd:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04da:	; new closure is in rax
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
	push 1	; arg count
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
.L_lambda_simple_env_loop_04de:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04de
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04de
.L_lambda_simple_env_end_04de:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04de:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04de
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04de
.L_lambda_simple_params_end_04de:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04de
	jmp .L_lambda_simple_end_04de
.L_lambda_simple_code_04de:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04de
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04de:
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
.L_lambda_simple_env_loop_04df:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04df
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04df
.L_lambda_simple_env_end_04df:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04df:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04df
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04df
.L_lambda_simple_params_end_04df:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04df
	jmp .L_lambda_simple_end_04df
.L_lambda_simple_code_04df:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04df
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04df:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0408
	; preparing a tail-call
	mov rax, L_constants + 4
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_075a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_075a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_075a
.L_tc_recycle_frame_done_075a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0408
.L_if_else_0408:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
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
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
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
.L_lambda_simple_env_loop_04e0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_04e0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04e0
.L_lambda_simple_env_end_04e0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04e0:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_04e0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04e0
.L_lambda_simple_params_end_04e0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04e0
	jmp .L_lambda_simple_end_04e0
.L_lambda_simple_code_04e0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04e0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e0:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1	; arg count
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
	push 3	; arg count
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
.L_lambda_simple_end_04e0:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_075b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_075b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_075b
.L_tc_recycle_frame_done_075b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0408:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04df:	; new closure is in rax
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
.L_lambda_simple_env_loop_04e1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04e1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04e1
.L_lambda_simple_env_end_04e1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04e1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04e1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04e1
.L_lambda_simple_params_end_04e1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04e1
	jmp .L_lambda_simple_end_04e1
.L_lambda_simple_code_04e1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04e1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e1:
	enter 0, 0
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_075c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_075c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_075c
.L_tc_recycle_frame_done_075c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04e1:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04de:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_94], rax
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
.L_lambda_opt_env_loop_00be:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_00be
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00be
.L_lambda_opt_env_end_00be:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00be:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_00be
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00be
.L_lambda_opt_params_end_00be:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00be
	jmp .L_lambda_opt_end_00be
.L_lambda_opt_code_00be:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_00be
	ja .L_lambda_opt_arity_check_more_00be
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00be: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_0239:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0239
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0239
.L_lambda_opt_stack_shrink_loop_exit_0239:
	lea r10, [rsp + 8* 0 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_023a:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_023a
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_023a
.L_lambda_opt_stack_shrink_loop_exit_023a:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00be
.L_lambda_opt_arity_check_exact_00be: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_0238:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0238
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0238
.L_lambda_opt_stack_shrink_loop_exit_0238:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00be:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_075d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_075d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_075d
.L_tc_recycle_frame_done_075d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_00be:	; new closure is in rax
	mov qword [free_var_140], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_04e2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04e2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04e2
.L_lambda_simple_env_end_04e2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04e2:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04e2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04e2
.L_lambda_simple_params_end_04e2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04e2
	jmp .L_lambda_simple_end_04e2
.L_lambda_simple_code_04e2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04e2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e2:
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
.L_lambda_simple_env_loop_04e3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04e3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04e3
.L_lambda_simple_env_end_04e3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04e3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04e3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04e3
.L_lambda_simple_params_end_04e3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04e3
	jmp .L_lambda_simple_end_04e3
.L_lambda_simple_code_04e3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_04e3
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e3:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0409
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
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
	push 3	; arg count
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
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
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
.L_tc_recycle_frame_loop_075e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_075e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_075e
.L_tc_recycle_frame_done_075e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0409
.L_if_else_0409:
	mov rax, L_constants + 1
.L_if_end_0409:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_04e3:	; new closure is in rax
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
.L_lambda_simple_env_loop_04e4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04e4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04e4
.L_lambda_simple_env_end_04e4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04e4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04e4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04e4
.L_lambda_simple_params_end_04e4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04e4
	jmp .L_lambda_simple_end_04e4
.L_lambda_simple_code_04e4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04e4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e4:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_075f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_075f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_075f
.L_tc_recycle_frame_done_075f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04e4:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04e2:	; new closure is in rax
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
	push 1	; arg count
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
.L_lambda_simple_env_loop_04e5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04e5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04e5
.L_lambda_simple_env_end_04e5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04e5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04e5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04e5
.L_lambda_simple_params_end_04e5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04e5
	jmp .L_lambda_simple_end_04e5
.L_lambda_simple_code_04e5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04e5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e5:
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
.L_lambda_simple_env_loop_04e6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04e6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04e6
.L_lambda_simple_env_end_04e6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04e6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04e6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04e6
.L_lambda_simple_params_end_04e6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04e6
	jmp .L_lambda_simple_end_04e6
.L_lambda_simple_code_04e6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_04e6
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e6:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_040a
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
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
	push 3	; arg count
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
	push 2	; arg count
	mov rax, qword [free_var_144]	; free var vector-ref
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
.L_tc_recycle_frame_loop_0760:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0760
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0760
.L_tc_recycle_frame_done_0760:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_040a
.L_if_else_040a:
	mov rax, L_constants + 1
.L_if_end_040a:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_04e6:	; new closure is in rax
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
.L_lambda_simple_env_loop_04e7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04e7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04e7
.L_lambda_simple_env_end_04e7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04e7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_04e7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04e7
.L_lambda_simple_params_end_04e7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04e7
	jmp .L_lambda_simple_end_04e7
.L_lambda_simple_code_04e7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04e7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e7:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param v
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0761:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0761
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0761
.L_tc_recycle_frame_done_0761:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04e7:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04e5:	; new closure is in rax
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
.L_lambda_simple_env_loop_04e8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04e8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04e8
.L_lambda_simple_env_end_04e8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04e8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04e8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04e8
.L_lambda_simple_params_end_04e8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04e8
	jmp .L_lambda_simple_end_04e8
.L_lambda_simple_code_04e8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04e8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e8:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param n
	push rax
	; preparing a non-tail-call
	push 0	; arg count
	mov rax, qword [free_var_139]	; free var trng
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_0762:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0762
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0762
.L_tc_recycle_frame_done_0762:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04e8:	; new closure is in rax
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
.L_lambda_simple_env_loop_04e9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04e9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04e9
.L_lambda_simple_env_end_04e9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04e9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04e9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04e9
.L_lambda_simple_params_end_04e9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04e9
	jmp .L_lambda_simple_end_04e9
.L_lambda_simple_code_04e9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04e9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e9:
	enter 0, 0
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0763:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0763
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0763
.L_tc_recycle_frame_done_0763:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04e9:	; new closure is in rax
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
.L_lambda_simple_env_loop_04ea:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04ea
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04ea
.L_lambda_simple_env_end_04ea:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04ea:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04ea
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04ea
.L_lambda_simple_params_end_04ea:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04ea
	jmp .L_lambda_simple_end_04ea
.L_lambda_simple_code_04ea:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04ea
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ea:
	enter 0, 0
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0764:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0764
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0764
.L_tc_recycle_frame_done_0764:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04ea:	; new closure is in rax
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
.L_lambda_simple_env_loop_04eb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04eb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04eb
.L_lambda_simple_env_end_04eb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04eb:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04eb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04eb
.L_lambda_simple_params_end_04eb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04eb
	jmp .L_lambda_simple_end_04eb
.L_lambda_simple_code_04eb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04eb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04eb:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 3190
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var remainder
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0765:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0765
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0765
.L_tc_recycle_frame_done_0765:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04eb:	; new closure is in rax
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
.L_lambda_simple_env_loop_04ec:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04ec
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04ec
.L_lambda_simple_env_end_04ec:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04ec:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04ec
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04ec
.L_lambda_simple_params_end_04ec:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04ec
	jmp .L_lambda_simple_end_04ec
.L_lambda_simple_code_04ec:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04ec
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ec:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_83]	; free var even?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0766:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0766
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0766
.L_tc_recycle_frame_done_0766:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04ec:	; new closure is in rax
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
.L_lambda_simple_env_loop_04ed:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04ed
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04ed
.L_lambda_simple_env_end_04ed:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04ed:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04ed
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04ed
.L_lambda_simple_params_end_04ed:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04ed
	jmp .L_lambda_simple_end_04ed
.L_lambda_simple_code_04ed:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04ed
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ed:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_104]	; free var negative?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_040b
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0767:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0767
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0767
.L_tc_recycle_frame_done_0767:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_040b
.L_if_else_040b:
	mov rax, PARAM(0)	; param x
.L_if_end_040b:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04ed:	; new closure is in rax
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
.L_lambda_simple_env_loop_04ee:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04ee
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04ee
.L_lambda_simple_env_end_04ee:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04ee:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04ee
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04ee
.L_lambda_simple_params_end_04ee:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04ee
	jmp .L_lambda_simple_end_04ee
.L_lambda_simple_code_04ee:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04ee
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ee:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_040c
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_040c
.L_if_else_040c:
	mov rax, L_constants + 2
.L_if_end_040c:
	cmp rax, sob_boolean_false
	je .L_if_else_0418
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
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
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_81]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_040d
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
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
	push 1	; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_0768:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0768
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0768
.L_tc_recycle_frame_done_0768:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_040d
.L_if_else_040d:
	mov rax, L_constants + 2
.L_if_end_040d:
	jmp .L_if_end_0418
.L_if_else_0418:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_148]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_040f
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_148]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_040e
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
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
	push 1	; arg count
	mov rax, qword [free_var_143]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_040e
.L_if_else_040e:
	mov rax, L_constants + 2
.L_if_end_040e:
	jmp .L_if_end_040f
.L_if_else_040f:
	mov rax, L_constants + 2
.L_if_end_040f:
	cmp rax, sob_boolean_false
	je .L_if_else_0417
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
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
	push 1	; arg count
	mov rax, qword [free_var_141]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_0769:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0769
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0769
.L_tc_recycle_frame_done_0769:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0417
.L_if_else_0417:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_138]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0411
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_138]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0410
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
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
	push 1	; arg count
	mov rax, qword [free_var_127]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0410
.L_if_else_0410:
	mov rax, L_constants + 2
.L_if_end_0410:
	jmp .L_if_end_0411
.L_if_else_0411:
	mov rax, L_constants + 2
.L_if_end_0411:
	cmp rax, sob_boolean_false
	je .L_if_else_0416
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_076a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_076a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_076a
.L_tc_recycle_frame_done_076a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0416
.L_if_else_0416:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_108]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0412
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_108]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0412
.L_if_else_0412:
	mov rax, L_constants + 2
.L_if_end_0412:
	cmp rax, sob_boolean_false
	je .L_if_else_0415
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_076b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_076b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_076b
.L_tc_recycle_frame_done_076b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0415
.L_if_else_0415:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_78]	; free var char?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0413
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_78]	; free var char?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0413
.L_if_else_0413:
	mov rax, L_constants + 2
.L_if_end_0413:
	cmp rax, sob_boolean_false
	je .L_if_else_0414
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_076c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_076c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_076c
.L_tc_recycle_frame_done_076c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0414
.L_if_else_0414:
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_076d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_076d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_076d
.L_tc_recycle_frame_done_076d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0414:
.L_if_end_0415:
.L_if_end_0416:
.L_if_end_0417:
.L_if_end_0418:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04ee:	; new closure is in rax
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
.L_lambda_simple_env_loop_04ef:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04ef
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04ef
.L_lambda_simple_env_end_04ef:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04ef:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04ef
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04ef
.L_lambda_simple_params_end_04ef:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04ef
	jmp .L_lambda_simple_end_04ef
.L_lambda_simple_code_04ef:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04ef
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ef:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_041a
	mov rax, L_constants + 2
	jmp .L_if_end_041a
.L_if_else_041a:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_80]	; free var eq?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0419
	; preparing a tail-call
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
.L_tc_recycle_frame_loop_076e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_076e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_076e
.L_tc_recycle_frame_done_076e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0419
.L_if_else_0419:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_076f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_076f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_076f
.L_tc_recycle_frame_done_076f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0419:
.L_if_end_041a:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04ef:	; new closure is in rax
	mov qword [free_var_34], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2	; arg count
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
.L_lambda_simple_env_loop_04f0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04f0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04f0
.L_lambda_simple_env_end_04f0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04f0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04f0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04f0
.L_lambda_simple_params_end_04f0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04f0
	jmp .L_lambda_simple_end_04f0
.L_lambda_simple_code_04f0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04f0
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f0:
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
.L_lambda_simple_env_loop_04f1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04f1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04f1
.L_lambda_simple_env_end_04f1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04f1:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_04f1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04f1
.L_lambda_simple_params_end_04f1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04f1
	jmp .L_lambda_simple_end_04f1
.L_lambda_simple_code_04f1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_04f1
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f1:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_041b
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_041b
.L_if_else_041b:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
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
	push 1	; arg count
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
	push 5	; arg count
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
.L_lambda_simple_env_loop_04f2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_04f2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04f2
.L_lambda_simple_env_end_04f2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04f2:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_04f2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04f2
.L_lambda_simple_params_end_04f2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04f2
	jmp .L_lambda_simple_end_04f2
.L_lambda_simple_code_04f2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04f2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f2:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0771:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0771
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0771
.L_tc_recycle_frame_done_0771:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04f2:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0770:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0770
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0770
.L_tc_recycle_frame_done_0770:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_041b:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_04f1:	; new closure is in rax
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
.L_lambda_simple_env_loop_04f3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04f3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04f3
.L_lambda_simple_env_end_04f3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04f3:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_04f3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04f3
.L_lambda_simple_params_end_04f3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04f3
	jmp .L_lambda_simple_end_04f3
.L_lambda_simple_code_04f3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_04f3
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f3:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_041c
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param str
	push rax
	push 2	; arg count
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
	push 3	; arg count
	mov rax, qword [free_var_131]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
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
	push 2	; arg count
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
.L_tc_recycle_frame_loop_0772:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0772
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0772
.L_tc_recycle_frame_done_0772:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_041c
.L_if_else_041c:
	mov rax, PARAM(1)	; param i
.L_if_end_041c:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_04f3:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param add
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
.L_lambda_opt_env_loop_00bf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00bf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00bf
.L_lambda_opt_env_end_00bf:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00bf:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_00bf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00bf
.L_lambda_opt_params_end_00bf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00bf
	jmp .L_lambda_opt_end_00bf
.L_lambda_opt_code_00bf:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_00bf
	ja .L_lambda_opt_arity_check_more_00bf
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00bf: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_023c:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_023c
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_023c
.L_lambda_opt_stack_shrink_loop_exit_023c:
	lea r10, [rsp + 8* 0 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_023d:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_023d
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_023d
.L_lambda_opt_stack_shrink_loop_exit_023d:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00bf
.L_lambda_opt_arity_check_exact_00bf: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_023b:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_023b
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_023b
.L_lambda_opt_stack_shrink_loop_exit_023b:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00bf:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	; preparing a tail-call
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
	push 2	; arg count
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
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_99]	; free var make-string
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
.L_tc_recycle_frame_loop_0773:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0773
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0773
.L_tc_recycle_frame_done_0773:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_00bf:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04f0:	; new closure is in rax
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
	push 2	; arg count
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
.L_lambda_simple_env_loop_04f4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04f4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04f4
.L_lambda_simple_env_end_04f4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04f4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04f4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04f4
.L_lambda_simple_params_end_04f4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04f4
	jmp .L_lambda_simple_end_04f4
.L_lambda_simple_code_04f4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04f4
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f4:
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
.L_lambda_simple_env_loop_04f5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04f5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04f5
.L_lambda_simple_env_end_04f5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04f5:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_04f5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04f5
.L_lambda_simple_params_end_04f5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04f5
	jmp .L_lambda_simple_end_04f5
.L_lambda_simple_code_04f5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_04f5
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f5:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_107]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_041d
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_041d
.L_if_else_041d:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
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
	push 1	; arg count
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
	push 5	; arg count
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
.L_lambda_simple_env_loop_04f6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_04f6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04f6
.L_lambda_simple_env_end_04f6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04f6:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_04f6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04f6
.L_lambda_simple_params_end_04f6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04f6
	jmp .L_lambda_simple_end_04f6
.L_lambda_simple_code_04f6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04f6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f6:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0775:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0775
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0775
.L_tc_recycle_frame_done_0775:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04f6:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0774:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0774
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0774
.L_tc_recycle_frame_done_0774:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_041d:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_04f5:	; new closure is in rax
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
.L_lambda_simple_env_loop_04f7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_04f7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04f7
.L_lambda_simple_env_end_04f7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04f7:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_04f7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04f7
.L_lambda_simple_params_end_04f7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04f7
	jmp .L_lambda_simple_end_04f7
.L_lambda_simple_code_04f7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_04f7
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f7:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_041e
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	push 2	; arg count
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
	push 3	; arg count
	mov rax, qword [free_var_147]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
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
	push 2	; arg count
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
.L_tc_recycle_frame_loop_0776:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0776
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0776
.L_tc_recycle_frame_done_0776:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_041e
.L_if_else_041e:
	mov rax, PARAM(1)	; param i
.L_if_end_041e:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_04f7:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param add
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
.L_lambda_opt_env_loop_00c0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00c0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00c0
.L_lambda_opt_env_end_00c0:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00c0:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_00c0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00c0
.L_lambda_opt_params_end_00c0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00c0
	jmp .L_lambda_opt_end_00c0
.L_lambda_opt_code_00c0:	; lambda-opt body
	mov r8, qword [rsp + 8*2]
	mov r9, 1
	lea r13, [r8 + 2] 
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_00c0
	ja .L_lambda_opt_arity_check_more_00c0
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_00c0: ;More case
	mov r15, r8
	sub r15, r9
	lea rcx, [r15 + 1]
	lea r12, [rsp + 8*r8 + 8*2]
	mov r11, sob_nil
.L_lambda_opt_stack_shrink_loop_023f:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_023f
	mov rdi, 17
	call malloc
	mov byte [rax], T_pair
	mov rbx, qword [r12]
	mov qword [rax + 1], rbx
	mov qword [rax + 1 + 8], r11
	mov r11, rax
	sub r12, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_023f
.L_lambda_opt_stack_shrink_loop_exit_023f:
	lea r10, [rsp + 8* 0 + 8*3]
	mov qword [r10], r11
	lea r13, [8 * r13]
	add r13, rsp
	mov r14, 3
	mov rcx, 4 + 0
.L_lambda_opt_stack_shrink_loop_0240:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_0240
	mov r11, qword [r10]
	mov qword [r13], r11
	sub r10, 8
	sub r13, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_0240
.L_lambda_opt_stack_shrink_loop_exit_0240:
	add r13, 8
	mov rsp, r13
jmp .L_lambda_opt_stack_adjusted_00c0
.L_lambda_opt_arity_check_exact_00c0: ;Exact case
	mov r8, qword [rsp -8 * 0]
	mov qword [rsp -8 * 1], r8
	mov r8, qword [rsp +8 * 1]
	mov qword [rsp +8 * 0], r8
	mov r8, qword [rsp +8 * 2]
	mov rcx, r8
	inc r8
	mov qword [rsp +8 * 1], r8
	mov rdx, rsp
	add rdx, 24
.L_lambda_opt_stack_shrink_loop_023e:
	cmp rcx, 0
	je .L_lambda_opt_stack_shrink_loop_exit_023e
	mov r8, [rdx]
	mov qword [rdx -8], r8
	add rdx, 8
	dec rcx
	jmp .L_lambda_opt_stack_shrink_loop_023e
.L_lambda_opt_stack_shrink_loop_exit_023e:
	mov qword [rdx -8], sob_nil
	sub rsp, 8
.L_lambda_opt_stack_adjusted_00c0:
	mov qword [rsp + 8*2], 1
	enter 0, 0
	; preparing a tail-call
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
	push 2	; arg count
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
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_101]	; free var make-vector
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
.L_tc_recycle_frame_loop_0777:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0777
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0777
.L_tc_recycle_frame_done_0777:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret 8 * (2 + 1)
.L_lambda_opt_end_00c0:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04f4:	; new closure is in rax
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
.L_lambda_simple_env_loop_04f8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_04f8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_04f8
.L_lambda_simple_env_end_04f8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_04f8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_04f8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_04f8
.L_lambda_simple_params_end_04f8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_04f8
	jmp .L_lambda_simple_end_04f8
.L_lambda_simple_code_04f8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04f8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f8:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
	mov rax, qword [free_var_119]	; free var string->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_118]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0778:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0778
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0778
.L_tc_recycle_frame_done_0778:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04f8:	; new closure is in rax
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
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param vec
	push rax
	push 1	; arg count
	mov rax, qword [free_var_141]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_118]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0779:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0779
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0779
.L_tc_recycle_frame_done_0779:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04f9:	; new closure is in rax
	mov qword [free_var_145], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	mov rax, L_constants + 1993
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_04fb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
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
	cmp rsi, 1
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
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_04fb
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04fb:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param j
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_041f
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, qword [free_var_128]	; free var string-ref
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
.L_lambda_simple_env_loop_04fc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
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
	cmp rsi, 3
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
	push 2	; arg count
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
	push 3	; arg count
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
	push 3	; arg count
	mov rax, qword [free_var_131]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	push 2	; arg count
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
	push 2	; arg count
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
.L_tc_recycle_frame_loop_077b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_077b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_077b
.L_tc_recycle_frame_done_077b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04fc:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_077a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_077a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_077a
.L_tc_recycle_frame_done_077a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_041f
.L_if_else_041f:
	mov rax, PARAM(0)	; param str
.L_if_end_041f:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_04fb:	; new closure is in rax
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
.L_lambda_simple_env_loop_04fd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
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
	cmp rsi, 1
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
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
	mov rax, qword [free_var_127]	; free var string-length
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
.L_lambda_simple_env_loop_04fe:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
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
	cmp rsi, 1
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
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_151]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0420
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	jmp .L_if_end_0420
.L_if_else_0420:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_077d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_077d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_077d
.L_tc_recycle_frame_done_077d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0420:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04fe:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_077c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_077c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_077c
.L_tc_recycle_frame_done_077c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04fd:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04fa:	; new closure is in rax
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
	push 1	; arg count
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
.L_lambda_simple_env_loop_0500:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
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
	cmp rsi, 1
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
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0500
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0500:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param j
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0421
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param vec
	push rax
	push 2	; arg count
	mov rax, qword [free_var_144]	; free var vector-ref
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
.L_lambda_simple_env_loop_0501:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
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
	cmp rsi, 3
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
	push 2	; arg count
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
	push 3	; arg count
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
	push 3	; arg count
	mov rax, qword [free_var_147]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	push 2	; arg count
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
	push 2	; arg count
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
.L_tc_recycle_frame_loop_077f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_077f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_077f
.L_tc_recycle_frame_done_077f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0501:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_077e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_077e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_077e
.L_tc_recycle_frame_done_077e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0421
.L_if_else_0421:
	mov rax, PARAM(0)	; param vec
.L_if_end_0421:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0500:	; new closure is in rax
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
.L_lambda_simple_env_loop_0502:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
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
	cmp rsi, 1
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
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param vec
	push rax
	push 1	; arg count
	mov rax, qword [free_var_143]	; free var vector-length
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
.L_lambda_simple_env_loop_0503:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
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
	cmp rsi, 1
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
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_151]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0422
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	jmp .L_if_end_0422
.L_if_else_0422:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_0781:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0781
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0781
.L_tc_recycle_frame_done_0781:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0422:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0503:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0780:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0780
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0780
.L_tc_recycle_frame_done_0780:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0502:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04ff:	; new closure is in rax
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
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0504
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0504:
	enter 0, 0
	; preparing a tail-call
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
.L_lambda_simple_env_loop_0505:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
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
	cmp rsi, 2
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
.L_lambda_simple_env_loop_0506:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
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
	cmp rsi, 1
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
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0423
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
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
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_0783:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0783
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0783
.L_tc_recycle_frame_done_0783:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0423
.L_if_else_0423:
	mov rax, L_constants + 1
.L_if_end_0423:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0506:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0784:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0784
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0784
.L_tc_recycle_frame_done_0784:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0505:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0782:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0782
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0782
.L_tc_recycle_frame_done_0782:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0504:	; new closure is in rax
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
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0507
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0507:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_99]	; free var make-string
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
.L_lambda_simple_env_loop_0508:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
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
	cmp rsi, 2
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
	; preparing a tail-call
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
.L_lambda_simple_env_loop_0509:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
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
	cmp rsi, 1
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
.L_lambda_simple_env_loop_050a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
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
	cmp rsi, 1
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
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0424
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	push 1	; arg count
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
	push 3	; arg count
	mov rax, qword [free_var_131]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_0787:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0787
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0787
.L_tc_recycle_frame_done_0787:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0424
.L_if_else_0424:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
.L_if_end_0424:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_050a:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
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
.L_tc_recycle_frame_loop_0788:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0788
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0788
.L_tc_recycle_frame_done_0788:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0509:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0786:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0786
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0786
.L_tc_recycle_frame_done_0786:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0508:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0785:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0785
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0785
.L_tc_recycle_frame_done_0785:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0507:	; new closure is in rax
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
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_050b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_050b:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_101]	; free var make-vector
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
.L_lambda_simple_env_loop_050c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
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
	cmp rsi, 2
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
	; preparing a tail-call
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
.L_lambda_simple_env_loop_050d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
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
	cmp rsi, 1
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
.L_lambda_simple_env_loop_050e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
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
	cmp rsi, 1
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
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0425
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	push 1	; arg count
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
	push 3	; arg count
	mov rax, qword [free_var_147]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
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
.L_tc_recycle_frame_loop_078b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_078b
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_078b
.L_tc_recycle_frame_done_078b:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0425
.L_if_else_0425:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
.L_if_end_0425:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_050e:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
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
.L_tc_recycle_frame_loop_078c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_078c
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_078c
.L_tc_recycle_frame_done_078c:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_050d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_078a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_078a
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_078a
.L_tc_recycle_frame_done_078a:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_050c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 1
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0789:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0789
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0789
.L_tc_recycle_frame_done_0789:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_050b:	; new closure is in rax
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
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_050f
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_050f:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_151]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0428
	mov rax, L_constants + 3485
	jmp .L_if_end_0428
.L_if_else_0428:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0427
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2	; arg count
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
	push 3	; arg count
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
.L_tc_recycle_frame_loop_078d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_078d
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_078d
.L_tc_recycle_frame_done_078d:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0427
.L_if_else_0427:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0426
	mov rax, L_constants + 3485
	jmp .L_if_end_0426
.L_if_else_0426:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, PARAM(2)	; param n
	push rax
	push 2	; arg count
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
	push 3	; arg count
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
.L_tc_recycle_frame_loop_078e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_078e
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_078e
.L_tc_recycle_frame_done_078e:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0426:
.L_if_end_0427:
.L_if_end_0428:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_050f:	; new closure is in rax
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
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0510
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0510:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 3510
	push rax
	push 1	; arg count
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
.L_tc_recycle_frame_loop_078f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_078f
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_078f
.L_tc_recycle_frame_done_078f:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0510:	; new closure is in rax
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
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0511
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0511:
	enter 0, 0
	mov rax, L_constants + 0
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0511:	; new closure is in rax
	mov qword [free_var_149], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2135
	push rax
	push 1	; arg count
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
.L_lambda_simple_env_loop_0513:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
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
	cmp rsi, 1
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
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0513
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0513:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, L_constants + 2270
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rbx, qword [rbp+8*2]
	mov rbx, qword [rbx+8*0]
	mov qword [rbx+8*0], rax
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0513:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0512:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
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
	; preparing a non-tail-call
	push 0	; arg count
	mov rax, PARAM(0)	; param counter
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a non-tail-call
	push 0	; arg count
	mov rax, PARAM(0)	; param counter
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a non-tail-call
	push 0	; arg count
	mov rax, PARAM(0)	; param counter
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	push 0	; arg count
	mov rax, PARAM(0)	; param counter
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8 * 1]
	push qword [rbp]
	mov rdi, qword [rbp + 8 * 3]
	lea rdi, [rbp + 8 * rdi + 8 * 3]
	mov rcx, 4 + 0
	lea rsi, [rbp - 8]
.L_tc_recycle_frame_loop_0790:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0790
	mov r10, qword [rsi]
	mov qword [rdi], r10
	sub rdi, 8
	sub rsi, 8
	dec rcx
	jmp .L_tc_recycle_frame_loop_0790
.L_tc_recycle_frame_done_0790:
	lea rsp, [rdi + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0514:	; new closure is in rax
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
	assert_pair(rdi)
	mov rdi, SOB_PAIR_CDR(rdi)
	inc rcx
	jmp .L_bin_apply_calc_number_of_args

.L_bin_apply_end_calc_loop:
        ;3. Update rsp -> rsp - 8 * argv[1].length
        lea r11, [8*(rcx - 3)]
        sub rsp, r11

        ;4. Save RET_ADDR
        mov r10, RET_ADDR
        mov qword [rsp], r10

        ;5. Save SOB_CLOSURE_ENV(proc)
        mov r10, PARAM(0)
        assert_closure(r10)
        mov rax, SOB_CLOSURE_ENV(r10)
        mov qword [rsp + 8 * 1], rax

        ;6. Save new argc = argv[1].length
        mov qword [rsp + 8 * 2], rcx
        
        ;5. Push all args in argv[1] to the stack
        lea r9, [rsp + 8 * 3]
	mov rdi, rsi; rsi - point to the first var in the list

.L_bin_apply_recycle_frame_loop:
	cmp rdi, sob_nil
	je .L_bin_apply_recycle_frame_done
        mov rax, SOB_PAIR_CAR(rdi)
        mov qword [r9], rax
        add r9, 8
        mov rdi, SOB_PAIR_CDR(rdi)
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
