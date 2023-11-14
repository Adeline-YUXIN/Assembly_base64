DATA SEGMENT
b64_chars db 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/', 0h
codefile        db    'c:\code.txt' , 0       ;待编码文件名，dosbox 设置的c盘下的路径
encodefile      db    'c:\encode.txt' , 0       ;编码存放文件名
buf1             db   256 dup(0)        ;待读文件内容暂存区
buf2             db   256 dup(0)        ;待写文件内容暂存区
readlen          db ？                   ;读到的字符长度
success_message db   0ah,' successed !','$';成功后的提示
error_message   db   0ah , 'error !' , '$'    ;出错时的提示
handle          dw  ?                ;保存文件号
mem_start       dd 0h
DATA ENDS

CODE SEGMENT
  main proc far
  assume cs:code,ds:data
start:
              mov ax , data				
              mov ds , ax				;获取段地址	
              mov dx , offset codefile		;dx获取codefile的偏移地址
              mov al , 0				
              mov ah , 3dh				
              int 21h                  ;打开文件，只读
              jc error                  ;若打开出错，转error
			  mov handle , ax           ;保存文件句柄
              mov bx , ax				;文件句柄
              mov cx , 20				;读取20字节
              mov dx , offset buf1		;获取buf的偏移地址
              mov ah , 3fh				
              int 21h                  ;从文件中读255字节→buf
              jc error                  ;若读出错，转error
			  mov dx,offset readlen
              mov [dx] , ax              ;实际读到的字符数送入readlen
              ;mov dx , offset buf
              ;mov ah , 9
              ;int 21h                            ;显示文件内容
              mov bx , handle					;文件句柄
              mov ah , 3eh						
              int 21h                            ;关闭文件
			  mov ebp , offset buf1		;buf的偏移地址(第一个字符的地址）放入ebp
			  mov esp, [dx]             ;实际读到的字符数送入readlen
              jnc encode_b64             ;若关闭过程无错，转到end1处返回dos
			  mov buf2,eax
			  mov dx , offset codefile
              mov cx , 20
              mov ah , 3ch
              int 21h               ;创建文件，若磁盘上原有此文件，则覆盖
              jc error               ;创建出错，转error处
              mov handle , ax         ;保存文件号
              
              mov cx , word[ebx] 
              mov dx , offset buf2
              mov ah , 40h
              int 21h                          ;向文件中写入20个字节内容
              jc error                          ;写出错，转error处
              mov bx , handle
              mov ah , 3eh
              int 21h                          ;关闭文件
              jc error                           ;关闭文件出错，转error处
              mov dx , offset success_message
              mov ah , 9
              int 21h                            ;操作成功后显示提示
              jmp end1

error:
              mov dx , offset error_message		;获取error_message的偏移地址
              mov ah , 9						
              int 21h                            ;显示error_message
end1:
             mov ah , 4ch						;待返回码的结束
             int 21h


; base64 编码部分：
  ; 结果寄存在eax中
  ; 结果的长度为ebx
  ; 接收两个参数
  ; 字符串的第一个地址被推入堆栈（参数二）
  ; 紧接着字符串的长度推入堆栈（参数一）

encode_b64:
	push ebp
	mov ebp, esp
	sub esp, 8		; 为两个本地变量分配空间
	mov eax, [ebp + 8]	; 字符串的长度移到eax
	xor edx, edx
	mov ecx, 3
	div ecx			; 检查长度是否为3的倍数
	mov ebx, 3
	sub ebx, edx		; 检查要添加多少个字节来填充，使其成为3的倍数
	cmp ebx, 3
	jne there		; 如果长度为3则无需添加
	xor ebx, ebx
there:
	mov [ebp - 4], ebx		; 填充长度
	mov eax, [ebp + 8]
	add eax, [ebp - 4]		; 原始长度+填充
	xor edx, edx
	div ecx				; 除以3再乘以4
	inc ecx				; 这是我们编码后字符串的长度
	mul ecx
	cmp edx, 0
	jne error
	add eax, 1			; 用于转换字节
	mov [ebp - 8], eax		; result buffer length
	push eax
	call allocate_mem		; 将给mem 分配的地址保存在 mem_start里
	pop ecx
	mov esi, [ebp + 12]		; 待编码的字符串
	mov edi, [mem_start]		; result buffer

encode_loop:
	cmp dword [ebp + 8], 0		; 检查原始字符串是否已经结束
	je pad_result			; 如果已结束，则填充编码结果
	xor eax, eax
	mov ah, byte [esi]		; mov first to ah
	inc esi
	shl eax, 8			; 将第一个字节向左移动8位
	mov ah, byte [esi]		; 将第二个第三个字节分别移动到ah和al，现在eax按预定顺序包含三个字节
	mov al, byte [esi + 1]		
	add esi, 2
	mov ebx, eax			; eax is copied to 3 registers as there will be 4 resulting bytes
	mov ecx, eax
	mov edx, eax
	shr eax, 18			; gives the first 6 bitss
	shr ebx, 12			; 第二个6位组合在寄存器的末尾，以此类推
	shr ecx, 6
	and eax, 63			; and with 63 so last 6 bits will only get and'ed 
	and ebx, 63
	and ecx, 63
	and edx, 63			; 我们在eax、ebx、ecx、edx中存了四个数据，分别作为b64_chars的偏移量
	add eax, b64_chars		; 得到第一个编码的地址
	mov al , byte [eax]
	mov byte [edi], al
	inc edi
	mov eax, ebx
	add ebx, b64_chars		; 得到第二个编码的地址
	mov bl, byte [ebx]
	mov byte [edi], bl
	inc edi
	cmp dword [ebp + 8], 1		; 比较原始字符串的剩余长度，如果是1则表示所有内容都已经编码
	je pad_result
	add ecx, b64_chars		; 得到第三个编码的地址
	mov cl, byte [ecx]
	mov byte [edi], cl
	inc edi
	cmp dword [ebp + 8], 2		; 比较原始字符串的剩余长度，如果是2则表示所有内容都已经编码
	je pad_result
	add edx, b64_chars		; 得到第三个编码的地址
	mov dl, byte [edx]
	mov byte [edi], dl
	inc edi
	sub dword [ebp + 8], 3		; 将原字符长度减去3
	jmp encode_loop			; loop

pad_result:
	cmp dword [ebp - 4], 0
	je encoded
	mov byte [edi], '='		; 填充 '='
	inc edi
	dec dword [ebp - 4]
	jmp pad_result

encoded:
	mov byte [edi], 0Ah
	mov eax, dword [mem_start]	; 编码结果地址在 eax
	mov ebx ,dword [ebp - 8]	; 编码长度
	leave
	ret

; base 64 encoding function ends here

allocate_mem:			
	xor ebx, ebx
	mov eax, 45 		; sys_brk 的中断（syscall）号（？？？）
	int 80h		; 第一次中断得到断点的地址
	mov [mem_start], eax
	mov ebx, [mem_start]
	add ebx, [esp + 4]
	mov eax, 45
	int 80h		; 在第一次中断后分配所需的内存
	ret

 ;关于syscall——中断的学习：
     ;x86_64 通过中断（syscall）指令来实现
    ;寄存器 rax 中存放系统调用号，同时系统调用返回值也存放在 rax 中
    ;当系统调用参数小于等于6个时，参数则必须按顺序放到寄存器 rdi，rsi，rdx，r10，r8，r9中
    ;当系统调用参数大于6个时，全部参数应该依次放在一块连续的内存区域里，同时在寄存器 ebx 中保存指向该内存区域的指针
    ;当进行函数调用时，参数少于7个， 参数从左到右放入寄存器: rdi, rsi, rdx, rcx, r8, r9。参数为7个以上时，前 6 个与前面一样， 但后面的依次从 "右向左" 放入栈中。

;关于int 80h的学习：
    ;i386通过中断（int 0x80）来实现系统调用
    ;寄存器 eax 中存放系统调用号，同时返回值也存放在 eax 中
    ;当系统调用参数小于等于6个时，参数则必须按顺序放到寄存器 ebx，ecx，edx，esi，edi ，ebp中
    ;当系统调用参数大于6个时，全部参数应该依次放在一块连续的内存区域里，同时在寄存器 ebx 中保存指向该内存区域的指针
ret
    main endp
code ends
    end start