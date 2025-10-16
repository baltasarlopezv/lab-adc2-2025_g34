// ===============================================================
// Ejercicio 1: "Flores en el jardin"
// 640x480, XRGB8888 little-endian (bytes B,G,R,A)
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



// ---------------------------------------------------------------
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
        
        ldp     x23, x24, [sp, #48]    /al final de todo antes de retornar los carga devuelta para que el main los vea tal cual los envio y no haya cambios
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

// ---------------------------------------------------------------
InfLoop:
        b       InfLoop

        