DATA SEGMENT
b64_chars db 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/', 0h
codefile        db    'code.txt' , 00                       ;�������ļ�����dosbox ���õ�c���µ�·��
encodefile      db    'encode.txt' , 00                     ;�������ļ���
buf1            db    14h dup(0)                            ;��ת�����ݻ�����(20=14h)
buf2            db    1ch dup(0)                            ;��ת�����ݻ�������21/3*4=28=1ch)
error1_message  db    0ah , 'codefile error !' , '$'        ;�ļ�1����ʱ����ʾ
error2_message  db    0ah , 'encodefile error !' , '$'      ;�ļ�2����ʱ����ʾ
success_message db    0ah , 'success !' , '$'               ;��ɺ����ʾ
handle1         dw    ?                                     ;�����ļ���
handle2         dw    ?                                     ;�����ļ���
DATA ENDS

CODE SEGMENT
  main proc far
  assume ds:data,cs:code
start:
;��������
    push ds       
    sub ax,ax     
    push ax       
    mov ax,data
    mov ds,ax                       ;��ȡ���ݶε�ַ

file1:
;��codefile�ļ�
    mov dx , offset codefile		;dx��ȡcodefile��ƫ�Ƶ�ַ
    mov al , 0				        ;ֻ��
    mov ah , 3dh		            ;**********************************************************************
	                                ;3dh�Ź��ܣ��ļ��Ĵ򿪣�ѧϰ�� 
	                                ;��ڲ�����DS:DX=ָ���ļ����ַ����ĵ�ַ��AL��00H/01H������ȡ/�����ļ�����
									;���ز�����CF��0���������ɹ���AX���ļ����������AX�������
									;**********************************************************************
    int 21h  
    jc error1                       ;���򿪳���cf=1����תerror
	mov handle1 , ax                ;�����ļ����

;��ȡcodefile�ļ�
    mov bx , handle1			    ;�ļ��������bx��Ϊ����
    mov cx , 14h				    ;�����ȡ20�ֽڣ�ע�ⷵ�ص�AX=ʵ�ʶ�ȡ�ļ����ֽ�����
    mov dx , offset buf1		    ;��ȡbuf1��ƫ�Ƶ�ַ
    mov ah , 3fh				    ;**********************************************************************
	                                ;3fh�Ź��ܣ��ļ��Ķ�ȡ��ѧϰ��
	                                ;��ڲ�����AH��3fH��BX���ļ������DS:DX�����ݻ�����ƫ������AL��00H/01H������ȡ/�����ļ�����
								    ;���ز�����CF��0�����رճɹ���CX���ļ����ԣ�AX=ʵ�ʶ�ȡ�ļ����ֽ���������AX�������
								    ;**********************************************************************
    int 21h            
    jc error1                       ;��������תerror
    push ax                         ;��ȡ���ַ�����ջ

;�ر�codefile�ļ�
    mov bx , handle1			    ;�ļ������bx ��Ϊ����
    mov ah , 3eh					;**********************************************************************
	                                ;3eh�Ź��ܣ��ļ��Ĺرգ�ѧϰ��
	                                ;��ڲ�����AH��3EH��BX���ļ����
								    ;���ز�����CF��0�����رճɹ�������AX�������
								    ;**********************************************************************
    int 21h                         ;�ر��ļ�
	jc error1                       ;���رճ���תerror

;base64����ǰ��׼��������
;������ѧϰ��base64����֪����ÿ����ASCII��ſ��Ըպñ����4���룬���Բ����������Ҫ�����3�ı�������
calculate:
    pop ax                          ;��ȡ����ʵ���ַ��� ��ջ
    mov bl,3    
    div bl                          ;axĬ��Ϊ������������bl��8λ���е�3  ������ah������al
    mov cx,0                        ;cx ���� 0
    mov cl,al                       ;��ֵ��ζ�ſ��Ա���ɶ�����base64��ÿ��4���룩
    test ah,ah                      ;����ah�Ƿ�Ϊ��,���ǿգ���temp=0��ZF��1
    jnz addl                        ;��Ϊ�� ��һ��
    jmp encode_b64
addl:
    inc cl                          ;��Ϊ�գ�����3�ı���������һ��
    jmp encode_b64

;�����ļ�1ʱ���ִ���
error1:
    mov dx,offset error1_message
    mov ah,9h
    int 21h
    mov ah,4ch
    int 21h

     ;������������base64 ���벿�֣�����������
     ; 1�������д��buf2
     ; 2�����Ⱥţ��������������ı������Ϊ��=��
encode_b64:
	sub bl,ah                       ;����Ľ����Ϊ��=���ĸ���
    push bx                         ;������Ҫ���ĵȺ�����
    mov si,0                        ;si��0��ΪѰַ��׼��
    mov di,0                        ;di��0��ΪѰַ��׼��
    mov ah,0                        ;��ǰ��ah��գ�����Ҫ��ax����al��ֵ
;��ÿ�飨3��ascii�룩���б���
encode:
    push cx                         ;���浱ǰѭ������
    ;�����һ���ַ� 
    mov al,buf1[si]                 ;�� buf[si] д�� al����ȡ������ĵ�һ���ֽڣ�
    mov cl,2     
    shr al,cl                       ;��al �߼����� 2 λ���õ�һ�������ַ����൱��ǰ��λ�� 0��
    call far ptr putchar  
    ;����ڶ����ַ� 
    mov ah,buf1[si]                 ;�� buf[si]��buf[si+1] �ֱ�Ž� ah��al
    mov al,buf1[si+1]  
    and ah,3                        ;ah and 0000 0011 ��ǰ 6 ��λ ��0
    mov cl,4      
    shr ax,cl                       ;ax �߼����� 4 λ���õ��ڶ��������ַ��� al ��
    call far ptr putchar 
    ;����������ַ�
    mov ah,buf1[si+1]               ;��buf[si+1]��buf[si+2]�ֱ�Ž�ah��al
    mov al,buf1[si+2]  
    and ah,0fh                      ;ah and 0000 1111 ��ǰ 4 λ ��0
    mov cl,6h     
    shr ax,cl                       ;ax �߼����� 6 λ���õ������������ַ��� al ��
    call far ptr putchar  
    ;������ĸ��ַ� 
    mov al,buf1[si+2]               ;�� buf[si+2] д�� al����ȡ�������ֽڣ�
    and al,3fh                      ;al and 0011 1111���õ����ĸ� base64 �ַ�
    call far ptr putchar  
    pop cx                          ;��ǰѭ��������ջ
    add si,3                        ;si=si+3 ָ����һ�������������׸��ֽ�
    loop encode
    jmp equal

;���Ⱥ�
equal:
    pop cx                          ;��Ҫ���ĵȺ�������ջ���Ž�cx��Ϊfill��ѭ������
    push di                         ;��ʱdi��ֵ���Ǳ���ĳ���
    cmp cx,3                        ;���cx����3��������0����˵������Ҫ���Ⱥ�
    jz file2
fill:
    mov buf2[di-1],'='              ;ax ��ʱ���Ǳ����ĳ���
    dec di
    loop fill

file2:
;��encodefile�ļ�
    mov dx , offset encodefile		;dx��ȡencodefile��ƫ�Ƶ�ַ
    mov al , 1h				        
    mov ah , 3dh		            									
    int 21h  
    jc error2                       ;���򿪳���cf=1����תerror
	mov handle2 , ax                ;�����ļ����

;д��encodefile�ļ�
    pop cx                          ;buf2���ȣ��������ĳ��ȣ���ջ
    mov dx,offset buf2              ;��ȡbuf1��ƫ�Ƶ�ַ
    mov bx,handle2                  ;��ȡ�ļ��������Ϊ����
    mov ah,40h				        ;**********************************************************************
	                                ;40h�Ź��ܣ��ļ���д�룩ѧϰ��
	                                ;��ڲ�����AH��40H��BX���ļ������DS:DX�����ݻ�����ƫ����
								    ;���ز�����CF��0�����ɹ���AX=ʵ��д���ļ����ֽ���������AX�������
								    ;**********************************************************************
    int 21h            
    jc error2                       ;��д����תerror

;�ر�encodefile�ļ�
    mov bx , handle2			    ;�ļ������bx ��Ϊ����
    mov ah , 3eh						                                
    int 21h                       
	jc error2                       ;���رճ���תerror
    jmp endl

;�����ļ�2ʱ���ִ���
error2:
    mov dx,offset error2_message
    mov ah,9h
    int 21h
    mov ah,4ch
    int 21h

  ;���ݵ�ǰ al �е�ֵ���� base64 ���еĶ�Ӧ�����ַ�д�� buf2 �Ķ�Ӧλ��
putchar:
    mov bx,ax                       ;ax��ֵ��base64�ַ���Ӧλ�ã����ڼ��Ѱַֻ����bx������bl��
    mov al,b64_chars[bx]            ;�� base64 ��ĵ� al ���ַ�д�� al
    mov buf2[di],al                 ;al д�� buf2[si]����Ϊ mov �������������ܶ����ڴ浥Ԫ���� al �ݴ�
    inc di
    retf
 
   
;���������
endl:
    mov dx,offset success_message
    mov ah,9h
    int 21h
    mov ah,4ch
    int 21h
 ret 
   main endp      
code ends
   end start