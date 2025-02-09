; =====================================================
; Lab1
; Autor: Sara Hernández-21743
; =====================================================
; Contador 1:
;   - LEDs: PB4-PB1
;   - Botones: PC3 (incremento), PC4 (decremento)
; Contador 2:
;   - LEDs: PB0(LSB), PD7, PD6, PD5
;   - Botones: PD3 (incremento), PD2 (decremento)
; Suma:
;   - LEDs resultado: PB5 (LSB), PC0, PC1, PC2 (MSB)
;   - Boton suma: PC5
; =====================================================

; Incluir definiciones del ATmega328P
.include "m328Pdef.inc"

; === DEFINICIÓN DE REGISTROS ===
.def temp = r16       ; Registro temporal para operaciones generales
.def cont1 = r17      ; Contador 1 (0-15)
.def cont2 = r18      ; Contador 2 (0-4)
.def result = r19     ; Resultado de la suma
.def carry = r20      ; Indicador de overflow en la suma

; Vector de reset
.org 0x00
    rjmp inicio       ; Saltar a la rutina de inicio

inicio:
    ; Configurar oscilador a 1MHz
    cli                    ; Deshabilitar interrupciones
    ldi temp, 0x80        ; Cargar valor para habilitar cambio de prescaler
    sts CLKPR, temp       ; Habilitar cambio de prescaler
    ldi temp, 0x03        ; Divisor de 8 para conseguir 1MHz
    sts CLKPR, temp       ; Establecer nuevo prescaler
    sei                   ; Habilitar interrupciones

    ; === CONFIGURACIÓN DE PUERTOS ===
    ; Configurar Puerto B
    ldi temp, 0x3F        ; Configurar PB5-PB0 como salidas (0011 1111)
    out DDRB, temp        ; Establecer dirección de los pines
    ldi temp, 0x00        ; Inicializar todos los pines en 0
    out PORTB, temp       ; Aplicar valor inicial

    ; Configurar Puerto C
    ldi temp, 0x07        ; PC2-PC0 como salidas para resultado
    out DDRC, temp        ; Establecer dirección
    ldi temp, 0x38        ; Pull-ups en PC5 (suma), PC4, PC3 (0011 1000)
    out PORTC, temp       ; Activar pull-ups

    ; Configurar Puerto D
    ldi temp, 0xE0        ; PD7-PD5 como salidas (1110 0000)
    out DDRD, temp        ; Establecer dirección
    ldi temp, 0x0C        ; Pull-ups en PD3-PD2 (0000 1100)
    out PORTD, temp       ; Activar pull-ups

    ; Inicializar registros
    clr cont1             ; Contador 1 a 0
    clr cont2             ; Contador 2 a 0
    clr result           ; Resultado a 0
    clr carry            ; Carry a 0

; === LOOP PRINCIPAL ===
main_loop:
    ; Verificar botones del Contador 1
    sbic PINC, 3          ; Saltar si PC3 está en 0 (presionado)
    rcall inc_cont1       ; Incrementar contador 1
    
    sbic PINC, 4          ; Saltar si PC4 está en 0 (presionado)
    rcall dec_cont1       ; Decrementar contador 1

    ; Verificar botones del Contador 2
    sbic PIND, 3          ; Saltar si PD3 está en 0 (presionado)
    rcall inc_cont2       ; Incrementar contador 2
    
    sbic PIND, 2          ; Saltar si PD2 está en 0 (presionado)
    rcall dec_cont2       ; Decrementar contador 2

    ; Verificar botón de suma
    sbic PINC, 5          ; Saltar si PC5 está en 0 (presionado)
    rcall hacer_suma      ; Realizar suma

    ; Actualizar displays
    rcall mostrar_cont1   ; Actualizar LEDs contador 1
    rcall mostrar_cont2   ; Actualizar LEDs contador 2
    
    rjmp main_loop        ; Volver al inicio del loop

; === RUTINAS CONTADOR 1 ===
inc_cont1:
    rcall debounce_corto  ; Antirrebote
    sbic PINC, 3          ; Verificar si botón sigue presionado
    ret                   ; Si no, retornar
    cpi cont1, 15         ; Comparar con máximo valor
    breq inc1_done        ; Si es igual, no incrementar
    inc cont1             ; Incrementar contador
inc1_done:
    ret

dec_cont1:
    rcall debounce_corto  ; Antirrebote
    sbic PINC, 4          ; Verificar si botón sigue presionado
    ret                   ; Si no, retornar
    cpi cont1, 0          ; Comparar con mínimo valor
    breq dec1_done        ; Si es igual, no decrementar
    dec cont1             ; Decrementar contador
dec1_done:
    ret

mostrar_cont1:
    in temp, PORTB        ; Leer estado actual de PORTB
    andi temp, 0xE1       ; Mantener bits no usados por cont1 (1110 0001)
    mov r21, cont1        ; Copiar valor del contador
    lsl r21               ; Desplazar a posición correcta
    andi r21, 0x1E        ; Mantener solo bits relevantes (0001 1110)
    or temp, r21          ; Combinar con estado actual
    out PORTB, temp       ; Actualizar LEDs
    ret

; === RUTINAS CONTADOR 2 ===
inc_cont2:
    rcall debounce_corto  ; Antirrebote
    sbic PIND, 3          ; Verificar si botón sigue presionado
    ret                   ; Si no, retornar
    cpi cont2, 4          ; Comparar con máximo valor
    breq inc2_done        ; Si es igual, no incrementar
    inc cont2             ; Incrementar contador
inc2_done:
    ret

dec_cont2:
    rcall debounce_corto  ; Antirrebote
    sbic PIND, 2          ; Verificar si botón sigue presionado
    ret                   ; Si no, retornar
    cpi cont2, 0          ; Comparar con mínimo valor
    breq dec2_done        ; Si es igual, no decrementar
    dec cont2             ; Decrementar contador
dec2_done:
    ret

mostrar_cont2:
    ; Limpiar LEDs previos
    in temp, PORTB        ; Leer PORTB
    andi temp, 0xFE       ; Limpiar PB0
    out PORTB, temp       ; Actualizar PORTB
    
    in temp, PORTD        ; Leer PORTD
    andi temp, 0x1F       ; Limpiar PD7-PD5
    out PORTD, temp       ; Actualizar PORTD
    
    ; Encender LED según valor
    cpi cont2, 0          ; Si es 0
    breq mostrar2_done    ; Todos apagados
    
    cpi cont2, 1          ; Si es 1
    brne try2             ; Si no, probar siguiente
    sbi PORTB, 0          ; Encender PB0
    ret
    
try2:
    cpi cont2, 2          ; Si es 2
    brne try3             ; Si no, probar siguiente
    sbi PORTD, 7          ; Encender PD7
    ret
    
try3:
    cpi cont2, 3          ; Si es 3
    brne try4             ; Si no, probar siguiente
    sbi PORTD, 6          ; Encender PD6
    ret
    
try4:
    cpi cont2, 4          ; Si es 4
    brne mostrar2_done    ; Si no, terminar
    sbi PORTD, 5          ; Encender PD5
mostrar2_done:
    ret

; === RUTINAS SUMA ===
hacer_suma:
    rcall debounce_largo  ; Antirrebote largo
    sbic PINC, 5          ; Verificar si botón sigue presionado
    ret                   ; Si no, retornar
    
    ; Esperar que se suelte el botón
esperar_soltar:
    sbis PINC, 5          ; Si botón soltado
    rjmp esperar_soltar   ; Si no, seguir esperando
    
    ; Realizar suma
    clr result           ; Limpiar resultado previo
    clr carry            ; Limpiar carry
    
    mov result, cont1     ; Cargar primer número
    add result, cont2     ; Sumar segundo número
    brcc no_overflow      ; Si no hay carry, mostrar
    ldi carry, 1         ; Si hay carry, marcar
no_overflow:
    rcall mostrar_suma    ; Mostrar resultado
    
    ; Verificar overflow
    tst carry             ; Probar si hay carry
    breq suma_done        ; Si no hay, terminar
    rcall parpadear       ; Si hay, parpadear
suma_done:
    ret

mostrar_suma:
    ; Limpiar LEDs de resultado
    in temp, PORTB        ; Leer PORTB
    andi temp, 0xDF       ; Limpiar PB5
    out PORTB, temp       ; Actualizar PORTB
    
    in temp, PORTC        ; Leer PORTC
    andi temp, 0xF8       ; Limpiar PC2-PC0
    out PORTC, temp       ; Actualizar PORTC
    
    ; Preparar resultado
    mov temp, result      ; Copiar resultado
    andi temp, 0x0F       ; Mantener solo 4 bits
    
    ; Mostrar bits del resultado
    ; Bit 0 (LSB) -> PB5
    in r21, PORTB         ; Leer PORTB
    andi r21, 0xDF        ; Limpiar PB5
    sbrc temp, 0          ; Si bit 0 es 1
    ori r21, 0x20        ; Encender PB5
    out PORTB, r21        ; Actualizar PORTB
    
    ; Bits 1-3 -> PC0-PC2
    in r21, PORTC         ; Leer PORTC
    andi r21, 0xF8        ; Limpiar PC2-PC0
    sbrc temp, 1          ; Si bit 1 es 1
    ori r21, 0x01        ; Encender PC0
    sbrc temp, 2          ; Si bit 2 es 1
    ori r21, 0x02        ; Encender PC1
    sbrc temp, 3          ; Si bit 3 es 1
    ori r21, 0x04        ; Encender PC2
    out PORTC, r21        ; Actualizar PORTC
    
    ret

; === RUTINAS DE PARPADEO ===
parpadear:
    ldi r21, 3           ; 3 parpadeos
parpadeo_loop:
    rcall mostrar_suma    ; Mostrar resultado
    rcall delay           ; Esperar
    
    ; Apagar LEDs
    in temp, PORTB        ; Limpiar PB5
    andi temp, 0xDF
    out PORTB, temp
    in temp, PORTC        ; Limpiar PC2-PC0
    andi temp, 0xF8
    out PORTC, temp
    
    rcall delay           ; Esperar
    
    dec r21               ; Decrementar contador
    brne parpadeo_loop    ; Si no es cero, continuar
    rcall mostrar_suma    ; Mostrar resultado final
    ret

; === RUTINAS DE RETARDO ===
delay:
    ldi r21, 255         ; Valor para retardo
delay_loop:
    dec r21               ; Decrementar contador
    brne delay_loop       ; Si no es cero, continuar
    ret

; === RUTINAS DE ANTIRREBOTE ===
debounce_corto:
    ldi r21, 20          ; Retardo corto para contadores
debounce_corto_loop:
    dec r21
    brne debounce_corto_loop
    ret

debounce_largo:
    ldi r21, 100         ; Retardo largo para suma
debounce_largo_loop:
    dec r21
    brne debounce_largo_loop
    ret