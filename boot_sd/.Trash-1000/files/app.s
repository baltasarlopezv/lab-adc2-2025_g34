.globl app
app:
    mov x20, x0             // x20 = Dirección base del FrameBuffer

    // 1. Inicializar periféricos GPIO (LEDs y Pulsadores)
    bl gpio_init

    // 2. Encender LED Rojo al iniciar el juego (requisito Ej. 2)
    bl encender_led_rojo

    // 3. Dibujar fondo estático y laberinto
    bl dibujar_fondo
    bl dibujar_laberinto

    // 4. Posición inicial del personaje (Centro X=65, Y=58)
    mov x21, #65            // x21 = Posición X actual
    mov x22, #58            // x22 = Posición Y actual
    bl dibujar_personaje

game_loop:
    // Leer estado de los pulsadores
    bl leer_pulsadores      // Retorna estado en w0

    // Mapeo de botones según la placa de laboratorio:
    // GPIO 14: Arriba
    // GPIO 15: Abajo
    // GPIO 17: Izquierda
    // GPIO 18: Derecha

    mov x25, x21            // Guardar posición previa X
    mov x26, x22            // Guardar posición previa Y

    // Chequear GPIO 17 (Izquierda) -> bit 17
    tbz w0, #17, check_right
    sub x21, x21, #4        // Mover a la izquierda
    b avaliar_movimiento

check_right:
    // Chequear GPIO 18 (Derecha) -> bit 18
    tbz w0, #18, check_up
    add x21, x21, #4        // Mover a la derecha
    b avaliar_movimiento

check_up:
    // Chequear GPIO 14 (Arriba) -> bit 14
    tbz w0, #14, check_down
    sub x22, x22, #4        // Mover arriba
    b avaliar_movimiento

check_down:
    // Chequear GPIO 15 (Abajo) -> bit 15
    tbz w0, #15, no_input
    add x22, x22, #4        // Mover abajo
    b avaliar_movimiento

no_input:
    b game_loop

avaliar_movimiento:
    // Validar colisión con paredes del laberinto en la nueva posición (x21, x22)
    bl verificar_colision
    cbnz x0, colision_detectada

    // Si no hay colisión, borrar personaje en posición anterior y redibujar en la nueva
    mov x1, x25
    mov x2, x26
    bl borrar_personaje

    mov x1, x21
    mov x2, x22
    bl dibujar_personaje

    // Verificar si alcanzó la meta (Salida inferior: X entre 262 y 325, Y >= 465)
    cmp x22, #465
    b.lt delay_game
    cmp x21, #262
    b.lt delay_game
    cmp x21, #325
    b.gt delay_game

    // ¡Meta alcanzada! Encender LED verde y apagar LED rojo
    bl encender_led_verde
    bl apagar_led_rojo

delay_game:
    // Retardo para suavizar la velocidad de desplazamiento
    movz x11, 0x08, lsl #16
delay_mov:
    sub x11, x11, #1
    cbnz x11, delay_mov
    b game_loop

colision_detectada:
    // Si hubo colisión, revertir a la posición anterior
    mov x21, x25
    mov x22, x26
    b game_loop


//------------------------------------------------------------------------------
// verificar_colision: Comprueba si el rectángulo contenedores del personaje
// colisiona con el color de las paredes (0x1082) u bordes.
// Retorna x0 = 1 si hay colisión, x0 = 0 si el camino está libre.
//------------------------------------------------------------------------------
verificar_colision:
    // Tomar los extremos del bounding box del personaje alrededor de (x21, x22)
    sub x7, x21, #10        // X min
    add x8, x21, #10        // X max
    sub x9, x22, #20        // Y min
    add x10, x22, #15       // Y max

    // Verificación de límites de pantalla
    cmp x7, #22
    b.lt col_true
    cmp x8, #490
    b.ge col_true
    cmp x9, #22
    b.lt col_true
    cmp x10, #478
    b.ge col_true

    // Muestrear esquinas y centro inferior para muros (color 0x1082)
    mov x1, x7
    mov x2, x9
    bl leer_pixel_color
    movz x4, #0x1082
    cmp x3, x4
    b.eq col_true

    mov x1, x8
    mov x2, x9
    bl leer_pixel_color
    cmp x3, x4
    b.eq col_true

    mov x1, x7
    mov x2, x10
    bl leer_pixel_color
    cmp x3, x4
    b.eq col_true

    mov x1, x8
    mov x2, x10
    bl leer_pixel_color
    cmp x3, x4
    b.eq col_true

    mov x0, #0              // Sin colisión
    ret
col_true:
    mov x0, #1              // Colisión detectada
    ret


//------------------------------------------------------------------------------
// leer_pixel_color: Retorna en x3 el color de 16 bits del píxel en (x1, x2)
//------------------------------------------------------------------------------
leer_pixel_color:
    lsl x9, x2, #9
    add x9, x9, x1
    lsl x9, x9, #1
    add x10, x20, x9
    ldrh w3, [x10]
    ret


//------------------------------------------------------------------------------
// borrar_personaje: Pinta el área ocupada por el personaje con el color del piso (0xF79E)
//------------------------------------------------------------------------------
borrar_personaje:
    mov x28, x30
    sub x1, x1, #15
    sub x2, x2, #24
    movz w3, #0xF79E        // Color de fondo del pasillo (crema)
    mov x4, #31
    mov x5, #44
    bl dibujar_rectangulo
    mov x30, x28
    ret


//==============================================================================
// INCLUSIÓN DE PROCEDIMIENTOS GRÁFICOS (Mismos del Ejercicio 1)
//==============================================================================
dibujar_pixel:
    cmp x1, #0
    b.lt pixel_fin
    cmp x1, #512
    b.ge pixel_fin
    cmp x2, #0
    b.lt pixel_fin
    cmp x2, #512
    b.ge pixel_fin
    lsl x9, x2, #9
    add x9, x9, x1
    lsl x9, x9, #1
    add x10, x20, x9
    sturh w3, [x10]
pixel_fin:
    ret

dibujar_rectangulo:
    mov x28, x30
    cmp x4, #0
    b.le rect_fin
    cmp x5, #0
    b.le rect_fin
    mov x11, x1
    add x12, x1, x4
    add x13, x2, x5
rect_loop_y:
    cmp x2, x13
    b.ge rect_fin
    mov x1, x11
rect_loop_x:
    cmp x1, x12
    b.ge rect_next_y
    bl dibujar_pixel
    add x1, x1, #1
    b rect_loop_x
rect_next_y:
    add x2, x2, #1
    b rect_loop_y
rect_fin:
    mov x30, x28
    ret

dibujar_circulo:
    mov x28, x30
    mov x11, x1
    mov x12, x2
    mov x13, x4
    mul x14, x13, x13
    sub x15, xzr, x13
circ_loop_y:
    cmp x15, x13
    b.gt circ_fin
    sub x16, xzr, x13
circ_loop_x:
    cmp x16, x13
    b.gt circ_next_y
    mul x17, x16, x16
    mul x9, x15, x15
    add x17, x17, x9
    cmp x17, x14
    b.gt circ_skip_pixel
    add x1, x11, x16
    add x2, x12, x15
    bl dibujar_pixel
circ_skip_pixel:
    add x16, x16, #1
    b circ_loop_x
circ_next_y:
    add x15, x15, #1
    b circ_loop_y
circ_fin:
    mov x30, x28
    ret

dibujar_triangulo:
    mov x28, x30
    mov x11, x1
    mov x12, x2
    mov x13, x4
    mov x14, #0
tri_loop_y:
    cmp x14, x13
    b.ge tri_fin
    lsr x15, x14, #1
    add x15, x14, x15
    sub x16, x11, x15
    add x17, x11, x15
    add x2, x12, x14
    mov x1, x16
tri_loop_x:
    cmp x1, x17
    b.gt tri_next_y
    bl dibujar_pixel
    add x1, x1, #1
    b tri_loop_x
tri_next_y:
    add x14, x14, #1
    b tri_loop_y
tri_fin:
    mov x30, x28
    ret

dibujar_fondo:
    mov x29, x30
    mov x1, #0
    mov x2, #0
    movz w3, #0xA388
    mov x4, #512
    mov x5, #512
    bl dibujar_rectangulo
    mov x1, #6
    mov x2, #6
    movz w3, #0xD5B0
    mov x4, #500
    mov x5, #500
    bl dibujar_rectangulo
    mov x1, #16
    mov x2, #16
    movz w3, #0x7264
    mov x4, #480
    mov x5, #480
    bl dibujar_rectangulo
    mov x1, #22
    mov x2, #22
    movz w3, #0xF79E
    mov x4, #468
    mov x5, #468
    bl dibujar_rectangulo
    mov x23, #34
fondo_tex_h:
    cmp x23, #478
    b.ge fondo_tex_v_init
    mov x1, #34
    mov x2, x23
    movz w3, #0xDF1B
    mov x4, #444
    mov x5, #1
    bl dibujar_rectangulo
    add x23, x23, #19
    b fondo_tex_h
fondo_tex_v_init:
    mov x23, #34
fondo_tex_v:
    cmp x23, #478
    b.ge fondo_fin
    mov x1, x23
    mov x2, #34
    movz w3, #0xDF1B
    mov x4, #1
    mov x5, #444
    bl dibujar_rectangulo
    add x23, x23, #19
    b fondo_tex_v
fondo_fin:
    mov x30, x29
    ret

dibujar_laberinto:
    mov x29, x30
    mov x1, #262
    mov x2, #478
    movz w3, #0x2589
    mov x4, #64
    mov x5, #12
    bl dibujar_rectangulo
    movz w3, #0x1082
    mov x1, #22
    mov x2, #22
    mov x4, #468
    mov x5, #12
    bl dibujar_rectangulo
    mov x1, #22
    mov x2, #22
    mov x4, #12
    mov x5, #468
    bl dibujar_rectangulo
    mov x1, #478
    mov x2, #22
    mov x4, #12
    mov x5, #468
    bl dibujar_rectangulo
    mov x1, #22
    mov x2, #478
    mov x4, #240
    mov x5, #12
    bl dibujar_rectangulo
    mov x1, #326
    mov x2, #478
    mov x4, #164
    mov x5, #12
    bl dibujar_rectangulo
    mov x1, #174
    mov x2, #98
    mov x4, #316
    mov x5, #12
    bl dibujar_rectangulo
    mov x1, #22
    mov x2, #174
    mov x4, #164
    mov x5, #12
    bl dibujar_rectangulo
    mov x1, #326
    mov x2, #174
    mov x4, #88
    mov x5, #12
    bl dibujar_rectangulo
    mov x1, #98
    mov x2, #250
    mov x4, #88
    mov x5, #12
    bl dibujar_rectangulo
    mov x1, #250
    mov x2, #250
    mov x4, #164
    mov x5, #12
    bl dibujar_rectangulo
    mov x1, #22
    mov x2, #326
    mov x4, #240
    mov x5, #12
    bl dibujar_rectangulo
    mov x1, #326
    mov x2, #326
    mov x4, #88
    mov x5, #12
    bl dibujar_rectangulo
    mov x1, #98
    mov x2, #402
    mov x4, #164
    mov x5, #12
    bl dibujar_rectangulo
    mov x1, #98
    mov x2, #22
    mov x4, #12
    mov x5, #88
    bl dibujar_rectangulo
    mov x1, #174
    mov x2, #250
    mov x4, #12
    mov x5, #88
    bl dibujar_rectangulo
    mov x1, #250
    mov x2, #98
    mov x4, #12
    mov x5, #88
    bl dibujar_rectangulo
    mov x1, #250
    mov x2, #250
    mov x4, #12
    mov x5, #240
    bl dibujar_rectangulo
    mov x1, #326
    mov x2, #326
    mov x4, #12
    mov x5, #164
    bl dibujar_rectangulo
    mov x1, #402
    mov x2, #174
    mov x4, #12
    mov x5, #88
    bl dibujar_rectangulo
    mov x1, #402
    mov x2, #326
    mov x4, #12
    mov x5, #88
    bl dibujar_rectangulo
    mov x30, x29
    ret

dibujar_personaje:
    mov x29, x30
    mov x1, x21
    mov x2, x22
    movz w3, #0x1082
    mov x4, #11
    bl dibujar_circulo
    mov x1, x21
    mov x2, x22
    movz w3, #0xFFDF
    mov x4, #8
    bl dibujar_circulo
    mov x1, x21
    sub x2, x22, #19
    movz w3, #0x1082
    mov x4, #14
    bl dibujar_triangulo
    sub x1, x21, #4
    add x2, x22, #1
    movz w3, #0x1082
    mov x4, #1
    bl dibujar_circulo
    add x1, x21, #4
    add x2, x22, #1
    movz w3, #0x1082
    mov x4, #1
    bl dibujar_circulo
    sub x1, x21, #8
    add x2, x22, #13
    movz w3, #0x1082
    mov x4, #17
    mov x5, #13
    bl dibujar_rectangulo
    sub x1, x21, #8
    add x2, x22, #22
    movz w3, #0xD882
    mov x4, #17
    mov x5, #2
    bl dibujar_rectangulo
    sub x1, x21, #13
    add x2, x22, #13
    movz w3, #0x1082
    mov x4, #4
    mov x5, #10
    bl dibujar_rectangulo
    add x1, x21, #10
    add x2, x22, #13
    movz w3, #0x1082
    mov x4, #4
    mov x5, #10
    bl dibujar_rectangulo
    sub x1, x21, #7
    add x2, x22, #27
    movz w3, #0x1082
    mov x4, #5
    mov x5, #7
    bl dibujar_rectangulo
    add x1, x21, #3
    add x2, x22, #27
    movz w3, #0x1082
    mov x4, #5
    mov x5, #7
    bl dibujar_rectangulo
    mov x30, x29
    ret
