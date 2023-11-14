DATA SEGMENT
b64_chars db 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/', 0h
codefile        db    'c:\code.txt' , 0       ;�������ļ�����dosbox ���õ�c���µ�·��
encodefile      db    'c:\encode.txt' , 0       ;�������ļ���
buf1             db   256 dup(0)        ;�����ļ������ݴ���
buf2             db   256 dup(0)        ;��д�ļ������ݴ���
readlen          db ��                   ;�������ַ�����
success_message db   0ah,' successed !','$';�ɹ������ʾ
error_message   db   0ah , 'error !' , '$'    ;����ʱ����ʾ
handle          dw  ?                ;�����ļ���
mem_start       dd 0h
DATA ENDS

CODE SEGMENT
  main proc far
  assume cs:code,ds:data
start:
              mov ax , data				
              mov ds , ax				;��ȡ�ε�ַ	
              mov dx , offset codefile		;dx��ȡcodefile��ƫ�Ƶ�ַ
              mov al , 0				
              mov ah , 3dh				
              int 21h                  ;���ļ���ֻ��
              jc error                  ;���򿪳���תerror
			  mov handle , ax           ;�����ļ����
              mov bx , ax				;�ļ����
              mov cx , 20				;��ȡ20�ֽ�
              mov dx , offset buf1		;��ȡbuf��ƫ�Ƶ�ַ
              mov ah , 3fh				
              int 21h                  ;���ļ��ж�255�ֽڡ�buf
              jc error                  ;��������תerror
			  mov dx,offset readlen
              mov [dx] , ax              ;ʵ�ʶ������ַ�������readlen
              ;mov dx , offset buf
              ;mov ah , 9
              ;int 21h                            ;��ʾ�ļ�����
              mov bx , handle					;�ļ����
              mov ah , 3eh						
              int 21h                            ;�ر��ļ�
			  mov ebp , offset buf1		;buf��ƫ�Ƶ�ַ(��һ���ַ��ĵ�ַ������ebp
			  mov esp, [dx]             ;ʵ�ʶ������ַ�������readlen
              jnc encode_b64             ;���رչ����޴�ת��end1������dos
			  mov buf2,eax
			  mov dx , offset codefile
              mov cx , 20
              mov ah , 3ch
              int 21h               ;�����ļ�����������ԭ�д��ļ����򸲸�
              jc error               ;��������תerror��
              mov handle , ax         ;�����ļ���
              
              mov cx , word[ebx] 
              mov dx , offset buf2
              mov ah , 40h
              int 21h                          ;���ļ���д��20���ֽ�����
              jc error                          ;д����תerror��
              mov bx , handle
              mov ah , 3eh
              int 21h                          ;�ر��ļ�
              jc error                           ;�ر��ļ�����תerror��
              mov dx , offset success_message
              mov ah , 9
              int 21h                            ;�����ɹ�����ʾ��ʾ
              jmp end1

error:
              mov dx , offset error_message		;��ȡerror_message��ƫ�Ƶ�ַ
              mov ah , 9						
              int 21h                            ;��ʾerror_message
end1:
             mov ah , 4ch						;��������Ľ���
             int 21h


; base64 ���벿�֣�
  ; ����Ĵ���eax��
  ; ����ĳ���Ϊebx
  ; ������������
  ; �ַ����ĵ�һ����ַ�������ջ����������
  ; �������ַ����ĳ��������ջ������һ��

encode_b64:
	push ebp
	mov ebp, esp
	sub esp, 8		; Ϊ�������ر�������ռ�
	mov eax, [ebp + 8]	; �ַ����ĳ����Ƶ�eax
	xor edx, edx
	mov ecx, 3
	div ecx			; ��鳤���Ƿ�Ϊ3�ı���
	mov ebx, 3
	sub ebx, edx		; ���Ҫ��Ӷ��ٸ��ֽ�����䣬ʹ���Ϊ3�ı���
	cmp ebx, 3
	jne there		; �������Ϊ3���������
	xor ebx, ebx
there:
	mov [ebp - 4], ebx		; ��䳤��
	mov eax, [ebp + 8]
	add eax, [ebp - 4]		; ԭʼ����+���
	xor edx, edx
	div ecx				; ����3�ٳ���4
	inc ecx				; �������Ǳ�����ַ����ĳ���
	mul ecx
	cmp edx, 0
	jne error
	add eax, 1			; ����ת���ֽ�
	mov [ebp - 8], eax		; result buffer length
	push eax
	call allocate_mem		; ����mem ����ĵ�ַ������ mem_start��
	pop ecx
	mov esi, [ebp + 12]		; ��������ַ���
	mov edi, [mem_start]		; result buffer

encode_loop:
	cmp dword [ebp + 8], 0		; ���ԭʼ�ַ����Ƿ��Ѿ�����
	je pad_result			; ����ѽ���������������
	xor eax, eax
	mov ah, byte [esi]		; mov first to ah
	inc esi
	shl eax, 8			; ����һ���ֽ������ƶ�8λ
	mov ah, byte [esi]		; ���ڶ����������ֽڷֱ��ƶ���ah��al������eax��Ԥ��˳����������ֽ�
	mov al, byte [esi + 1]		
	add esi, 2
	mov ebx, eax			; eax is copied to 3 registers as there will be 4 resulting bytes
	mov ecx, eax
	mov edx, eax
	shr eax, 18			; gives the first 6 bitss
	shr ebx, 12			; �ڶ���6λ����ڼĴ�����ĩβ���Դ�����
	shr ecx, 6
	and eax, 63			; and with 63 so last 6 bits will only get and'ed 
	and ebx, 63
	and ecx, 63
	and edx, 63			; ������eax��ebx��ecx��edx�д����ĸ����ݣ��ֱ���Ϊb64_chars��ƫ����
	add eax, b64_chars		; �õ���һ������ĵ�ַ
	mov al , byte [eax]
	mov byte [edi], al
	inc edi
	mov eax, ebx
	add ebx, b64_chars		; �õ��ڶ�������ĵ�ַ
	mov bl, byte [ebx]
	mov byte [edi], bl
	inc edi
	cmp dword [ebp + 8], 1		; �Ƚ�ԭʼ�ַ�����ʣ�೤�ȣ������1���ʾ�������ݶ��Ѿ�����
	je pad_result
	add ecx, b64_chars		; �õ�����������ĵ�ַ
	mov cl, byte [ecx]
	mov byte [edi], cl
	inc edi
	cmp dword [ebp + 8], 2		; �Ƚ�ԭʼ�ַ�����ʣ�೤�ȣ������2���ʾ�������ݶ��Ѿ�����
	je pad_result
	add edx, b64_chars		; �õ�����������ĵ�ַ
	mov dl, byte [edx]
	mov byte [edi], dl
	inc edi
	sub dword [ebp + 8], 3		; ��ԭ�ַ����ȼ�ȥ3
	jmp encode_loop			; loop

pad_result:
	cmp dword [ebp - 4], 0
	je encoded
	mov byte [edi], '='		; ��� '='
	inc edi
	dec dword [ebp - 4]
	jmp pad_result

encoded:
	mov byte [edi], 0Ah
	mov eax, dword [mem_start]	; ��������ַ�� eax
	mov ebx ,dword [ebp - 8]	; ���볤��
	leave
	ret

; base 64 encoding function ends here

allocate_mem:			
	xor ebx, ebx
	mov eax, 45 		; sys_brk ���жϣ�syscall���ţ���������
	int 80h		; ��һ���жϵõ��ϵ�ĵ�ַ
	mov [mem_start], eax
	mov ebx, [mem_start]
	add ebx, [esp + 4]
	mov eax, 45
	int 80h		; �ڵ�һ���жϺ����������ڴ�
	ret

 ;����syscall�����жϵ�ѧϰ��
     ;x86_64 ͨ���жϣ�syscall��ָ����ʵ��
    ;�Ĵ��� rax �д��ϵͳ���úţ�ͬʱϵͳ���÷���ֵҲ����� rax ��
    ;��ϵͳ���ò���С�ڵ���6��ʱ����������밴˳��ŵ��Ĵ��� rdi��rsi��rdx��r10��r8��r9��
    ;��ϵͳ���ò�������6��ʱ��ȫ������Ӧ�����η���һ���������ڴ������ͬʱ�ڼĴ��� ebx �б���ָ����ڴ������ָ��
    ;�����к�������ʱ����������7���� ���������ҷ���Ĵ���: rdi, rsi, rdx, rcx, r8, r9������Ϊ7������ʱ��ǰ 6 ����ǰ��һ���� ����������δ� "������" ����ջ�С�

;����int 80h��ѧϰ��
    ;i386ͨ���жϣ�int 0x80����ʵ��ϵͳ����
    ;�Ĵ��� eax �д��ϵͳ���úţ�ͬʱ����ֵҲ����� eax ��
    ;��ϵͳ���ò���С�ڵ���6��ʱ����������밴˳��ŵ��Ĵ��� ebx��ecx��edx��esi��edi ��ebp��
    ;��ϵͳ���ò�������6��ʱ��ȫ������Ӧ�����η���һ���������ڴ������ͬʱ�ڼĴ��� ebx �б���ָ����ڴ������ָ��
ret
    main endp
code ends
    end start