.include "m328pdef.inc"
;----------- definiciones para comunicacion suart USART0 -----------

.def  usart_leido = r23
.def usart_escribir = r24
;--------------------------------------------------------------------




;------------------ definiciones para datos SRAM --------------------
.equ PESO_UMBRAL_H = 0x02
.equ PESO_UMBRAL_M = 0x00
.equ PESO_UMBRAL_L = 0x00

.equ PESO_MAX_H = 0x05
.equ PESO_MAX_M = 0xFE 
.equ PESO_MAX_L = 0x00


;peso 10% fernet (de 300 ml)
.equ PESO_LIQUIDO_1_H = 0x00
.equ PESO_LIQUIDO_1_M = 0x6E
.equ PESO_LIQUIDO_1_L = 0x80

;peso 10% coca (de 300 ml)
.equ PESO_LIQUIDO_2_H = 0x00
.equ PESO_LIQUIDO_2_M = 0x78
.equ PESO_LIQUIDO_2_L = 0x80

;-------- manejar_estado.def ---------------------------------------
;registro de estados
.def estado = r16			;ESTE REGISTRO NO PUEDE SER USADO PARA OTRA COSA

;bit de estado de deteccion de pulsos O VASO
.equ DT_BIT = 0
;bit de estado de configurar el vaso puesto
.equ CV_BIT = 1
;bit de estado de servido primer liquido
.equ S1_BIT = 2
;bit de estado de servido de segundo liquido
.equ S2_BIT = 3
;bit de estado de espera a retirar vaso lleno
.equ RV_BIT = 4
;-------------------------------------------------------------------

;------- estado de deteccion --------
.def contador = r17

;hay que medirlos todavía
.equ TIEMPO_PULSO_MENOR = 1
.equ TIEMPO_PULSO_MAYOR = 3

.equ TIEMPO_VASO  = 10

;------- configurar_vaso ------------
.def temp_0 = r18
.def temp_L = r19
.def temp_M = r20
.def temp_H = r21

.def graduacion = r22
;---------------------------------------------------------

;------------- definiciones leer_hx711 -------------
;registros auxiliares
.def A=r20
.def NRO_BITS_HX711 = r19

;defino los registros de I/O que voy  a usar
.equ DDR_ADSK = DDRB
.equ DDR_ADDO = DDRB
.equ port_ADSK = portB
.equ pin_ADDO = pinB

;pines de el/los puerto/s a utilizar
.equ ADSK = 1
.equ ADDO = 0

;registros de paso del dato leido
.def peso_leido_L = r16
.def peso_leido_M = r17
.def peso_leido_H = r18
;--------------------------------------------------------------------

;-----------------definiciones para promedio-----------------
.equ LONG_TABLA = 8 ;debe ser potencia de 2 (y minimo 2)
.equ DIV_LONG_TABLA = 3	;cuantas veces shiftear para dividir por N
.def leido_L=r16
.def leido_M=r17
.def leido_H=r18
;--------------------------------------------------------------
;----------------- definiciones para guardar_peso --------------------
.def gd_temp = r16
.def reg_posicion_tabla = r17
.def gd_contador = r18

.equ TMNO_DATO = 3
.equ FIN_TABLA = 24

;----------- cambiar graduacion (control de display) -----------
.equ DDR_DISPLAY = DDRD
.equ PORT_DISPLAY = PORTD				 ;puerto utilizado para el display

;posiciones de los LEDs en el puerto
.equ LED_1 = 2
.equ LED_2 = 3
.equ LED_3 = 4
.equ LED_4 = 5
.equ LED_5 = 6
.def display = r16
;-----------------------------------------
;----------- obtener graduacion -----------
;deben coincidir con el display de leds
.equ GRAD_20 =3
.equ GRAD_30 =4
.equ GRAD_40 =5
.equ GRAD_50 =6
;-----------------------------------------
;------------ control de bombas -----------
.equ DDR_BOMBAS = DDRB
.equ PORT_BOMBAS = PORTB

;pines donde estan las bombas
.equ BOMBA_1 = 3
.equ BOMBA_2 = 4
;------------------------------------------

;---------cmp24-------
.def cp24_temp = r24
;---------------------

;--------------------------------------------------------------------

.dseg
;umbral de deteccion para estado activo
peso_umbral:
	.byte 3
;maximo peso que puede pesar un vaso
peso_max:
	.byte 3
;valor binario del peso de 10% de vaso de liquido 1 
peso_liquido_1:
	.byte 3
;valor binario del peso de 10% de vaso de liquido 2
peso_liquido_2:
	.byte 3

;dato leido del modulo
dato_hx711:
	.byte 3

;tabla de 8 pesos leidos
tabla_pesos:
	.byte 24
;guardo la posicion de la tabla para escribirla
posicion_tabla:
	.byte 1

;promedio de valores de tabla (lo devuelve la funcion promedio)
promedio:
	.byte 3

;hasta el valor que este guardado aca va a servir el primer liquido
cota_1:
	.byte 3
;hasta el valor que este aca va a servir el segundo liquido
cota_2:
	.byte 3

.cseg
	.org 0x00
	rjmp main

	.org OVF1addr
	rjmp ISR_T1_OV
	.org int_vectors_size

main:

;configuracion
	;inicializo stack pointer
	ldi r20, high(RAMEND)
	out sph, r20
	ldi r20, low(RAMEND)
	out spl, r20

;--------------------------sacar esto-------------------------
	;cargo el valor para el BAUD rate (BAUD = 9600) --> UBRR = 103
	ldi r17, high(103)
	ldi r16, low(103)
	
	;inicializo la comunicacion usart
	rcall USART_Init
	clr r16
	clr r17
;-----------------------------------------------------------------	

;hay que inicializar uart (por el momento no)
;inicializo la posicion de tabla en 0
	ldi XL, low(posicion_tabla)
	ldi XH, high(posicion_tabla)
	ldi r20, 0
	st X, r20

;hay que inicializar sleep
	in r20, SMCR
	;limpio los bits de velocidad en el registro
	ori r20, 1<<SE

	;seteo la modo de timer (a idle: (SM2|1|0) = 000)
	andi r20, ~(1<<SM0|1<<SM1|1<<SM2)
	out SMCR,R20






;guardo los datos de ummbral, peso de 10% liquido 1, peso de 10% liquido 2 en la sram
	ldi XL, low(peso_umbral)
	ldi XH, high(peso_umbral)

	ldi r20, PESO_UMBRAL_H
	st X+, r20
	ldi r20, PESO_UMBRAL_M
	st X+, r20
	ldi r20, PESO_UMBRAL_L
	st X, r20

	ldi XL, low(peso_max)
	ldi XH, high(peso_max)

	ldi r20, PESO_MAX_H
	st X+, r20
	ldi r20, PESO_MAX_M
	st X+, r20
	ldi r20, PESO_MAX_L
	st X, r20


	ldi XL, low(peso_liquido_1)
	ldi XH, high(peso_liquido_1)

	ldi r20, PESO_LIQUIDO_1_H
	st X+, r20
	ldi r20, PESO_LIQUIDO_1_M
	st X+, r20
	ldi r20, PESO_LIQUIDO_1_L
	st X, r20

	ldi XL, low(peso_liquido_2)
	ldi XH, high(peso_liquido_2)

	ldi r20, PESO_LIQUIDO_2_H
	st X+, r20
	ldi r20, PESO_LIQUIDO_2_M
	st X+, r20
	ldi r20, PESO_LIQUIDO_2_L
	st X, r20

;configuro puertos de entrada y salida

	;inicializo los pines para lectura de hx711
	sbi DDR_ADSK, ADSK
	cbi DDR_ADDO, ADDO

	;seteo como salidas a los pines de los led del display
	in r20, DDR_DISPLAY
	ori r20, (1<<LED_1)|(1<<LED_2)|(1<<LED_3)|(1<<LED_4)|(1<<LED_5)
	out  DDR_display, r20
	;siempre debe estar prendido el LED_1 (no hay opcion de graduacion 0)
	sbi PORT_DISPLAY, LED_1
	
	;seteo los pines de control de bombas de liquido como salidas
	in r20, DDR_BOMBAS
	ori r20, (1<<BOMBA_1)|(1<<BOMBA_2)
	out  DDR_BOMBAS, r20

;inicializo el timer1

	lds r20, TCCR1B
	;limpio los bits de velocidad en el registro
	andi r20, ~(1<<CS12|1<<CS11|1<<CS10)
	;seteo la velocidad
	;velocidad (1 muestra cada 4ms)(sin prescaler)
	ori r20, 0<<CS12|1<<CS11|1<<CS10
	sts TCCR1B,R20

	;habilito la interrupcion	
	lds r20, TIMSK1
	ori R20, 1<<TOIE1
	sts TIMSK1, r20

;setear registro de estados en 0 (chequeo de pulso/vaso)
	clr estado
	ori estado, 1<<DT_BIT
	sei

main_loop:
	;entro en sleep hasta medir un peso
	sleep
	rcall manejo_estado
	rjmp main_loop

;--------------------------------------------------------------------
manejo_estado:
	
	sbrc estado, DT_BIT
	rcall estado_deteccion

	sbrc estado, CV_BIT
	rcall estado_configurar_vaso

	sbrc estado, S1_BIT
	rcall estado_servir_liquido_1

	sbrc estado, S2_BIT
	rcall estado_servir_liquido_2

	sbrc estado, RV_BIT
	rcall estado_retirar_vaso

	ret

;------------------- (estado 1) --------------------------
estado_deteccion:
	
	ldi XL, low(dato_hx711)
	ldi XH, high(dato_hx711)
	ldi YL, low(peso_max)
	ldi YH, high(peso_max)

	;si el dato leido es mayor al peso maximo para un vaso, lo toma como nada y limpia el contador
	rcall cp24
	brts nada


	ldi YL, low(peso_umbral)
	ldi YH, high(peso_umbral)
	rcall cp24

	;si el dato leido es menor al umbral y menor al máximo, va a validar si es un pulso
	brtc validar

	;si es mayor a umbral, incrementa el contador
	inc contador

	;si el contador es igual a TIEMPO_VASO, cambia los flags: CV=1 Y DT=0
	cpi contador, TIEMPO_VASO
	breq cambiar_a_CV

	;si el contador no es tiempo vaso, vuelve al inicio a sleep
	rjmp ret_estado_deteccion

;salto aca si el dato leido es menor al umbral
validar:
	;si el contador esta entre TIEMPO_PULSO_MENOR y TIMEPO_PULSO_MAYOR, cambia la graduacion elegida
	cpi contador, TIEMPO_PULSO_MENOR
	brsh seguir
	rjmp nada
seguir:
	cpi contador, TIEMPO_PULSO_MAYOR
	brlo cambio_de_graduacion


	;si no fue un pulso, resetea el contador
nada:
	clr contador
	rjmp ret_estado_deteccion

cambio_de_graduacion:
	;desactivar timer aca? (no creo que sea necesario aca)
	rcall cambiar_graduacion
	;activarlo aca de nuevo?

	clr contador
	rjmp ret_estado_deteccion

;salto aca si el contador llego a TIEMPO_VASO
cambiar_a_CV:
	clr contador
	clr estado
	ori estado, 1<<CV_BIT

ret_estado_deteccion:
	rcall guardar_peso
	ret

;------------- (estado 2) ------------------
;en este  estado configuro las cotas hasta las que va a servir cada líquido
estado_configurar_vaso:
	push graduacion
	push XL
	push XH
	push temp_0
	push temp_L
	push temp_M
	push temp_H

	;desactivo el timer cuando configuro
	rcall desactivar_timer

	ldi XL, low(dato_hx711)
	ldi XH, high(dato_hx711)

	;devuelve la graduacion en el registro "graduacion"
	rcall obtener_graduacion
	
	;guardo en temp el peso del vaso
	ld temp_H, X+
	ld temp_M, X+
	ld temp_L, X

;guardo en cota 1 el valor del vaso + el peso del 10% del líquido_1 por la graduacion elegida
	ldi XL, low(peso_liquido_1+2)
	ldi XH, high(peso_liquido_1+2)
	;meto el valor en el stack para no perderlo
	push graduacion
loop_cota_1:
	ld temp_0, X
	add temp_L, temp_0
	ld temp_0, -X
	adc temp_M, temp_0
	ld temp_0, -X
	adc temp_H, temp_0

	;vuelvo al puntero a la posicion inicial
	adiw XH:XL, 2

	dec graduacion
	brne loop_cota_1
	;obtengo de nuevo el valor de graduacion
	pop graduacion

	ldi XL, low(cota_1)
	ldi XH, high(cota_1)	
	st X+, temp_H
	st X+, temp_M
	st X, temp_L

;pone como segunda cota peso_vaso + peso_10_liquido_1 * graduacion + peso_liquido_2 * (10-graduacion)
	ldi XL, low(peso_liquido_2+2)
	ldi XH, high(peso_liquido_2+2)
	;hago graduacion -10 y lo complemeno (ca2) (para que de positivo)
	subi graduacion, 10
	neg graduacion

loop_cota_2:
	ld temp_0, X
	add temp_L, temp_0
	;sbiw XH:XL, 1
	ld temp_0, -X
	adc temp_M, temp_0
	;sbiw XH:XL, 1
	ld temp_0, -X
	adc temp_H, temp_0

	;vuelvo al puntero a la posicion inicial
	adiw XH:XL, 2

	dec graduacion
	brne loop_cota_2

	ldi XL, low(cota_2)
	ldi XH, high(cota_2)
	st X+, temp_H
	st X+, temp_M
	st X, temp_L	
	
;cambio estado a servir liquido_1 y vuelvo
	clr estado
	ori estado, 1<<S1_BIT
	;activo el timer de nuevo
	rcall activar_timer
	
	pop temp_H
	pop temp_M
	pop temp_L
	pop temp_0
	pop XH
	pop XL
	pop graduacion
	ret

;------------- (estado 3) -----------------------
estado_servir_liquido_1:
	rcall abrir_bomba_1
	rcall promedio_tabla
	
	ldi XL, low(dato_hx711)
	ldi XH, high(dato_hx711)

	ldi YL, low(peso_umbral)
	ldi YH, high(peso_umbral)

	rcall cp24
	;si el peso leido es menor al umbral, cancelo el servido
	brtc cancelar_s1

	ldi YL, low(promedio)
	ldi YH, high(promedio)
	
	rcall cp24
	;si el peso leido es menor al promedio, cancelo el servido
	brtc cancelar_s1
	
	ldi YL, low(cota_1)
	ldi YH, high(cota_1)
	rcall cp24
	;si el peso leido es mayor a la cota_1, salta
	brts terminar_s1
	rjmp ret_servir_liquido_1

cancelar_s1:
	rcall cerrar_bomba_1
	;cambio estado a RV (que espera a que el peso leido sea menor al umbral para reiniciar)
	clr estado
	ori estado, 1<<RV_BIT
	rjmp ret_servir_liquido_1

terminar_s1:
	rcall cerrar_bomba_1
	clr estado
	ori estado, 1<<S2_BIT

ret_servir_liquido_1:
	rcall guardar_peso
	ret


;------------- (estado 4) -----------------------
estado_servir_liquido_2:

	rcall abrir_bomba_2
	rcall promedio_tabla
	
	ldi XL, low(dato_hx711)
	ldi XH, high(dato_hx711)

	ldi YL, low(peso_umbral)
	ldi YH, high(peso_umbral)

	rcall cp24
	;si el peso leido es menor al umbral, cancelo el servido
	brtc cancelar_s2

	ldi YL, low(promedio)
	ldi YH, high(promedio)
	
	rcall cp24
	;si el peso leido es menor al promedio, salta	
	brtc cancelar_s2
	
	ldi YL, low(cota_2)
	ldi YH, high(cota_2)
	rcall cp24
	;si el peso leido es mayor a la cota_2, salta
	brts terminar_s2
	rjmp ret_servir_liquido_2

cancelar_s2:
	rcall cerrar_bomba_2
	;cambio estado a RV (que espera a que el peso leido sea menor al umbral para reiniciar)
	clr estado
	ori estado, 1<<RV_BIT
	rjmp ret_servir_liquido_2

terminar_s2:
	rcall cerrar_bomba_2
	clr estado
	ori estado, 1<<RV_BIT

ret_servir_liquido_2:
	rcall guardar_peso
	ret




;------------- (estado 5) -----------------------
estado_retirar_vaso:
	rcall promedio_tabla
	
	ldi XL, low(promedio)
	ldi XH, high(promedio)

	ldi YL, low(peso_umbral)
	ldi YH, high(peso_umbral)

	rcall cp24
	;si el promedio es menor al umbral, cambia de estado a Detección
	brtc cambiar_a_DT
	rjmp ret_estado_retirar_vaso

cambiar_a_DT:
	clr estado
	ori estado, 1<<DT_BIT

ret_estado_retirar_vaso:
	rcall guardar_peso
	ret


;-----------------------------------------------------------------
guardar_peso:
	push gd_contador
	push reg_posicion_tabla
	push gd_temp
	push XL
	push XH
	push YL
	push YH

	;pongo en gd_contador el tamaño de los datos de la tabla (cuantos registros ocupa)
	ldi gd_contador, TMNO_DATO

	;obtengo la posicion de donde guarde el dato menos reciente
	ldi XL, low(posicion_tabla)
	ldi XH, high(posicion_tabla)
	ld reg_posicion_tabla, X
	
	ldi XL, low(dato_hx711)
	ldi XH, high(dato_hx711)
	ldi YL, low(tabla_pesos)
	ldi YH, high(tabla_pesos)

;guardo el dato leido en la posicion de la tabla que seguía de la vez anterior
	add YL, reg_posicion_tabla
	brcc guardar_siguiente
	inc YH

;guarda la cantidad de registros que ocupa un dato
guardar_siguiente:
	ld gd_temp, X+
	st Y+, gd_temp
	dec gd_contador
	brne guardar_siguiente

	;incremento la posicion en un dato
	subi reg_posicion_tabla, -TMNO_DATO

	;si llega al final de la tabla lo vuelve a 0
	cpi reg_posicion_tabla, FIN_TABLA
	brne ret_guardar_dato
	ldi reg_posicion_tabla, 0

ret_guardar_dato:
	ldi XL, low(posicion_tabla)
	ldi XH, high(posicion_tabla)

	st X, reg_posicion_tabla

	pop YH
	pop YL
	pop XH
	pop XL
	pop gd_temp
	pop reg_posicion_tabla
	pop gd_contador

	ret

;---------------------- cambiar graduacion --------------------------
cambiar_graduacion:
	push display

	;leemos en el registro display el puerto de los leds
	
	;comparamos uno a uno si estan encendidos los LEDs
	; cuando lee uno no prendido, lo prende y sale
	sbis PORT_DISPLAY, LED_2
	rjmp d_graduacion_20
	sbis PORT_DISPLAY, LED_3
	rjmp d_graduacion_30
	sbis PORT_DISPLAY, LED_4
	rjmp d_graduacion_40
	sbis PORT_DISPLAY, LED_5
	rjmp d_graduacion_50
	
	;si todos los LEDs estaban prendidos, reinicia el display
	;dejando prendido el LED1 (y deja los pines que no son led como estaban)
	in display, PORT_DISPLAY
	andi display, ~((1<<LED_2)|(1<<LED_3)|(1<<LED_4)|(1<<LED_5))
	out PORT_DISPLAY, display
	rjmp ret_modificar_display

d_graduacion_20:
	sbi PORT_DISPLAY, LED_2
	rjmp ret_modificar_display
d_graduacion_30:
	sbi PORT_DISPLAY, LED_3
	rjmp ret_modificar_display
d_graduacion_40:
	sbi PORT_DISPLAY, LED_4
	rjmp ret_modificar_display
d_graduacion_50:
	sbi PORT_DISPLAY, LED_5
	rjmp ret_modificar_display

ret_modificar_display:
	pop display
	ret
;------------------- obtener graduacion ---------------------
obtener_graduacion:

	;la graduacion debe estar al menos en 10% (graduacion = 1)
	ldi graduacion, 1
	
	;chequeo si los leds estan prendidos, y si lo estan, aumenta la graduacion en 1
	;cuando ve el primero sin prender, sale
	sbis PORT_DISPLAY, GRAD_20
	rjmp ret_obtener_graduacion
	inc graduacion

	sbis PORT_DISPLAY, GRAD_30
	rjmp ret_obtener_graduacion
	inc graduacion

	sbis PORT_DISPLAY, GRAD_40
	rjmp ret_obtener_graduacion
	inc graduacion

	sbis PORT_DISPLAY, GRAD_50
	rjmp ret_obtener_graduacion
	inc graduacion

ret_obtener_graduacion:
	ret
;----------------------------------------

activar_timer:
	push r20
	lds r20, TIMSK1
	ori R20, 1<<TOIE1
	sts TIMSK1, r20
	pop r20
	ret

desactivar_timer:
	push r20
	lds r20, TIMSK1
	andi r20, ~(1<<TOIE1)
	sts TIMSK1, r20
	pop r20
	ret

abrir_bomba_1:
	sbi PORT_BOMBAS, BOMBA_1
	ret
cerrar_bomba_1:
	cbi PORT_BOMBAS, BOMBA_1
	ret
abrir_bomba_2:
	sbi PORT_BOMBAS, BOMBA_2
	ret
cerrar_bomba_2:
	cbi PORT_BOMBAS, BOMBA_2
	ret
;------------------------- leer_hx711 ---------------------------------------
leer_hx711:
	push NRO_BITS_HX711
	push A
	push peso_leido_L
	push peso_leido_M
	push peso_leido_H
	push XL
	push XH
	;limpio el carry porque lo voy a usar
	clc
	;limpio los registros que voy a usar
	clr peso_leido_L
	clr peso_leido_M
	clr peso_leido_H

	;habilito la conversión de datos si no estaba activada
	cbi port_ADSK, ADSK

	;si no termino la conversión vuelve a chequear ADDO
AD_not_finished:
	sbic pin_ADDO, ADDO 	
	rjmp AD_not_finished

	;cargo el contador r19 con 24 para pasar 24 bits
	ldi NRO_BITS_HX711, 24

ShiftOut:
	;mando un pulso de clock
	sbi port_ADSK, ADSK
	;se necesita delay de 1us aproximadamente, usamos 18 ciclos de máquina (con freq=16MHz), por lo que tarda 1,125us
	rcall T_high
	cbi port_ADSK, ADSK

	;guarda el dato leido en el carry
	sbic pin_ADDO, ADDO
	sec			
	
	;guarda el bit leido en los registros
	mov A,peso_leido_L
	rol A
	mov peso_leido_L,A
	mov A,peso_leido_M
	rol A
	mov peso_leido_M,A
	mov A,peso_leido_H
	rol A
	mov peso_leido_H,A
	;chequeo si movio los 24 bits
	dec r19
	brne ShiftOut

	;vuelvo a poner el clock en 1 cuando termina y asi
	;pone a DOUT en alto nuevamente
	sbi port_ADSK, ADSK
	rcall T_high

	;el clock debe terminar en bajo
	;para no entrar en modo de bajo consumo del hx711
	cbi port_ADSK, ADSK

	ldi XL, low(dato_hx711)
	ldi XH, high(dato_hx711)

;guardo el dato en la SRAM
	st X+, peso_leido_H
	st X+, peso_leido_M
	st X, peso_leido_L

	pop XH
	pop XL
	pop peso_leido_H
	pop peso_leido_M
	pop peso_leido_L
	pop A
	pop NRO_BITS_HX711
	ret 

;este delay dura 15 ciclos de maquina, sin contar el rcall
T_high:
	push r16
	ldi r16, 3
T_h_loop:
	dec r16
	brne T_h_loop
	
	pop r16
	ret
;-------------------------- promedio de tabla ---------------------------------------
;hace el promedio de los datos almacenados en la tabla
;devuelve el resultado en la posicion "promedio" en sram
promedio_tabla:
	push leido_L
	push leido_M
	push leido_H
	push r19
	push r20
	push r21
	push r22
	push r23
	push XL
	push XH

;limpio los registros acumuladores
	clr r20
	clr r21
	clr r22
	clr r23
;puntero para obtener los datos que leo
	ldi XL, LOW(tabla_pesos)
	ldi XH, HIGH(tabla_pesos)

	;hace el promedio de LONG_TABLA pesos leidos	
	ldi r19, LONG_TABLA
sumar:

	ld leido_H, X+
	ld leido_M, X+
	ld leido_L, X+

	;sumo de a 4 registros y acumulo el resultado en r23:r22:r21:r20
	add r20, leido_L
	adc r21, leido_M
	adc	r22, leido_H
	;si hubo carry incrementa el registro mas significativo
	brcc skip
	inc r23
skip:
	dec r19
	brne sumar

	;divide por LONG_TABLA (tiene que ser pot de 2) el resultado
	ldi r19, DIV_LONG_TABLA
dividir:
	lsr r23
	ror r22
	ror r21
	ror r20
	dec r19
	brne dividir
	
	;resto un valor pequeño para permitir un margen de tolerancia al servir
	subi r20, 0x00
	sbci r21, 0x19
	sbci r22, 0x00
	;una vez obtenido el resultado del promedio de 4 medidas de peso
	;lo guarda en la sram (resultado en primeros 24 bits)
	ldi XL, low(promedio)
	ldi XH, high(promedio)
	st X+, r22 ;peso_H
	st X+, r21 ;peso_M
	st X, r20  ;peso_L

	pop XH
	pop XL
	pop r23
	pop r22
	pop r21
	pop r20
	pop r19
	pop leido_H
	pop leido_M
	pop leido_L
	ret

;-----------------------------------------------------------------
;compara a los numeros de 3 bytes ubicados en los punteros X e Y
;devuelve el resultado en el bit T del SREG
;X<Y T = 0, X>=Y T = 1
cp24:
	push r17
	push r18
	push r24
	push XL
	push XH
	push YL
	push YH
	push cp24_temp
	;contador para comparar 3 registros
	ldi cp24_temp, 3
loop_cpi24:
	ld r17, X+
	ld r18, Y+
	cp r17, r18
	brlo X_menor_a_Y  
	cp r18, r17
	brlo X_mayor_o_igual_a_Y
	dec cp24_temp
	brne loop_cpi24
	
X_mayor_o_igual_a_Y:
	set
	rjmp ret_cp24

X_menor_a_Y:
	clt
	rjmp ret_cp24

ret_cp24:

	pop cp24_temp
	pop YH
	pop YL
	pop XH
	pop XL
	pop r24
	pop r18
	pop r17
	ret
;-----------------------------------------------------------------




;--------- interrupcion por timer overflow -------------------
ISR_T1_OV:
	push XL
	push XH
	push usart_escribir
	
	rcall leer_hx711
	ldi XL, low(dato_hx711)
	ldi XH, high(dato_hx711)
		
	ld usart_escribir, X+
	rcall USART_Transmit

	ld usart_escribir, X+
	rcall USART_Transmit

	ld usart_escribir, X
	rcall USART_Transmit

	pop usart_escribir
	pop XH
	pop XL
	reti


;--------------------------USART0------------------------------------

;inicializar la comunicación USART asincronica normal
USART_Init:
	; Setea baud rate (asume que el UBRR esta en R17(H):R16(L))
	sts UBRR0H, r17
	sts UBRR0L, r16
	; habilita transmisión y recepción
	ldi r16, (1<<RXEN0)|(1<<TXEN0)
	sts UCSR0B,r16
	; Setea formato de "frame"(bits de la comunicacion): 8data, 2stop bit
	ldi r16, (1<<USBS0)|(3<<UCSZ00)
	sts UCSR0C,r16
	ret
;-----------------------------------------------------
;recibir datos de 5 a 8 bits en Usart_leido
USART_Receive:
	push r21
	; Espera a recibir dato
loop_r:
	lds R21, UCSR0A
	sbrs R21, RXC0
	rjmp loop_r
	; recibe los datos del buffer UDR0
	lds usart_leido, UDR0

	pop r21
	ret
;-----------------------------------------------------
;transmitir 5 a 8 bits por usart_escribir
USART_Transmit:
	push r20
	; Espera a que el buffer de transmisión este vacío
loop_t:
	lds R20,UCSR0A
	sbrs R20,UDRE0
	rjmp loop_t
	; pone el dato de R16 en el buffer de transmisión y lo envía
	sts UDR0,usart_escribir
	pop r20
	ret

;-----------------------------------------------------
