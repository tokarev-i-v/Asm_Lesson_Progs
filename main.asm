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
	mov eax, [number]
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
bignum_add_plus_plus proc BN_res_p: dword, BN1_p: dword, BN2_p: dword
	local Bigger: dword; содержит указатель на большее ЧИСЛО (массив dword)
	local Smaller: dword; содержит указатель на меньшее ЧИСЛО (массив dword)
	local i: dword; счетчик
	local carry: dword; определяет, есть ли перенос
	local rest: dword; остаток
	local temp: dword; переменная, должна перезаписываться в нужное значение перед каждым использованием

	mov [temp], 0
	mov [rest], 0
	mov [carry], 0

	mov eax, BN1_p
	mov ebx, BN2_p
	mov ecx, [BigNumber ptr [eax]].Len
	mov edx, [BigNumber ptr [ebx]].Len
	.if ecx >= edx
		mov [Bigger], eax
		mov [Smaller], ebx
		push [BigNumber ptr [eax]].Len
	.else
		mov [Bigger], ebx
		mov [Smaller], eax
		push [BigNumber ptr [ebx]].Len
	.endif
	

	pop [temp]
	inc [temp]
	push eax
	mov eax, 4
	mul [temp]
	mov [temp], eax
	pop eax

	invoke crt_malloc, [temp]
	mov ebx, [BN_res_p]

	mov [BigNumber ptr [ebx]].Num_p, eax

	mov ebx, [BigNumber ptr [ebx]].Num_p
	mov [i], 0
	mov cl, 0
	mov edi, [temp]
	;mov [k], 4 ; множитель
	.while [i] < edi
		mov eax, [i]
		mov  byte ptr [ebx+eax], byte ptr cl
		inc [i]
	.endw
	; заполнили 0 разряды!


	; вначале складываются оба числа
	mov [i], 0
	mov ebx, [Smaller]
	mov ecx, [BigNumber ptr [ebx]].Len
	.while [i] < ecx
		push ebx
		push ecx

		mov ebx, [BN1_p]
		mov ebx, [BigNumber ptr [ebx]].Num_p
		mov ecx, [BN2_p]
		mov ecx, [BigNumber ptr [ecx]].Num_p

		push eax
		mov eax, [i]
		mov [temp], 4
		mul [temp]
		mov [temp], eax
		pop eax
		
		mov esi, [temp]
		mov edi, [ebx+esi]
		 
		.if edi > INT_MAX
			mov esi, [temp]
			mov edi, [ecx+esi]

			.if edi > INT_MAX

				mov edx, [ebx + esi]
				sub edx, INT_MAX
				push edx

				mov edx, [ecx + esi]
				sub edx, INT_MAX
				pop eax
				add edx, eax

				add edx, [carry]
				sub edx, 2

				mov eax, [BN_res_p]
				mov eax, [BigNumber ptr [eax]].Num_p

				mov [eax + esi], edx
				mov [carry], 1
			.else
				mov eax, [ebx + esi]
				sub eax, INT_MAX
				add eax, [ecx + esi]
				add eax, [carry]

				.if eax >= INT_MAX
					sub eax, INT_MAX
					sub eax, 2
					mov edx, eax
					mov eax, [BN_res_p]
					mov eax, [BigNumber ptr [eax]].Num_p
					mov [eax + esi], edx
					mov [carry], 1
				.else
					add eax, INT_MAX
					mov edx, eax
					mov eax, [BN_res_p]
					mov eax, [BigNumber ptr [eax]].Num_p
					mov [eax + esi], edx
					mov [carry], 0
				.endif
			.endif
		.else

			mov esi, [temp]
			mov edi, [ecx+esi]

			.if edi > INT_MAX				
				mov eax, [ecx + esi]
				sub eax, INT_MAX
				add eax, [ebx + esi]
				add eax, [carry]
				.if eax >= INT_MAX
					sub eax, INT_MAX
					sub eax, 2
					mov edx, [BN_res_p]
					mov edx, [BigNumber ptr [edx]].Num_p
					mov [edx + esi], eax
					mov [carry], 1
				.else
					add eax, INT_MAX
					mov edx, eax
					mov eax, [BN_res_p]
					mov eax, [BigNumber ptr [eax]].Num_p
					mov [eax + esi], edx
					mov [carry], 0					
				.endif

			.else
				mov eax, [BN_res_p]
				mov eax, [BigNumber ptr [eax]].Num_p
				mov edx, [ebx + esi]
				add edx, [ecx + esi]
				add edx, [carry]
				mov [eax + esi], edx
				mov [carry], 0
			.endif

		.endif

		pop ecx
		pop ebx
		inc [i]
	.endw


	mov ebx, [Bigger]
	mov ecx, [BigNumber ptr [ebx]].Num_p
	mov eax, [BN_res_p]
	mov eax, [BigNumber ptr [eax]].Num_p

	push ecx
	mov ecx, [BigNumber ptr [ebx]].Len
	.while	[i] < ecx
		pop ecx

		push eax
		mov eax, [i]
		mov [temp], 4
		mul [temp]
		mov [temp], eax
		pop eax

		mov esi, [temp]
		mov edi, [ecx+esi]
		
		.if edi == UINT_MAX
			.if [carry] != 1
				mov edx, [ecx + esi]
				add edx, [carry]
				mov [eax + esi], edx
				mov [carry], 0
			.endif
		.else
			mov edx, [ecx + esi]
			add edx, [carry]
			mov [eax + esi], edx	
			mov [carry], 0
		.endif
		inc [i]

		push ecx
		mov ecx, [BigNumber ptr [ebx]].Len
	.endw
	mov eax, [BN_res_p]
	mov ebx, [BigNumber ptr [eax]].Num_p 

	push eax
	mov eax, [i]
	mov [temp], 4
	mul [temp]
	mov [temp], eax
	pop eax

	mov esi, [temp]
	mov edi, [ebx+esi]


	.if [carry] == 1
		mov [ebx + esi], dword ptr 1
		mov esi, [i]
		inc esi
		mov [BigNumber ptr [eax]].Len, esi
	.else
		mov esi, [i]
		mov [BigNumber ptr [eax]].Len, esi
	.endif
	
	xor eax, eax
	ret
bignum_add_plus_plus endp

; функция возвращает индекс первого НЕНУЛЕВОГО разряда, следующего за данным
; Такой должен существовать, если это не конец
find_first_not_null_index proc uses ebx ecx edx edi BN_p:dword, cur_index:dword
	local j:dword

	mov eax, [cur_index]
	mov [j], eax
	inc [j]

	mov eax, [BN_p]
	mov edi, [BigNumber ptr [eax]].Len
	mov ebx, [BigNumber ptr [eax]].Num_p
	.while [j] < edi
		mov ecx, [j]
		mov edx, [ebx+ebx*4]
		.if [j] != 0
			mov eax, [j]
			ret
		.endif
	.endw
	
	; если больше нет ненулевого разряда
	mov eax, 0
	ret
find_first_not_null_index endp

; устанавливает максимальные значения в разряды с i по j
; ОБЕ ГРАНИЦЫ ВКЛЮЧИТЕЛЬНО
; функция сохраняет состояния регистров!
set_max_num_to_nulls_from_i_to_j proc uses eax ebx ecx edx edi BN_p:dword, i_ind:dword, j_ind:dword
	local i:dword
	local j:dword
	
	mov eax, [i_ind]
	mov [i], eax
	mov eax, [j_ind]
	mov ebx, [BN_p]
	mov ebx, [BigNumber ptr [ebx]].Num_p
	.while [i] <= eax
		mov ecx, [i]
		mov edx, UINT_MAX
		mov [ebx+ecx*4], edx
	.endw 

	ret
set_max_num_to_nulls_from_i_to_j endp
; BN1 - BN2
; BN1 >= BN2!!!
bignum_sub_plus_plus proc BN_res_p: dword, BN1_p: dword, BN2_p: dword
	local loan: dword
	local tlen: dword 
	local temp: dword
	local i: dword
	; это копия числа BN_2_p.Num_p, в которой мы будем делать изменения и из которой будем вычитать все.
	; Затем этот указатель будет положен в BN_res_p.Num_p
	local temp_BN1_N_p: dword

	mov [loan], 0
	mov [tlen], 0
	mov [temp], 0

	mov eax, [BN_res_p]
	invoke crt_free, [BigNumber ptr [eax]].Num_p


	; выделяем память
	mov eax, [BN1_p]
	mov eax, [BigNumber ptr [eax]].Len
	mov ecx, 4
	mul ecx

	invoke crt_malloc, eax
	mov ebx, [BN_res_p]
	mov [BigNumber ptr [ebx]].Num_p, eax
	; копируем число
	mov ebx, eax
	mov eax, [BN1_p]
	mov edi, [BigNumber ptr [eax]].Len
	mov eax, [BigNumber ptr [eax]].Num_p

	.while [i] < edi
		mov ecx, [i]
		mov edx, [eax+ecx*4]
		mov [ebx+ecx*4], edx
		inc [i]		
	.endw
	; скопировали число

	mov eax, [BN2_p]
	mov edi, [BigNumber ptr [BN2_p]].Len
	mov eax, [BigNumber ptr [eax]].Num_p
	mov ebx, [BN_res_p]
	mov ebx, [BigNumber ptr [ebx]].Num_p
	mov [i], 0
	; вычитание разрядов
	; пока не кончится меньшее число
	; в EAX хранится указатель на МЕНЬШЕЕ число
	; в EBX хранится указатель на БОЛЬШЕЕ число
	.while [i] < edi

		mov ecx, [i]
		mov edx, [eax+ecx*4]
		; сравниваем числа
		.if [ebx+ecx*4] >= edx
			sub [ebx+ecx*4], edx
		.else
		; вот тут шляпа	
			invoke find_first_not_null_index, [BN_res_p], [i]
			; сначала ищем ненулевой разряд для заема
			mov [temp], eax
			; если ненулевой разряд нашелся
			.if [temp] != 0
			; записываем 
				inc [i]
				dec [temp]
				invoke set_max_num_to_nulls_from_i_to_j, [BN_res_p], [i], [temp]
				dec [i]
				inc [temp]
				; теперь занимаем из меньшего (но >i) ненулевого разряда
				mov esi, [temp]
				sub [ebx+esi*4], dword ptr 1
				; теперь делаем шоколадно
				mov esi, UINT_MAX
				sub esi, [eax+ecx*4]
				add [ebx+ecx*4], esi
			.endif

		.endif
	.endw
	;ТЕПЕРЬ СДЕЛАТЬ ПРОВЕРКУ НА 0 СТАРШИЕ РАЗРЯДЫ И СТЕРЕТЬ ИХ, ПЕРЕЗАПИСАВ ЧИСЛО В НОВОЕ!;


	xor eax, eax
	ret
bignum_sub_plus_plus endp


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
	local BN1_p: dword
	local BN2_p: dword
	local BN3_p: dword
	
	invoke crt_malloc, sizeof(BigNumber)
	mov [BN1_p], eax
	invoke bignum_init_null, [BN1_p], 50
	
	invoke crt_malloc, sizeof(BigNumber)
	mov [BN2_p], eax
	invoke bignum_init_null, [BN2_p], 50

	invoke crt_malloc, sizeof(BigNumber)
	mov [BN3_p], eax
	invoke bignum_init_null, [BN3_p], 50

	
	invoke crt_malloc, 12
	mov [Str_1], eax
	invoke crt_strcpy, [Str_1], $CTA0("HELLO_WORLD")

	invoke crt_strlen, [Str_1]
	mov [StrLen], eax
	invoke crt_printf, $CTA0("%i\n"), [StrLen]
	

	invoke bignum_set_str, [BN1_p], $CTA0("0xFFFFFFFF")
	invoke bignum_set_str, [BN2_p], $CTA0("0x1FFFFFFFFFFFFFF")
	invoke bignum_set_str, [BN3_p], $CTA0("0X0")

	invoke bignum_add_plus_plus, [BN3_p], [BN1_p], [BN2_p]

	invoke bignum_print, [BN1_p]
	invoke bignum_print, [BN2_p]
	invoke bignum_print, [BN3_p]
		
	invoke crt_system, $CTA0("pause")
	mov eax, 0
	ret
main endp

end main
