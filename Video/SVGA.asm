;http://en.wikipedia.org/wiki/Graphics_processing_unit
;http://en.wikipedia.org/wiki/GPGPU
;http://en.wikipedia.org/wiki/Graphics_card
;http://en.wikipedia.org/wiki/Nvidia_PureVideo
;http://bos.asmhackers.net/docs/
;http://www.inversereality.org/files/vesavideomodes.pdf
;http://www.shawnhargreaves.com/freebe/index.html
;http://www.x.org/docs/intel/
;http://support.amd.com/us/ChipsetMotherboard_TechDocs/44415.pdf
;AMD:
;http://www.x.org/wiki/radeonhd/
;http://www.x.org/wiki/RadeonFeature
;http://www.x.org/wiki/radeon
;http://www.x.org/docs/AMD/
;http://developer.nvidia.com/3d-vision-and-surround-technology
%macro def_str 0
	%strlen __strsize pstring
	db __strsize ;n�mero de chars
	db pstring   ;string
%endmacro

[bits 16]
[org 7c00h]

cli
jmp 0:SOF

call_VESA:
	int 10h
	test ah,ah;sucesso na fun��o?
	jz .return;sim, retorna
	cmp al,4Fh
	push .print_exception
	je .no_hardware_support
	cmp ah,01h
	je .call_failed
	cmp ah,02h
	je .wrong_GPU_or_monitor
	cmp ah,03h
	je .SVGA_failure
	.no_hardware_support:
		mov si,msgs.no_hardware_support
		.return: ret
	.call_failed:
		mov si,msgs.SVGA_function_call_failed
		ret
	.wrong_GPU_or_monitor:
		mov si,msgs.GPU_monitor_failure
		ret
	.SVGA_failure:
		mov si,msgs.SVGA_error
	.print_exception:
	;mostra com int's da BIOS
	;mov ah,0Eh
	;mov cx,25
    ;loop_print:
        ;mov al,[bp]
		;int 10h
		;inc bp
        ;loop loop_print
	;recebe tecla:
	;xor ah,ah
	;int 16h
	;reinicia:
	;int 19h
		xor ch,ch
		mov cl,[si];n�mero de chars
		inc si;pular n�mero de chars

		push dword 0B800h
		pop es

		mov ah,0000_1111b;preto e branco
		cld
		_loop:
			lodsb;al=[ds:si], DF ? si-- : si++
			stosw;[es:di]=ax, di = DF ? DI - 2 : DI + 2
			loop _loop
		xor ah,ah
		int 16h
		int 19h

SOF:
push cs
pop es
mov di,vesa_signature_buffer
mov ax,4Fh << 4 | 00h
int 10h
lgdt [GDT.pointer]
push 16
pop ds
mov eax,cr0
or eax,1
mov cr0,eax
jmp 8:PM

[bits 32]
PM:
mov eax,'PMID';PM Info Block Signature - Assinatura VESA para MP
hlt


GDT:
.start:
	dq 0;null-descriptor
	
	;c�digo:
	dw 1111_1111_1111_1111b;bits 0-15 -> bits 0-15 do limite do segmento
	dw 0;bits 16-31 -> bits 0-15 do endere�o base
	db 0;bits 32-39 -> bits 16-23 do endere�o base
	;bit 40 -> bit de acesso - setado pela CPU para 1 cada vez que o segmento � acessado. Usado pelo OS para definir se o segmento � muito acessado
	;bit 41 -> acesso. 1 = leitura e escrita (segmento de dados), leitura e execu��o (segmento de c�digo), 0=leitura ("") e execu��o ("")
	;bit 42 -> dire��o de expans�o
	;bit 43 -> tipo de segmento (0=dados,1=c�digo)
	;bit 44 -> bit do descriptor - 0=do sistema,1=c�digo/dados(programa)
	;bits 45 e 46 -> privil�gio (0=m�x,3=m�n)
	;bit 47 -> bit P - setado se o segmento est� na mem�ria. Usado pelo sistema para manusear os segmetos em mem�ria RAM e virtual.
	db 1001_1010b;setado em ORDEM CONTR�RIA!
	;bits 48-51 -> bits 16-19 do limite do segmento
	;bit 52 -> reservado para o SO
	;bit 53 -> reservado (0)
	;bit 54 -> tipo de segmento (0=16 bits,1=32 bits)
	;bit 55 -> G (granularity) se setado, segmento *= 4K
	db 1100_1111b;setado em ORDEM CONTR�RIA!
	;bits 24-32 -> bits 24-32 do endere�o base
	db 0

	;dados:
	dw 1111_1111_1111_1111b;bits 0-15 -> bits 0-15 do limite do segmento
	dw 0;bits 16-31 -> bits 0-15 do endere�o base
	db 0;bits 32-39 -> bits 16-23 do endere�o base

	;bit 40 -> bit de acesso - setado pela CPU para 1 cada vez que o segmento � acessado. Usado pelo OS para definir se o segmento � muito acessado
	;bit 41 -> acesso. 1 = leitura e escrita (segmento de dados), leitura e execu��o (segmento de c�digo), 0=leitura ("") e execu��o ("")
	;bit 42 -> dire��o de expans�o
	;bit 43 -> tipo de segmento (0=dados,1=c�digo)
	;bit 44 -> bit do descriptor - 0=do sistema,1=c�digo/dados(programa)
	;bits 45 e 46 -> privil�gio (0=m�x,3=m�n)
	;bit 47 -> bit P - setado se o segmento est� na mem�ria. Usado pelo sistema para manusear os segmetos em mem�ria RAM e virtual.
	db 1001_0111b;setado em ORDEM CONTR�RIA!
	;bits 48-51 -> bits 16-19 do limite do segmento
	;bit 52 -> reservado para o SO
	;bit 53 -> reservado (0)
	;bit 54 -> tipo de segmento (0=16 bits,1=32 bits)
	;bit 55 -> G (granularity) - 1=segmento *= 4K
	db 1100_1111b;setado em ORDEM CONTR�RIA!
	;bits 24-32 -> bits 24-32 do endere�o base
	db 0
	
	

.pointer:
	dw .pointer - .start - 1
	dd .start

msgs:
%define pstring 'SVGA 32 bits n�o suportado'
.no_PM_SVGA: def_str
%define pstring 'Hardware n�o suporta SVGA'
.no_hardware_support: def_str
%define pstring 'Erro na fun��o SVGA'
.SVGA_function_call_failed: def_str
%define pstring 'GPU/monitor n�o suporta SVGA'
.GPU_monitor_failure: def_str
%define pstring 'Fun��o SVGA falhou'
.SVGA_error: def_str

vesa_buffer:
.signature db 'VBE2';Para VBE 2.0+. O fim do buffer tem 512 bytes.
.version_low db 0
.version_high db 0
.GPU_name_pointer dd 0
.capabilities db 0,0,0,0;bit 0: DAC (paleta de cores) tem tamanho fixo (6 bits por cor) se 0, sen�o DAC suporta tamb�m 8 bits por cor.
;bit 1: 0 se controlador � compat�vel com VGA (registradores, portas, etc)
;bit 2: 1 se, ao programar grandes blocos de RAMDAC, for nescess�rio usar "blank bit" em fun��o 09h (para n�o mudar paleta enquanto est� desenhando)
;bit 3: 1 se vis�o estereosc�pia (�culos 3D que pisca) suportado
;bit 4: 0 = sinal estereosc�pio suportado por conector stereo VESA
;		1 = "                                        " EVC VESA
.video_modes_pointer dd 0;ponteiro para array com modos de v�deo suportados pela PLACA DE V�DEO. � PRECISO TESTAR SE S�O SUPORTADOS PELO MONITOR.
;Acaba com -1 (0FFFFh). Se a primeira entrada � -1, SVGA n�o � suportado.
.video_RAM dw 0;mem�ria RAM instalada e utiliz�vel pela placa de v�deo / 64 KB.
.software_revision dw 0;BCD com a vers�o de software de SVGA

times 510 - ($ - $$) db 0
dw 0AA55h