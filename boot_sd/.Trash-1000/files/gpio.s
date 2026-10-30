.globl gpio_init
.globl leer_pulsadores
.globl encender_led_rojo
.globl apagar_led_rojo
.globl encender_led_verde
.globl apagar_led_verde

// Definiciones de registros y offsets de GPIO (Base: 0x3F200000)
.equ GPIO_BASE,     0x3F200000
.equ GPFSEL0,       0x00
.equ GPFSEL1,       0x04
.equ GPSET0,        0x1C
.equ GPCLR0,        0x28
.equ GPLEV0,        0x34

// Máscaras de bits para los GPIOs de la placa de pulsadores y LEDs
.equ LED_VERDE_BIT, (1 << 2)   // GPIO 2
.equ LED_ROJO_BIT,  (1 << 3)   // GPIO 3
.equ BTN_14_BIT,    (1 << 14)  // GPIO 14
.equ BTN_15_BIT,    (1 << 15)  // GPIO 15
.equ BTN_17_BIT,    (1 << 17)  // GPIO 17
.equ BTN_18_BIT,    (1 << 18)  // GPIO 18

//------------------------------------------------------------------------------
// gpio_init: Configura GPIO 2 y 3 como salida (001), y GPIO 14, 15, 17, 18 como entrada (000)
//------------------------------------------------------------------------------
gpio_init:
    ldr x10, =GPIO_BASE

    // Configurar GPFSEL0 para GPIO 2 y 3 como salida
    ldr w11, [x10, #GPFSEL0]
    mov w12, #(7 << 6)          // Limpiar bits de GPIO 2
    mov w13, #(7 << 9)          // Limpiar bits de GPIO 3
    bic w11, w11, w12
    bic w11, w11, w13
    mov w12, #(1 << 6)          // Salida (001) en GPIO 2
    mov w13, #(1 << 9)          // Salida (001) en GPIO 3
    orr w11, w11, w12
    orr w11, w11, w13
    str w11, [x10, #GPFSEL0]

    // Configurar GPFSEL1 para GPIO 14, 15, 17 y 18 como entrada (000)
    ldr w11, [x10, #GPFSEL1]
    mov w12, #(7 << 12)         // GPIO 14
    mov w13, #(7 << 15)         // GPIO 15
    mov w14, #(7 << 21)         // GPIO 17
    mov w15, #(7 << 24)         // GPIO 18
    bic w11, w11, w12
    bic w11, w11, w13
    bic w11, w11, w14
    bic w11, w11, w15
    str w11, [x10, #GPFSEL1]
    ret

//------------------------------------------------------------------------------
// leer_pulsadores: Devuelve en w0 el estado actual de los pines (GPLEV0)
//------------------------------------------------------------------------------
leer_pulsadores:
    ldr x10, =GPIO_BASE
    ldr w0, [x10, #GPLEV0]
    ret

//------------------------------------------------------------------------------
// Control de LEDs (Activos por bajo: GPCLR enciende, GPSET apaga)
//------------------------------------------------------------------------------
encender_led_rojo:
    ldr x10, =GPIO_BASE
    mov w11, #LED_ROJO_BIT
    str w11, [x10, #GPCLR0]
    ret

apagar_led_rojo:
    ldr x10, =GPIO_BASE
    mov w11, #LED_ROJO_BIT
    str w11, [x10, #GPSET0]
    ret

encender_led_verde:
    ldr x10, =GPIO_BASE
    mov w11, #LED_VERDE_BIT
    str w11, [x10, #GPCLR0]
    ret

apagar_led_verde:
    ldr x10, =GPIO_BASE
    mov w11, #LED_VERDE_BIT
    str w11, [x10, #GPSET0]
    ret