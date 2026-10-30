// ===============================================================
// Ejercicio 2: "Flores en el jardin - Animacion de Nubes"
// 640x480 (bytes B,G,R,A)
// x0 = base del framebuffer
// Imagen: Tres flores coloridas sobre pasto verde con cielo celeste y nubes blancas
// ===============================================================

        .equ SCREEN_WIDTH,      640
        .equ SCREEN_HEIGHT,     480
        .equ BYTES_PER_PX,      4

        .globl main

// ---------------------------------------------------------------
// pintarpixel(x, y, color)  (x0, x1, x2)  -- usa x20 como base
pintarpixel:
        // Validar límites
        cmp     x0, #0
        blt     1f
        cmp     x0, #SCREEN_WIDTH
        bge     1f
        cmp     x1, #0
        blt     1f
        cmp     x1, #SCREEN_HEIGHT
        bge     1f
        
        // Calcular offset: (y * WIDTH + x) * 4
        mov     x9, #SCREEN_WIDTH
        mul     x9, x1, x9
        add     x9, x9, x0
        lsl     x9, x9, #2
        add     x9, x20, x9
        str     w2, [x9]
        
1:      ret



// crearRectangulo(x, y, width, height, color) - x0, x1, x2, x3, x4
crearRectangulo:
        stp     x29, x30, [sp, #-64]!    //stp guarda los registros para que entre los bucles, sumas y resta no se pierdan 
        stp     x19, x20, [sp, #16]
        stp     x21, x22, [sp, #32]
        stp     x23, x24, [sp, #48]
        
        mov     x19, x0         // x inicial
        mov     x21, x1         // y inicial
        mov     x22, x2         // ancho
        mov     x23, x3         // alto
        mov     x24, x4         // color
        mov     x10, x20        // Guardar framebuffer base
        
        mov     x25, x21        // y actual
        
rellenar_y:
        mov     x26, x19        // x actual
        
rellenar_x:               //va marcando puntito en el eje x hasta que llegye a 320, cuando llegue ahi va a pasar al loop de y y va a repetir el mismo proceso hasta completar todo a lo ancho y alto
        mov     x0, x26    //x[i]    
        mov     x1, x25    //y[i]
        mov     x2, x24
        mov     x20, x10        // Restaurar x20
        bl      pintarpixel
        
        add     x26, x26, #1   // i++
        add     x4, x19, x22 // 640
        cmp     x26, x4    // i <640 ? salta a rellenar_x
        blt     rellenar_x    //si ya x26 no es mas chico que x4=(320) vamos a sumarle uno a x25 =(0) asi pasamos a otra fila de nuestra mastriz y volvemos a repetir lo del loop de x en esa fila 
        
        add     x25, x25, #1
        add     x4, x21, x23
        cmp     x25, x4
        blt     rellenar_y
        
        ldp     x23, x24, [sp, #48]   //al final de todo antes de retornar los carga devuelta para que el main los vea tal cual los envio y no haya cambios
        ldp     x21, x22, [sp, #32]
        ldp     x19, x20, [sp, #16]
        ldp     x29, x30, [sp], #64
        ret

// CirculoRelleno(cx, cy, r, color) - x0, x1, x2, x3
CirculoRelleno:
        stp     x29, x30, [sp, #-80]!
        stp     x19, x20, [sp, #16]
        stp     x21, x22, [sp, #32]
        stp     x23, x24, [sp, #48]
        stp     x25, x26, [sp, #64]
        
        mov     x19, x0         // cx
        mov     x21, x1         // cy
        mov     x22, x2         // r
        mov     x23, x3         // color
        mov     x26, x20        // Guardar framebuffer base
        
        // y = cy - r
        sub     x24, x21, x22
        
cr_rellenar_y:
        // x = cx - r
        sub     x25, x19, x22
        
cr_rellenar_x:
        // Calcular (x - cx)^2 + (y - cy)^2
        sub     x4, x25, x19    // dx = x - cx
        sub     x5, x24, x21    // dy = y - cy
        mul     x4, x4, x4      // dx^2
        mul     x5, x5, x5      // dy^2
        add     x4, x4, x5      // dx^2 + dy^2
        
        // r^2
        mul     x5, x22, x22
        
        // Si distancia <= r^2, dibujar
        cmp     x4, x5
        bgt     cr_saltear
        
        mov     x0, x25
        mov     x1, x24
        mov     x2, x23
        mov     x20, x26        // Restaurar x20 para pintarpixel
        bl      pintarpixel
        
cr_saltear:
        add     x25, x25, #1
        add     x4, x19, x22
        cmp     x25, x4
        ble     cr_rellenar_x
        
        add     x24, x24, #1
        add     x4, x21, x22
        cmp     x24, x4
        ble     cr_rellenar_y
        
        ldp     x25, x26, [sp, #64]
        ldp     x23, x24, [sp, #48]
        ldp     x21, x22, [sp, #32]
        ldp     x19, x20, [sp, #16]
        ldp     x29, x30, [sp], #80
        ret
// crearTriangulo(x, y, base, altura, color)
// Triángulo isósceles apuntando hacia la derecha
crearTriangulo:
        stp     x29, x30, [sp, #-64]!
        stp     x19, x20, [sp, #16]
        stp     x21, x22, [sp, #32]
        stp     x23, x24, [sp, #48]

        mov     x19, x0         // x inicial
        mov     x21, x1         // y inicial (tope)
        mov     x22, x2         // base
        mov     x23, x3         // altura
        mov     x24, x4         // color
        mov     x10, x20        // guardar framebuffer base

        mov     x25, #0         // contador de filas (dy)

tri_y_loop:
        mov     x26, #0         // contador de columnas (dx)
        // calcular límite horizontal (va creciendo con y)
        // ancho = (base * dy) / altura
        mul     x27, x22, x25
        sdiv    x27, x27, x23   // x27 = ancho actual

tri_x_loop:
        mov     x0, x19
        add     x0, x0, x26     // x = x_inicial + dx
        mov     x1, x21
        add     x1, x1, x25     // y = y_inicial + dy
        mov     x2, x24
        mov     x20, x10
        bl      pintarpixel

        add     x26, x26, #1
        cmp     x26, x27
        blt     tri_x_loop

        add     x25, x25, #1
        cmp     x25, x23
        blt     tri_y_loop

        ldp     x23, x24, [sp, #48]
        ldp     x21, x22, [sp, #32]
        ldp     x19, x20, [sp, #16]
        ldp     x29, x30, [sp], #64
        ret

// ===============================================================
// main
// ===============================================================
main:
        stp     x29, x30, [sp, #-16]!
        mov     x20, x0         // Guardar framebuffer base

// ===== CIELO CELESTE (parte superior) =====
        mov     x0, #0
        mov     x1, #0
        mov     x2, #SCREEN_WIDTH
        mov     x3, #320
        movz    w4, 0xA0D0, lsl 0    // Celeste más oscuro
        movk    w4, 0x0055, lsl 16
        bl      crearRectangulo

// ===== PASTO VERDE (parte inferior) =====
        mov     x0, #0
        mov     x1, #320
        mov     x2, #SCREEN_WIDTH
        mov     x3, #160
        movz    w4, 0xAB00, lsl 0    // Verde pasto más claro
        movk    w4, 0x0056, lsl 16
        bl      crearRectangulo

// ===== NUBE IZQUIERDA =====
        // Círculo 1 de la nube
        mov     x0, #100
        mov     x1, #80
        mov     x2, #35
        movz    w3, 0xFFFF, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
        
        // Círculo 2 de la nube
        mov     x0, #140
        mov     x1, #70
        mov     x2, #40
        movz    w3, 0xFFFF, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
        
        // Círculo 3 de la nube
        mov     x0, #180
        mov     x1, #80
        mov     x2, #35
        movz    w3, 0xFFFF, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno

// ===== NUBE DERECHA =====
        // Círculo 1 de la nube
        mov     x0, #480
        mov     x1, #100
        mov     x2, #40
        movz    w3, 0xFFFF, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
        
        // Círculo 2 de la nube
        mov     x0, #530
        mov     x1, #90
        mov     x2, #45
        movz    w3, 0xFFFF, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
        
        // Círculo 3 de la nube
        mov     x0, #575
        mov     x1, #100
        mov     x2, #38
        movz    w3, 0xFFFF, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno

// ===== FLOR IZQUIERDA (ROJA) =====
        // Tallo verde oscuro
        mov     x0, #150
        mov     x1, #320
        mov     x2, #6
        mov     x3, #90
        movz    w4, 0x2B40, lsl 0
        movk    w4, 0x0006, lsl 16

        bl      crearRectangulo
        
        // Centro amarillo
        mov     x0, #150
        mov     x1, #280
        mov     x2, #20
        movz    w3, 0xD700, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
        
        // Pétalo superior
        mov     x0, #150
        mov     x1, #245
        mov     x2, #15
        movz    w3, 0x2020, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
        
        // Pétalo inferior
        mov     x0, #150
        mov     x1, #315
        mov     x2, #15
        movz    w3, 0x2020, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
        
        // Pétalo izquierdo
        mov     x0, #115
        mov     x1, #280
        mov     x2, #15
        movz    w3, 0x2020, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
        
        // Pétalo derecho
        mov     x0, #185
        mov     x1, #280
        mov     x2, #15
        movz    w3, 0x2020, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
        
        // Pétalo diagonal superior izquierdo
        mov     x0, #125
        mov     x1, #255
        mov     x2, #15
        movz    w3, 0x2020, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
        
        // Pétalo diagonal superior derecho
        mov     x0, #175
        mov     x1, #255
        mov     x2, #15
        movz    w3, 0x2020, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
         // Pétalo diagonal inferior izquierdo
        mov     x0, #125
        mov     x1, #305
        mov     x2, #15
        movz    w3, 0x2020, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno

        // Pétalo diagonal inferior derecho
        mov     x0, #175
        mov     x1, #305
        mov     x2, #15
        movz    w3, 0x2020, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno

// Hoja triangular izquierda
        mov     x0, #156        // x inicial (pegado al tallo)
        mov     x1, #350        // y inicial
        mov     x2, #25         // base
        mov     x3, #25         // altura
        movz    w4, 0x2B40, lsl 0
        movk    w4, 0x0006, lsl 16
        bl      crearTriangulo
// ===== FLOR DERECHA (ROJA) =====
        // Tallo verde oscuro
        mov     x0, #490
        mov     x1, #320
        mov     x2, #6
        mov     x3, #100
        movz    w4, 0x2B40, lsl 0
        movk    w4, 0x0006, lsl 16  
        

        bl      crearRectangulo
        
        // Centro amarillo
        mov     x0, #490
        mov     x1, #290
        mov     x2, #22
        movz    w3, 0xD700, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
        
        // Pétalo superior ROJO
        mov     x0, #490
        mov     x1, #250
        mov     x2, #17
        movz    w3, 0x2020, lsl 0    // Rojo
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
        
        // Pétalo inferior ROJO
        mov     x0, #490
        mov     x1, #330
        mov     x2, #17
        movz    w3, 0x2020, lsl 0    // Rojo
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
        
        // Pétalo izquierdo ROJO
        mov     x0, #450
        mov     x1, #290
        mov     x2, #17
        movz    w3, 0x2020, lsl 0    // Rojo
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
        
        // Pétalo derecho ROJO
        mov     x0, #530
        mov     x1, #290
        mov     x2, #17
        movz    w3, 0x2020, lsl 0    // Rojo
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
        
        // Pétalo diagonal superior izquierdo ROJO
        mov     x0, #462
        mov     x1, #262
        mov     x2, #17
        movz    w3, 0x2020, lsl 0    // Rojo
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
        
        // Pétalo diagonal superior derecho ROJO
        mov     x0, #518
        mov     x1, #262
        mov     x2, #17
        movz    w3, 0x2020, lsl 0    // Rojo
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
                // Pétalo diagonal inferior izquierdo ROJO
        mov     x0, #462
        mov     x1, #318
        mov     x2, #17
        movz    w3, 0x2020, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno

        // Pétalo diagonal inferior derecho ROJO
        mov     x0, #518
        mov     x1, #318
        mov     x2, #17
        movz    w3, 0x2020, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno
              
 // Hoja triangular derecha
        mov     x0, #496        // x inicial (pegado al tallo)
        mov     x1, #350        // y inicial
        mov     x2, #25         // base
        mov     x3, #25         // altura
        movz    w4, 0x2B40, lsl 0
        movk    w4, 0x0006, lsl 16
        bl      crearTriangulo



        // Posiciones iniciales de las nubes.
        mov     x19, #100
        mov     x21, #480
        mov     x22, x19
        mov     x23, x21

anim_loop:
        // Borrar las posiciones anteriores sin tocar las flores.
        mov     x0, x22
        mov     x1, #80
        mov     x2, #35
        movz    w4, 0xA0D0, lsl 0
        movk    w4, 0x0055, lsl 16
        mov     w3, w4
        bl      CirculoRelleno

        add     x0, x22, #40
        mov     x1, #70
        mov     x2, #40
        bl      CirculoRelleno

        add     x0, x22, #80
        mov     x1, #80
        mov     x2, #35
        bl      CirculoRelleno

        mov     x0, x23
        mov     x1, #100
        mov     x2, #40
        bl      CirculoRelleno

        add     x0, x23, #50
        mov     x1, #90
        mov     x2, #45
        bl      CirculoRelleno

        add     x0, x23, #95
        mov     x1, #100
        mov     x2, #38
        bl      CirculoRelleno

        // Nube izquierda.
        mov     x0, x19
        mov     x1, #80
        mov     x2, #35
        movz    w3, 0xFFFF, lsl 0
        movk    w3, 0x00FF, lsl 16
        bl      CirculoRelleno

        add     x0, x19, #40
        mov     x1, #70
        mov     x2, #40
        bl      CirculoRelleno

        add     x0, x19, #80
        mov     x1, #80
        mov     x2, #35
        bl      CirculoRelleno

        // Nube derecha.
        mov     x0, x21
        mov     x1, #100
        mov     x2, #40
        bl      CirculoRelleno

        add     x0, x21, #50
        mov     x1, #90
        mov     x2, #45
        bl      CirculoRelleno

        add     x0, x21, #95
        mov     x1, #100
        mov     x2, #38
        bl      CirculoRelleno

        // Retardo simple.
        ldr     x9, =0x200000
delay_loop:
        subs    x9, x9, #1
        b.ne    delay_loop

        // Mover las nubes de izquierda a derecha y reciclarlas.
        mov     x22, x19
        mov     x23, x21
        add     x19, x19, #4
        cmp     x19, #660
        blt     mover_nube_derecha
        mov     x19, #-120

mover_nube_derecha:
        add     x21, x21, #3
        cmp     x21, #660
        blt     anim_loop
        mov     x21, #-130
        b       anim_loop
