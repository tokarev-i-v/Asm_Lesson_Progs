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

bignum_print proc uses ebx edx ecx edi esi bignum_p: dword
	local i: dword
	mov ebx, [bignum_p]
	mov ecx, [BigNumber ptr [ebx]].Len
	dec ecx
	mov [i], ecx

	.if [i] == 0
		mov ecx, [BigNumber ptr [ebx]].Num_p
		mov ecx, [ecx]
		invoke crt_printf, $CTA0("%08X \n"), ecx
		mov eax, 0
		ret
	.endif
	
	.while 1
		mov ebx, [bignum_p]
		mov ebx, [BigNumber ptr [ebx]].Num_p
		mov eax, [i]
		mov ecx, [ebx+eax*4]
		invoke crt_printf, $CTA0("%08X "), ecx
		.if [i] == 0
			.break
		.endif
		dec [i]
	.endw

	invoke crt_printf, $CTA0("\n")
	mov eax, 0
	ret
bignum_print endp


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
	local rest: dword
	local StrLen: dword
	local Str_p: dword
	local tstr[11]: byte

	; начальная инициализация

	; записываем значение знака в структуру
	; записываем значение знака
	mov ebx, [str_p]
	mov ecx, [bignum_p]
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
	mov ecx, 8
	mov [StrLen], eax
	mov edx, 0
	div ecx
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
	mov ecx, 8
	div ecx
	mov [rest], edx
	.if(edx != 0)
		inc eax		
	.endif
	mov [BigNumber ptr [ebx]].Len, eax
	; записали значение длины

	; теперь заполняем 0 все разряды
	mov ebx, [bignum_p] ; вначале получаем адрес структуры
	mov edi, [BigNumber ptr [ebx]].Len ;записываем значение длины
	mov ebx, [BigNumber ptr [ebx]].Num_p; теперь записываем в ebx адрес
	; самого числа
	mov [i], 0 ; первый элемент
	;mov [k], 4 ; множитель
	.while [i] < edi
		mov eax, [i]
		mov ecx, 4
		mul ecx
		mov ecx, 0
		mov  [ebx+eax], ecx
		inc [i]
	.endw
	; заполнили 0 разряды!

	; теперь заполняем слова
	mov [i], 0 ; первый элемент
	.while [StrLen] > 7
		mov [k], 0
		.while [k] < 8
			mov eax, [StrLen]
			sub eax, [k]
			dec eax
			mov edx, [Str_p]
			mov cl, byte ptr [edx+eax]
			mov byte ptr [temp], cl

			mov edx, 7
			sub edx, k
			mov cl, byte ptr [temp]
			mov byte ptr tstr[edx], cl ; ВОТ ТУТ МОЖЕТ БЫТЬ КОСЯК!!!!!!!!!!!
			
			inc [k]
		.endw
		
		sub [StrLen], 8
		mov ecx, [k]
		mov byte ptr tstr[ecx], byte ptr 0
		invoke crt_strtoul, addr tstr, NULL, 16
		; теперь в eax лежит число
		; запишем полученно число в соответствующий разряд BigNumber
		mov ebx, [bignum_p] ; вначале получаем адрес структуры
		mov ebx, [BigNumber ptr [ebx]].Num_p; перезаписываем содержимое ebx
		push eax
		mov eax, [i]
		mov ecx, 4
		mul ecx
		mov edi, eax
		pop eax
		mov [ebx+edi], eax
		; записали
		inc [i]
	.endw

	mov [k], 0
	mov edx, [rest]
	.while [k] < edx
		push edx

		mov eax, [Str_p]
		mov ecx, [k]
		mov dl, byte ptr [eax+ecx]
		mov byte ptr tstr[ecx], dl

		pop edx
		inc [k]
	.endw
	mov ecx, [k]
	mov byte ptr tstr[ecx], byte ptr 0

	invoke crt_strtoul, addr tstr, NULL, 16
	mov ebx, [bignum_p] ; вначале получаем адрес структуры
	mov ebx, [BigNumber ptr [ebx]].Num_p; перезаписываем содержимое ebx

	push eax
	mov eax, [i]
	mov edx, 4
	mul edx
	pop edx
	mov [ebx+eax], edx

	mov eax, 0
	ret
bignum_set_str endp

bignum_set_ui proc bignum_p: dword, number: dword
	
	invoke crt_malloc, 4
	mov ebx, [bignum_p]
	mov [BigNumber ptr [ebx]].Len, 1
	mov [BigNumber ptr [ebx]].Sig, 0
	mov [eax], [number]
	mov [BigNumber ptr [ebx]].Num_p, eax 
	
	mov eax, 0
	ret
bignum_set_ui endp

bignum_set_i proc bignum_p: dword, number: dword
	invoke crt_malloc, 4
	mov ebx, [bignum_p]
	mov ecx, [number]
	mov [BigNumber ptr [ebx]].Len, 1
	.if ecx < 0
		mov [BigNumber ptr [ebx]].Sig, 1
		xor ecx, 80000000h
		mov [eax], ecx
	.else
		mov [BigNumber ptr [ebx]].Sig, 0
		mov [eax], ecx		
	.endif
	mov [BigNumber ptr [ebx]].Num_p, eax
	
	xor eax, eax
	ret
bignum_set_i endp

; складывает 2 "положительных" числа
bignum_add_+_+ proc BN_res_p: dword, BN1_p: dword, BN2_p: dword
	local Bigger: dword; содержит указатель на большее ЧИСЛО (массив dword)
	local Smaller: dword; содержит указатель на меньшее ЧИСЛО (массив dword)
	local i: dword; счетчик
	local carry: dword; определяет, есть ли перенос
	local rest: dword; остаток

	mov eax, BN1_p
	mov ebx, BN2_p
	.if [BigNumber ptr [eax]].Len >= [BigNumber ptr [ebx]].Len
		mov [Bigger], eax
		mov [Smaller], ebx
		push [BigNumber ptr [eax]].Len
	.else
		mov [Bigger], ebx
		mov [Smaller], eax
		push [BigNumber ptr [ebx]].Len
	.endif

	pop ecx
	invoke crt_malloc, (ecx+1)*4
	mov ebx, [BN_res_p]
	mov [BigNumber [ebx]].Num_p, eax
	; вначале складываются оба числа
	mov [i], 0
	mov ebx, [Smaller]
	.while [i] < [BigNumber ptr [ebx]].Len
		push ebx

		mov ebx, [BN1_p]
		mov ebx, [BigNumber ptr [ebx]].Num_p
		mov ecx, [BN2_p]
		mov ecx, [BigNumber ptr [ecx]].Num_p
		.if [ebx + [i]*4] > INT_MAX
			.if [ecx + [i]*4] > INT_MAX
				mov edx, [ebx + [i]*4]
				sub edx, INT_MAX
				push edx
				mov edx, [ecx + [i]*4]
				sub edx, INT_MAX
				pop eax
				add edx, eax
				mov eax, [BN_res_p]
				mov eax, [BigNumber ptr [eax]].Num_p
				mov [eax + [i]*4], edx
				mov [carry], 1
			.else
				mov eax, [ebx + [i]*4]
				sub eax, INT_MAX
				add eax, [ecx + [i]*4]
				add eax, [carry]

				.if eax >= INT_MAX
					sub eax, INT_MAX
					sub eax, 2
					mov edx, eax
					mov eax, [BN_res_p]
					mov eax, [BigNumber ptr [eax]].Num_p
					mov [eax + [i]*4], edx
					mov [carry], 1
				.else
					add eax, INT_MAX
					mov edx, eax
					mov eax, [BN_res_p]
					mov eax, [BigNumber ptr [eax]].Num_p
					mov [eax + [i]*4], edx
					mov [carry], 0
				.endif
			.endif
		.else

			.if [ecx + [i]*4] > INT_MAX				
				mov eax, [ecx + [i]*4]
				sub eax, INT_MAX
				add eax, [ebx + [i]*4]
				add eax, [carry]
				.if eax >= INT_MAX
					sub eax, INT_MAX - 2
					mov edx, [bignum_res_p]
					mov edx, [BigNumber ptr [edx]].Num_p
					mov [edx + [i]*4]], eax
					mov [carry], 1
				.else
					add eax, INT_MAX
					mov edx, eax
					mov eax, [BN_res_p]
					mov eax, [BigNumber ptr [eax]].Num_p
					mov [eax + [i]*4], edx
					mov [carry], 0					
				.endif

			.else
				mov eax, [bignum_res_p]
				mov eax, [BigNumber ptr [eax]].Num_p
				mov edx, [ebx + [i]*4]
				add edx, [ecx + [i]*4]
				add edx, [carry]
				mov [eax + [i]*4], edx
				mov [carry], 0
			.endif

		.endif

		pop ebx
		inc [i]
	.endw
	mov ebx, [Bigger]
	mov ecx, [BigNumber ptr [ebx]].Num_p
	mov eax, [bignum_res_p]
	mov eax, [BigNumber ptr [eax]].Num_p
	.while	[i] < [BigNumber ptr [ebx]].Len
		push ebx
		
		.if [ecx+[i]*4] == FFFFFFFFh
			.if [carry] != 1
				mov edx, [ecx + [i]*4]
				add edx, [carry]
				mov [eax + [i]*4], edx
			.endif
		.else
			mov edx, [ecx + [i]*4]
			add edx, [carry]
			mov [eax + [i]*4], edx	
		.endif
		pop ebx
		inc [i]
	.endw
	mov eax, [BN_res_p]
	mov ebx, [BigNumber ptr [eax]].Num_p 
	.if [carry] == 1
		mov [ebx + [i]*4], 1
		mov [BigNumber ptr [eax]].Len, [i]+1
	.else
		mov [BigNumber ptr [eax]].Len, [i]
	.endif

bignum_add_+_+ endp

; вычитает из первого второе
bignum_sub_+_+ proc bignum_res_p: dword, num_1_p: dword, sub_2_p: dword

bignum_sub_+_+ endp


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
	
	invoke bignum_set_str, [BN_p], $CTA0("0xFFFFFFF0F")
	invoke bignum_print, [BN_p]
		
	invoke crt_system, $CTA0("pause")
	mov eax, 0
	ret
main endp

end main
