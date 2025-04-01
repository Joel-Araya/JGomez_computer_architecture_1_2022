//Código de interpolación bilineal

.data
.balign 1
input_filename: .asciz "input.img"
output_filename: .asciz "output.img"
data_buffer: .space 524288  // Reservar 500KB bytes para el buffer
output_buffer: .space 2097152  // Reservar 2MB bytes para el buffer de salida
temp_pixels: .space 16      // Buffer temporal para palabras, matriz de 4x4
largo: .space 4	//Largo de la imagen
ancho: .space 4	//Ancho de la imagen

.text
.global _start

_start:
    // Abrir el archivo de entrada (input.txt)
    MOV R7, #5         // Número de syscall para sys_open
    LDR R0, =input_filename
    MOV R1, #0         // Flags: O_RDONLY (solo lectura)
    MOV R2, #0         // Permisos (no necesarios aquí)
    SWI 0              // Ejecutar syscall
    MOV R4, R0         // Guardar el descriptor de archivo en R4

    // Leer los datos del archivo de entrada
    MOV R7, #3         // Número de syscall para sys_read
    MOV R0, R4         // Descriptor de archivo (input.txt)
    LDR R1, =data_buffer // Buffer para almacenar los datos leídos
    MOV R2, #524288     // Tamaño del buffer
    SWI 0              // Ejecutar syscall
    MOV R6, R0         // Guardar la cantidad de bytes leídos en R6

    // Cerrar el archivo de entrada
    MOV R7, #6         // Número de syscall para sys_close
    MOV R0, R4         // Descriptor de archivo
    SWI 0              // Ejecutar syscall

    LDR R0, =data_buffer    // Cargar la dirección base del buffer en R0
    LDR R1, =output_buffer    // Cargar la dirección base del buffer temporal en R1
    LDR R2, =temp_pixels   // Cargar la dirección base del buffer temporal en R2

    LDRH R3, [R0]       // Cargar los 2 primeros bytes del archivo en R3, largo

    LDRH R4, [R0, #2]   // Cargar los 2 siguientes bytes del archivo en R4, ancho
    ADD R0, R0, #4      // Incrementar el puntero del buffer en 4 bytes, a partir de aquí se leerán los datos

	//Guardar largo y ancho en variables globales
	LDR R8, =largo
	STR R3, [R8]
	LDR R9, =ancho
	STR R4, [R9]

    //Hasta el momento solo se estan usando los registros R0, R1, R2, R3
    //R0 es el puntero al buffer de datos, quitando los 4 bytes de largo y ancho

    MOV R8, #0              // Inicializar el índice de R8 a 0, pixel x del temp_pixel
    MOV R9, #0              // Inicializar el índice de R9 a 0, pixel y del temp_pixel

    MOV R11, #0             // Contador de X, para el pixel de la imagen completa
    MOV R12, #0             // Contador de Y, para el pixel de la imagen completa

_read_bytes:

    LDR R0, =data_buffer    // Cargar de nuevo la dirección base del buffer en R0
	ADD R0, R0, #4
    LDR R1, =output_buffer    // Cargar de nuevo la dirección base del buffer temporal en R1
	LDR R10, =largo
	LDR R3, [R10]
	LDR R5, =ancho
	LDR R4, [R5]
	DSB            // Asegurar que la escritura se complete

    //Posicion del pixel de la imagen original, cuando llega a largo-1, ancho-1, es la ultima posicion
    //Agarro los pixeles (x,y), (x+1,y), (x,y+1), (x+1,y+1)

    MUL R10, R12, R3       // Multiplicar el contador de Y por el largo
    ADD R10, R10, R11       // Sumar el contador de X

    //Guardar esquinas de la imagen original en temp_pixel
    LDRB R5, [R0, R10]      // Cargar el byte en la posición (R0 + R10) en R5
    STRB R5, [R2]           // Guardar el byte en la posición (0,0) de temp_pixel
	DSB            // Asegurar que la escritura se complete

    ADD R10, R10, #1
    LDRB R5, [R0, R10]      // Cargar el byte en la posición (R0 + R10 + 1) en R5
    STRB R5, [R2, #3]       // Guardar el byte en la posición (0,3) de temp_pixel
	DSB            // Asegurar que la escritura se complete

    ADD R10, R10, R3		//Al sumarle el largo bajo una posición de la matriz
	SUB R10, R10, #1		//Restamos 1 para obtener la posición (x,y+1)
    LDRB R5, [R0, R10]      // Cargar el byte en la posición (R0 + R10) en R5
    STRB R5, [R2, #12]      // Guardar el byte en la posición (3,0) de temp_pixel
	DSB            // Asegurar que la escritura se complete

    ADD R10, R10, #1
    LDRB R5, [R0, R10]      // Cargar el byte en la posición (R0 + R10) en R5
    STRB R5, [R2, #15]      // Guardar el byte en la posición (3,3) de temp_pixel
	DSB            // Asegurar que la escritura se complete




_bilinear_interpolation:


	//Posicion de esquina (0,0) y (0,3)
	MOV R0, #0	//Posicion de (0,0)
	MOV R1, #12 //Posicion de (3,0)
	bl _get_lateral_values	//Guarda en R5 y R6 los valores de posición en el array temp_pixel, segun R0 y R1


	//Calculamos primero los valores verticales (0,1), (0,2), (3,1), (3,2)

	//Calculamos las pocisiones de (0,1)
	MOV R3, #4
	bl _bilinear_interpolation_equation

	//Calculamos las pocisiones de (0,2)
	MOV R3, #8
	bl _bilinear_interpolation_equation

	//Posicion de esquina (0,0) y (0,3)
	MOV R0, #3	//Posicion de (0,0)
	MOV R1, #15 //Posicion de (3,0)
	bl _get_lateral_values	//Guarda en R5 y R6 los valores de posición en el array temp_pixel, segun R0 y R1


	//Calculamos las pocisiones de (3,1)
	MOV R3, #7
	bl _bilinear_interpolation_equation

	//Calculamos las pocisiones de (3,2)
	MOV R3, #11
	bl _bilinear_interpolation_equation


_bilinear_interpolation_x_values:
	//Posicion de esquina (0,0) y (3,0)
	MOV R0, #0	//Posicion de (0,0)
	MOV R1, #3  //Posicion de (3,0)

	MOV R3, #1

_loop:
	bl _get_lateral_values	//Guarda en R5 y R6 los valores de posición en el array temp_pixel, segun R0 y R1

	//Calculamos las pocision inicial (primera ejecución es R3 es 1, pos (1,0))
	bl _bilinear_interpolation_equation

	//Calculamos las segunda posición (segunda ejecución es R3 es 2, pos (2,0))
	ADD R3, R3, #1
	bl _bilinear_interpolation_equation


	CMP R3, #14  // Ultima posición que falta es la 14
    BEQ _save_interpolated_pixels  

	//Actualizamos laterales con +4 en R0 y R1
	ADD R0, R0, #4
	ADD R1, R1, #4
	ADD R3, R3, #3	//Incrementamos R3 para la siguiente iteración

	B _loop

_save_interpolated_pixels:
	//Los pixeles se deben acomodar siguiendo la posición del pixel de la imagen original
	// R11 es X de la imagen original, R12 el Y
	// Pasos:

	//Constante 3 para multiplicar
	MOV R7, #3
	

	//Cargar el largo y ancho de la imagen original
	LDR R5, =largo
	LDR R3, [R5]
	LDR R6, =ancho
	LDR R4, [R6]
	DSB            // Asegurar que la escritura se complete

	//Obtener los nuevos valores de largo y ancho en R0 y R1, original*3-2
	MUL R0, R3, R7
	Mul R1, R4, R7
	SUB R0, R0, #2	//R0 es el nuevo largo
	SUB R1, R1, #2  //R1 es el nuevo ancho


	//Cargar output_buffer en R6
	LDR R6, =output_buffer

	//En R10 calculo la dirección del primer pixel de la nueva imagen segun R11 y R12
	//El nuevo pixel queda en X_original*3, Y_original*3
	MUL R8, R11, R7
	MUL R9, R12, R7

	//Con R8, R9 y el nuevo largo calculo la dirección del pixel en la nueva imagen
	MUL R10, R9, R0		//Y*Largo_nuevo
	ADD R10, R10, R8	// + X

	ADD R10, R6, R10 //Sumo la dirección de output_buffer



	MOV R9, #0              // Inicializar el índice de R9 a 0, pixel y del temp_pixel

reset_x:
	MOV R8, #0 //Contador de iteraciones en columna, pixel x

_save_interpolated_pixels_loop:

	CMP R8, #4
	BEQ _add_y

	CMP R9, #4
	BEQ _next_pixel

	MOV R4, #4 //Largo de la temp_pixel
	MUL R5, R9, R4
	ADD R5, R5, R8			//Posición en temp_pixel, del array de 4x4

	//Cargar pixel de temp_pixel en R3
	LDRB R3, [R2, R5]

	//Guardar pixel en la nueva imagen (R10)

	MUL R5, R9, R0			//Si aumenta 1 en y,debo aumentar en largo_nuevo posiciones de memoria, 1 fila
	ADD R5, R5, R8			//Posición en temp_pixel, del array de 4x4

	STRB R3, [R10, R5]		//Guardo el pixel en la nueva imagen
	DSB			// Asegurar que la escritura se complete

	ADD R8, R8, #1
	B _save_interpolated_pixels_loop

_add_y:
	ADD R9, R9, #1
	B reset_x	


_next_pixel:
	//Cargar el largo y ancho de la imagen original
	LDR R5, =largo
	LDRH R3, [R5]
	LDR R6, =ancho
	LDRH R4, [R6]
	DSB            // Asegurar que la escritura se complete

	//Incrementar el contador de X
	ADD R11, R11, #1
	SUB R3, R3, #1
	CMP R11, R3
	BNE _read_bytes

	//Incrementar el contador de Y
	ADD R12, R12, #1
	SUB R4, R4, #1
	MOV R11, #0		//Reiniciar el contador de X
	CMP R12, R4
	BGE _save_img
	B _read_bytes

_save_img:
	// Abrir el archivo de salida (output.txt)
	MOV R7, #5         // Número de syscall para sys_open
	LDR R0, =output_filename
	MOV R1, #65        // Flags: O_CREAT | O_WRONLY | O_TRUNC
	MOV R2, #0         // Permisos (no necesarios aquí)
	SWI 0              // Ejecutar syscall
	MOV R4, R0         // Guardar el descriptor de archivo en R4

	// Escribir los datos en el archivo de salida
	MOV R7, #4         // Número de syscall para sys_write
	MOV R0, R4         // Descriptor de archivo (output.txt)
	LDR R1, =output_buffer // Buffer con los datos a escribir
	MOV R2, #2097152         // Cantidad de bytes a escribir
	SWI 0              // Ejecutar syscall

	// Cerrar el archivo de salida
	MOV R7, #6         // Número de syscall para sys_close
	MOV R0, R4         // Descriptor de archivo
	SWI 0              // Ejecutar syscall

	B _end


_end:
    // Terminar el programa
    MOV R7, #1         // Número de syscall para sys_exit
    MOV R0, #0         // Código de salida
    SWI 0              // Ejecutar syscall

_get_lateral_values:
	LDRB R5, [R2, R0]      // Cargar el byte en la posición (0,0) de temp_pixel en R5
	LDRB R6, [R2, R1]      // Cargar el byte en la posición (0,3) de temp_pixel en R6

	MOV PC, LR

_bilinear_interpolation_equation:
	//PixelX = (x2-x)/(x2-x1)*R5 + (x-x1)/(x2-x1)*R6
	//PixelY = (y2-y)/(y2-y1)*R5 + (y-y1)/(y2-y1)*R6		//Es la misma para ambos casos, solo cambia la posición de los bytes

	//R7 = (R1-R3)/(R1-R0)*R5 + (R3-R0)/(R1-R0)*R6
	//Factorizando R7 = [(R1-R3)*R5 + (R3-R0)*R6]/(R1-R0)
	SUB R10, R1, R3
	MUL R7, R10, R5

	SUB R10, R3, R0
	MUL R4, R10, R6				//R4 haciendo de auxiliar

	ADD R7, R7, R4

	SUB R10, R1, R0
	SDIV R7, R7, R10

	//SDIV R4, R4, R10


	STRB R7, [R2, R3]           // Guardar el byte en la posición (0,1) de temp_pixel 
	DSB            				// Asegurar que la escritura se complete

	MOV PC, LR


_reset_temp_pixel:
	// Resetear todos los bytes de temp_pixel a 0 con str
	MOV R10, #0
	STRB R10, [R2]
	STRB R10, [R2, #4]
	STRB R10, [R2, #8]
	STRB R10, [R2, #12]

	MOV PC, LR


