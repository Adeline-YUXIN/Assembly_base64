DATA SEGMENT
b64_chars db 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/', 0h
codefile        db    'code.txt' , 00                       ;待编码文件名，dosbox 设置的c盘下的路径
encodefile      db    'encode.txt' , 00                     ;编码存放文件名
buf1            db    14h dup(0)                            ;待转码内容缓冲区(20=14h)
buf2            db    1ch dup(0)                            ;已转码内容缓冲区（21/3*4=28=1ch)
error1_message  db    0ah , 'codefile error !' , '$'        ;文件1出错时的提示
error2_message  db    0ah , 'encodefile error !' , '$'      ;文件2出错时的提示
success_message db    0ah , 'success !' , '$'               ;完成后的提示
handle1         dw    ?                                     ;保存文件号
handle2         dw    ?                                     ;保存文件号
DATA ENDS

CODE SEGMENT
  main proc far
  assume ds:data,cs:code
start:
;惯例操作
    push ds       
    sub ax,ax     
    push ax       
    mov ax,data
    mov ds,ax                       ;获取数据段地址

file1:
;打开codefile文件
    mov dx , offset codefile		;dx获取codefile的偏移地址
    mov al , 0				        ;只读
    mov ah , 3dh		            ;**********************************************************************
	                                ;3dh号功能（文件的打开）学习： 
	                                ;入口参数：DS:DX=指定文件名字符串的地址，AL＝00H/01H——读取/设置文件属性
									;返回参数：CF＝0——创建成功，AX＝文件句柄，否则，AX＝错误号
									;**********************************************************************
    int 21h  
    jc error1                       ;若打开出错（cf=1），转error
	mov handle1 , ax                ;保存文件句柄

;读取codefile文件
    mov bx , handle1			    ;文件句柄放入bx作为参数
    mov cx , 14h				    ;至多读取20字节（注意返回的AX=实际读取文件的字节数）
    mov dx , offset buf1		    ;获取buf1的偏移地址
    mov ah , 3fh				    ;**********************************************************************
	                                ;3fh号功能（文件的读取）学习：
	                                ;入口参数：AH＝3fH，BX＝文件句柄，DS:DX＝数据缓冲区偏移量，AL＝00H/01H——读取/设置文件属性
								    ;返回参数：CF＝0——关闭成功，CX＝文件属性，AX=实际读取文件的字节数，否则，AX＝错误号
								    ;**********************************************************************
    int 21h            
    jc error1                       ;若读出错，转error
    push ax                         ;读取的字符数入栈

;关闭codefile文件
    mov bx , handle1			    ;文件句柄给bx 作为参数
    mov ah , 3eh					;**********************************************************************
	                                ;3eh号功能（文件的关闭）学习：
	                                ;入口参数：AH＝3EH，BX＝文件句柄
								    ;返回参数：CF＝0——关闭成功，否则，AX＝错误号
								    ;**********************************************************************
    int 21h                         ;关闭文件
	jc error1                       ;若关闭出错，转error

;base64编码前的准备工作：
;计数（学习了base64我们知道，每三个ASCII码才可以刚好编码成4个码，所以不足的我们需要补齐成3的倍数。）
calculate:
    pop ax                          ;读取的真实的字符数 出栈
    mov bl,3    
    div bl                          ;ax默认为被除数，除以bl（8位）中的3  余数在ah，商在al
    mov cx,0                        ;cx 先置 0
    mov cl,al                       ;商值意味着可以编码成多少组base64（每组4个码）
    test ah,ah                      ;测试ah是否为空,若是空（即temp=0）ZF置1
    jnz addl                        ;不为空 补一组
    jmp encode_b64
addl:
    inc cl                          ;不为空，不是3的倍数，补加一组
    jmp encode_b64

;操作文件1时出现错误
error1:
    mov dx,offset error1_message
    mov ah,9h
    int 21h
    mov ah,4ch
    int 21h

     ;！！！！！！base64 编码部分！！！！！！
     ; 1、将结果写入buf2
     ; 2、补等号，将有余数补齐后的编码填充为‘=’
encode_b64:
	sub bl,ah                       ;相减的结果即为‘=’的个数
    push bx                         ;保存需要补的等号数量
    mov si,0                        ;si置0，为寻址做准备
    mov di,0                        ;di置0，为寻址做准备
    mov ah,0                        ;提前把ah清空，后面要用ax代表al的值
;对每组（3个ascii码）进行编码
encode:
    push cx                         ;保存当前循环次数
    ;处理第一个字符 
    mov al,buf1[si]                 ;把 buf[si] 写入 al（即取待编码的第一个字节）
    mov cl,2     
    shr al,cl                       ;把al 逻辑右移 2 位，得第一个编码字符（相当于前两位补 0）
    call far ptr putchar  
    ;处理第二个字符 
    mov ah,buf1[si]                 ;把 buf[si]、buf[si+1] 分别放进 ah、al
    mov al,buf1[si+1]  
    and ah,3                        ;ah and 0000 0011 把前 6 个位 置0
    mov cl,4      
    shr ax,cl                       ;ax 逻辑右移 4 位，得到第二个编码字符于 al 中
    call far ptr putchar 
    ;处理第三个字符
    mov ah,buf1[si+1]               ;把buf[si+1]、buf[si+2]分别放进ah、al
    mov al,buf1[si+2]  
    and ah,0fh                      ;ah and 0000 1111 把前 4 位 置0
    mov cl,6h     
    shr ax,cl                       ;ax 逻辑右移 6 位，得到第三个编码字符于 al 中
    call far ptr putchar  
    ;处理第四个字符 
    mov al,buf1[si+2]               ;把 buf[si+2] 写入 al（即取第三个字节）
    and al,3fh                      ;al and 0011 1111，得到第四个 base64 字符
    call far ptr putchar  
    pop cx                          ;当前循环次数出栈
    add si,3                        ;si=si+3 指向下一将被编码的组的首个字节
    loop encode
    jmp equal

;补等号
equal:
    pop cx                          ;需要补的等号数量出栈，放进cx成为fill的循环次数
    push di                         ;此时di的值就是编码的长度
    cmp cx,3                        ;如果cx等于3（余数是0），说明不需要补等号
    jz file2
fill:
    mov buf2[di-1],'='              ;ax 此时就是编码后的长度
    dec di
    loop fill

file2:
;打开encodefile文件
    mov dx , offset encodefile		;dx获取encodefile的偏移地址
    mov al , 1h				        
    mov ah , 3dh		            									
    int 21h  
    jc error2                       ;若打开出错（cf=1），转error
	mov handle2 , ax                ;保存文件句柄

;写入encodefile文件
    pop cx                          ;buf2长度（即编码后的长度）出栈
    mov dx,offset buf2              ;获取buf1的偏移地址
    mov bx,handle2                  ;获取文件句柄，作为参数
    mov ah,40h				        ;**********************************************************************
	                                ;40h号功能（文件的写入）学习：
	                                ;入口参数：AH＝40H，BX＝文件句柄，DS:DX＝数据缓冲区偏移量
								    ;返回参数：CF＝0——成功，AX=实际写入文件的字节数，否则，AX＝错误号
								    ;**********************************************************************
    int 21h            
    jc error2                       ;若写出错，转error

;关闭encodefile文件
    mov bx , handle2			    ;文件句柄给bx 作为参数
    mov ah , 3eh						                                
    int 21h                       
	jc error2                       ;若关闭出错，转error
    jmp endl

;操作文件2时出现错误
error2:
    mov dx,offset error2_message
    mov ah,9h
    int 21h
    mov ah,4ch
    int 21h

  ;根据当前 al 中的值，将 base64 表中的对应编码字符写入 buf2 的对应位置
putchar:
    mov bx,ax                       ;ax的值是base64字符对应位置（由于间接寻址只能用bx不能用bl）
    mov al,b64_chars[bx]            ;把 base64 表的第 al 个字符写入 al
    mov buf2[di],al                 ;al 写入 buf2[si]，因为 mov 两个操作数不能都是内存单元，用 al 暂存
    inc di
    retf
 
   
;程序结束处
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