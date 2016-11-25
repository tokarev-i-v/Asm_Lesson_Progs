.686
.model flat, stdcall
option casemap:none

;----------------------------------------

include c:\masm32\include\kernel32.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\gdi32.inc
include c:\masm32\include\windows.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\msvcrt.inc

include Strings.mac

; Len - количество 
BigNumber struct 
	Len dword 0
	Num_p dword 0
	Sig byte 0
BigNumber ends


.data

.data?

.const

.code


bignum_init_null proc uses edx ebx edi bignum_p: dword, len: dword
	local i:dword
	mov [i], 0
	mov eax, [len]
	mov edx, 4
	mul edx
	mov edx, 0
	invoke crt_malloc, eax
	mov ebx, eax
	mov edi, [len]

	.while [i] < edi
		mov edx, [i]
		mov ecx, 0
		mov dword ptr [ebx+edx], dword ptr ecx
		mov ecx, 1
		inc [i]
	.endw

	mov eax, dword ptr [bignum_p]	
	mov ecx, [len]
	mov [BigNumber ptr [eax]].Len, ecx
	mov eax, dword ptr [bignum_p]	
	mov [BigNumber ptr [eax]].Num_p, ebx
	mov [BigNumber ptr [eax]].Sig, 0

	mov eax, 0
	ret
bignum_init_null endp

bignum_set_str proc bignum_p: dword, str_p: dword
	; счетчики
	local i:dword
	local k:dword
	; переменная для разного использования
	local temp: dword
	; знак нового числа
	local signum: byte
	local StrLen: dword
	local Str_p: dword
	local tstr[11]: byte

	; начальная инициализация

	; записываем значение знака в структуру
	; записываем значение знака
	mov ebx, [str_p]
	mov ecx, [BN_p]
	.if byte ptr [ebx+0] == '-'
		mov [signum], 1
		mov [BigNumber ptr [ecx]].Sig, 1
	.else
		mov [signum], 0
		mov [BigNumber ptr [ecx]].Sig, 0
	.endif
	

	; копируем строку без "0x", и без '-' в зависимости от знака
	mov ebx, [str_p]
	invoke crt_strlen, [str_p]
	.if [signum] == 0
		sub eax, 2
	.else
		sub eax, 3
	.endif
	invoke crt_malloc, eax
	mov [Str_p], eax
	mov ebx, [str_p]
	.if [signum] == 0
		add ebx, 2
	.else
		add ebx, 3
	.endif
	invoke crt_strcpy, [Str_p], ebx
	; конец копирования

	; выделяем память под новое число
	invoke crt_strlen, [Str_p]
	mov [StrLen], eax
	mov edx, 0
	div 8 
	;теперь целая часть сохранилась в eax, остаток - edx
	inc eax ; увеличиваем, чтобы учесть остаток
	mov ebx, sizeof(dword)
	mul ebx	
	invoke crt_malloc, eax ; непосредственно - выделение
	mov ebx, [bignum_p]
	mov [BigNumber ptr [ebx]].Num_p, eax
	; сохранили указатель на выделенную память в структуру
	; конец

	; теперь записываем значение длины элементов числа
	mov eax, [StrLen]
	mov edx, 0
	.if(edx != 0)
		inc eax		
	.endif
	mov [BigNumber ptr [ebx]].Len, eax
	; записали значение длины

	; теперь заполняем 0 все разряды
	mov ebx, [BN_p] ; вначале получаем адрес структуры
	mov edi, [BigNumber ptr [ebx]].Len ;записываем значение длины
	mov ebx, [BigNumber ptr [ebx].Num_p; теперь записываем в ebx адрес
	; самого числа
	mov [i], 0 ; первый элемент
	;mov [k], 4 ; множитель
	.while [i] < edi
		mov eax, [i]
		mul 4
		mov  [ebx+eax], 0
		inc [i]
	.endw
	; заполнили 0 разряды!

	; теперь заполняем слова
	mov ebx, [BN_p] ; вначале получаем адрес структуры
	mov ebx, [BigNumber ptr [ebx].Num_p; перезаписываем содержимое ebx
	mov [i], 0 ; первый элемент
	.while [StrLen] > 7
		mov [k], 0
		.while [k] < 8
			mov eax, [StrLen]
			sub eax, k
			dec eax
			mov edx, [Str_p]
			mov byte ptr [temp], byte ptr [edx+eax]

			mov edx, 7
			sub edx, k
			mov tstr[edx], byte ptr [temp]
			
			inc [k]
		.endw

		sub [StrLen], 8
		mov tstr[k], 0
		invoke crt_strtoul, NULL, 16
		inc [i]
	.endw

	mov eax, 0
	   ret
bignum_set_str endp

bignum_st_ui proc bignum_p: dword, number: dword

bignum_st_ui endp

bignum_set_i proc bignum_p: dword, number: dword

bignum_set_i endp

bignum_add proc bignum_res_p: dword, bignum_1_p: dword, bignum_2_p: dword

bignum_add endp

bignum_sub proc bignum_res_p: dword, bignum_1_p: dword, bignum_2_p: dword

bignum_sub endp

bignum_xor proc bignum_res_p: dword, bignum_1_p: dword, bignum_2_p: dword

bignum_xor endp

bignum_or proc bignum_res_p: dword, bignum_1_p: dword, bignum_2_p: dword

bignum_or endp

bignum_and proc bignum_res_p: dword, bignum_1_p: dword, bignum_2_p: dword

bignum_and endp

bignum_mul_ui proc bignum_res_p: dword, bignum_1_p: dword, bignum_2_p: dword

bignum_mul_ui endp




main proc stdcall
	local StrLen: dword
	local Str_1: dword
	local BN_p: dword
	invoke crt_malloc, sizeof(BigNumber)
	mov [BN_p], eax
	invoke bignum_init_null, [BN_p], 50
	mov eax, [BN_p]
	invoke crt_printf, $CTA0("%i\n"), [BigNumber ptr [eax]].Len
	
	invoke crt_malloc, 12
	mov [Str_1], eax
	invoke crt_strcpy, [Str_1], $CTA0("HELLO_WORLD")

	invoke crt_strlen, [Str_1]
	mov [StrLen], eax
	invoke crt_printf, $CTA0("%i\n"), [StrLen]
	
		
	invoke crt_system, $CTA0("pause")
	mov eax, 0
	ret
main endp

end main
