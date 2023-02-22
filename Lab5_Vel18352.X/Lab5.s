;Archivo:	Lab5_Vel18352
;Dispositivo:   PIC16F887
;Autor:		Emilio Velasquez 18352
;Compilador:	XC8, MPLABX 5.40
;Programa:      Contador binario de 8 bits con contador decimal en 3 displays multiplexados
;Hardware:	2 pulsadores, 1 barra led y 3 displays
;Creado:	19/02/2023
;Ultima modificacion: 19/02/2023


// CONFIG1
CONFIG FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
CONFIG WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
CONFIG PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
CONFIG MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
CONFIG CP = OFF         // Code Protection bit (Program memory code protection is disabled)
CONFIG CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
CONFIG BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
CONFIG IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
CONFIG FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
CONFIG LVP = OFF       // Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

// CONFIG2
CONFIG BOR4V = BOR21V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
CONFIG WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

//#pragma CONFIG statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

PROCESSOR 16F887
#include <xc.inc>
        
UP	EQU	0
DOWN	EQU	1   ;Se establece el bit 0 como UP y 1 DOWN
  
PSECT	udata_bank0	;common memory
  Contador_A:		    DS 1
  Unidades:		    DS 1    
  Decenas:		    DS 1    
  Centenas:		    DS 1 
  Display_Bandera:	    DS 1 
  Display_Valor:	    DS 3
      
PSECT	udata_shr	;common memory
  W_TEMP:	DS 1	;1 Byte
  STATUS_TEMP:  DS 1	;1 Byte
    
PSECT resVect,	class=code, abs, delta=2
;------------------------- Vector Reset ---------------------------
ORG 00h			    ;Posicion del reset
resVect:
    PAGESEL main
    goto    main
    
PSECT intVect,	class=code, abs, delta=2
;------------------------- Interrupcion de Reset ---------------------------  
ORG 04h			    ;Posicion para la interrupciones
push:
    movwf   W_TEMP	    ;Se mueve de W a F 
    swapf   STATUS, W	    ;Se hace un swap de status y se almacena en W
    movwf   STATUS_TEMP	    ;Se mueve W a Status Temp  
isr:			    ;Sub Rutinas de interrupcion
    btfsc   RBIF	    ;Se chequea Interrupcion del puerto B
    call    int_iocb	    ;Se llama funcion de incrementar o decrementar Puerto B
    btfsc   T0IF	    ;Se chequea Interrupcion de Timer0
    call    Mostrar_Display	    ;Se llama funcion de contador display   
pop:    
    swapf   STATUS_TEMP, W  ;Se hace un swap de STATUS TEMP a W
    movwf   STATUS	    ;se mueve status a F
    swapf   W_TEMP, F	    ;Se hace swap de temp a f
    swapf   W_TEMP, W	    ;se hace swap de temp a w
    retfie		    ;regresa a la interrupcion
;----------------------- SUBRUTINA DE INTERRUPCI?N ----------------------------- 
int_iocb:
    banksel PORTB	    
    btfss   PORTB, UP	    ;Se verifica el bit UP para incrementar 
    incf    PORTA	    ;Incrementa Puerto A    
    btfss   PORTB, DOWN	    ;Se verifica el bit DOWN para decrementar
    decf    PORTA	    ;Decrementa Puerto A
    bcf	    RBIF	    ;Se limpia bandera de interrupcion
    return
       
PSECT CODE, DELTA=2, ABS
ORG 100h		    ;Posicion del codigo
;----------------------------- CONFIGURACION -----------------------------------
main:
    call    config_IO
    call    config_reloj
    call    config_iocb
    call    config_int_enable
    call    CONFIG_TMR0	    ;Se llaman las sub rutinas de conofiguracion 
;---------------------------- LOOP PRINCIPAL -----------------------------------
loop:
    call    Mover_Valor
    call    S_Centenas
    goto    loop	    ;regresa al bucle  
;----------------------------- SUB RUTINAS -------------------------------------
config_IO:
    banksel ANSEL
    clrf    ANSEL
    clrf    ANSELH	    ;I/O Digitales  
;------------ LEDs --------------    
    banksel TRISA
    clrf    TRISA	    ;Salida digital   
    banksel TRISB
    clrf    TRISB	    ;Salida digital	
    banksel TRISC
    clrf    TRISC	    ;Salida digital
    banksel TRISD
    clrf    TRISD	    ;Salida digital 
;------------ PUSH BOTTOM -----------    
    bsf	    TRISB, UP
    bsf	    TRISB, DOWN	    ;Entradas   
;---------- HABILITAR PULL-UP INTERNO ------    
    bcf	    OPTION_REG, 7
    bsf	    WPUB, UP
    bsf	    WPUB, DOWN
;------------ LIMPIAR PUERTO -------
    banksel PORTA
    clrf    PORTA	    ;Limpiar puerto    
    banksel PORTB
    clrf    PORTB	    ;Limpiar puerto     
    banksel PORTC
    clrf    PORTC	    ;Limpiar puerto   
    banksel PORTD
    clrf    PORTD	    ;Limpiar puerto   
    clrf    Contador_A	    ;Limpiar Contador
;----------- CONFIGURACION DE IOCB -----------
config_iocb:
    banksel TRISB
    bsf	    IOCB, UP
    bsf	    IOCB, DOWN	    ;Se habilita las interrupciones para cambio de estado en Puerto B    
    banksel PORTB
    movf    PORTB, 0	    ;Terminar mistmatch al terminar
    bcf	    RBIF	    ;Se limpia la bandera de interrupcion del Puerto B
    return
;----------- CONFIGURACION DEL RELOJ ----------    
config_reloj:
    banksel OSCCON
    bsf	    IRCF2
    bsf	    IRCF1
    bcf	    IRCF0	    ;Frecuencia de 4 MHz
    bsf	    SCS		    ;Reloj interno
    return
;-------- HABILITACION DE INTERRUPCIONES -------    
config_int_enable:   
    banksel INTCON
    bsf	    GIE		    ;Habilitar interrupciones globales
    bsf	    RBIE	    ;Se habilita la interrupcion de Puerto B
    bcf	    RBIF	    ;Se limpia la bandera de interrupcion del Puerto B
    bsf	    T0IE	    ;Se habilita interrupcion TMR0
    bcf	    T0IF	    ;Se limpia bandera de TMR0
    return  
;----------- CONFIGURACION DEL TIMER0 -----------      
CONFIG_TMR0:
    banksel OPTION_REG	    ;Se cambia de banco
    bcf	    T0CS	    ;TMR0 como temporizador
    bcf	    PSA		    ;Prescaler a TMR0
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0		    ;PS<2:0> -> 111 prescaler 1 : 256   
    banksel TMR0	    ;Se cambia de banco
    movlw   250
    movwf   TMR0	    ;2ms retardo
    bcf	    T0IF	    ;Se limpia bandera de interrupción
    return  
;----------- REINICIAR EL TIMER0 -----------    
reinicio_TMR0:		   
    movlw   250		    ;Mover la literal (250) a W
    movwf   TMR0	    ;Mover W a F
    bcf	    T0IF	    ;Se limpia bandera de interrupcion
    return 
;----------- Tabla del display -----------      
Display:		    ;Tabla de display para Anodo comun
    clrf    PCLATH
    bsf	    PCLATH,0
    andlw   0x0F
    addwf   PCL
    retlw   0x80    ;0
    retlw   0xF9    ;1
    retlw   0x24    ;2
    retlw   0x30    ;3
    retlw   0x19    ;4
    retlw   0x12    ;5
    retlw   0x02    ;6
    retlw   0xF8    ;7
    retlw   0x00    ;8
    retlw   0x10    ;9
    retlw   0x48    ;A
    retlw   0x03    ;B
    retlw   0xC6    ;C
    retlw   0x21    ;D
    retlw   0x06    ;E
    retlw   0x0E    ;F   
;----------- Mostrar valores en display -----------       
 Mostrar_Display:
    call    reinicio_TMR0	    ;Reinicia Timer0
    bcf	    PORTC, 0		
    bcf	    PORTC, 1		
    bcf	    PORTC, 2		    ;Se limpian selectores de multiplexado
    btfsc   Display_Bandera, 0	    ;Se verifica bandera de unidades
    goto    Display_3		    ;De estar encendida escribe valor de unidades
    btfsc   Display_Bandera, 1	    ;Se verifica bandera de decenas
    goto    Display_2		    ;De estar encendida escribe valor de decenas
    btfsc   Display_Bandera, 2	    ;Se verifica bandera de centenas
    goto    Display_1		    ;De estar encendida escribe valor de centenas   
;----------- Asignar valores a displays -----------       
Mover_Valor:
    movf    Unidades, 0		
    call    Display		
    movwf   Display_Valor	    ;Se mueve el valor de unidades y se carga en PORTD   
    movf    Decenas, 0		
    call    Display		
    movwf   Display_Valor+1	    ;Se mueve el valor de decenas y se carga en PORTD   
    movf    Centenas, 0		
    call    Display		
    movwf   Display_Valor+2	    ;Se mueve el valor centenas y se carga en PORTD
    return    
;----------- Display Unidades-----------   
Display_1:
    movf    Display_Valor, 0	    ;Mover el valor de display de centenas
    movwf   PORTD		    ;Mostrar el display
    bsf	    PORTC, 0		    ;Encender bit del display unidades
    bcf	    Display_Bandera, 2	    ;Apagar centenas
    bsf	    Display_Bandera, 1	    ;Encender decenas  
    return
;----------- Display Decenas -----------   
Display_2:
    movf    Display_Valor+1, 0	    ;Mover el valor de display de decenas
    movwf   PORTD		    ;Mostrar el display
    bsf	    PORTC, 1		    ;Encender bit del display decenas
    bcf	    Display_Bandera, 1	    ;Apagar decenas
    bsf	    Display_Bandera, 0	    ;Encender centenas
    return   
;----------- Display Centenas -----------       
Display_3:
    movf    Display_Valor+2, 0	    ;Mover el valor de display de unidades
    movwf   PORTD		    ;Mostrar el display
    bsf	    PORTC, 2		    ;Encender bit del display de unidades
    bcf	    Display_Bandera, 0	    ;Apagar centenas
    bsf	    Display_Bandera, 2	    ;Apagar unidades
    return      
;----------- Sub Rutinas para separar valor ----------- 
;----------- Separar Centenas -----------   
S_Centenas:
    clrf    Centenas		
    clrf    Decenas		
    clrf    Unidades		;Limpiar variables     
    movf    PORTA, 0		;Se transfiere el valor de PORTA
    movwf   Contador_A		;Mover a Contador_A
    movlw   100			;100 a W
    subwf   Contador_A, 1	;Restar 100 a Contador_A
    incf    Centenas		;Incrementar Centenas
    btfsc   STATUS, 0		;Verificar bandera BORROW, Si obtiene valor positivo se mantiene en 1 de lo contrario es negativo
    goto    $-4			;Si esta encendida regresa a restar
    decf    Centenas		;Si no enciende resta una Centena compensando al momento de re evaluar PORTA
    movlw   100			;100 a W
    addwf   Contador_A, 1	;Añadir 100 para compensar el numero negativo
    call    S_Decenas	        ;Ir a sub rutina de Dececnas   
    return
;----------- Separar Decenas -----------       
S_Decenas:
    movlw   10			;10 a W
    subwf   Contador_A, 1	;Se resta 10 a Contador_A
    incf    Decenas		;Incrementar Decenas
    btfsc   STATUS, 0		;Verificar bandera BORROW, Si obtiene valor positivo se mantiene en 1 de lo contrario es negativo
    goto    $-4			;Si esta encendida regresa a restar
    decf    Decenas		;Si no enciende incrementa una Decima para compensar al re evaluar PORTA
    movlw   10			;10 a W
    addwf   Contador_A, 1	;Añadir 10 para compensar numero negativo
    call    S_Unidades		;Ir a sub rutina de Unidades  
    return
;----------- Separar Unidades -----------       
S_Unidades:
    movlw   1			;1 a W
    subwf   Contador_A, 1	;Se resta 1 a Contador_A
    incf    Unidades		;Incrementar Unidades
    btfsc   STATUS, 0		;Verificar bandera BORROW, Si obtiene valor positivo se mantiene en 1 de lo contrario es negativo
    goto    $-4			;Si esta encendida regresa a restar
    decf    Unidades		;Si no enciende incrementa una Unidad para compensar al re evaluar PORTA
    movlw   1			;1 a W
    addwf   Contador_A, 1	;Incrementar 1 para compensar negativo en este caso da 0
    return    
END    