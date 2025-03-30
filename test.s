//Código de interpolación bilineal

.data
.balign 1
input_filename: .asciz "input.img"
output_filename: .asciz "output.img"
data_buffer: .space 500000  // Reservar 500KB bytes para el buffer
output_buffer: .space 2000000  // Reservar 2MB bytes para el buffer de salida
temp_pixels: .space 16      // Buffer temporal para palabras, matriz de 4x4
largo: .space 2	//Largo de la imagen
ancho: .space 2	//Ancho de la imagen

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
	STRH R3, [R8]
	LDR R9, =ancho
	STRH R4, [R9]

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
	LDRH R3, [R10]
	LDR R5, =ancho
	LDRH R4, [R5]
	DSB            // Asegurar que la escritura se complete

    //Posicion del pixel de la imagen original, cuando llega a largo-1, ancho-1, es la ultima posicion
    //Agarro los pixeles (x,y), (x+1,y), (x,y+1), (x+1,y+1)

    MUL R10, R12, R2       // Multiplicar el contador de Y por el largo
    ADD R10, R10, R11       // Sumar el contador de X

    //Guardar esquinas de la imagen original en temp_pixel
    LDRB R5, [R0, R10]      // Cargar el byte en la posición (R0 + R10) en R5
    STRB R5, [R2]           // Guardar el byte en la posición (0,0) de temp_pixel
	DSB            // Asegurar que la escritura se complete

    ADD R10, R10, #1
    LDRB R5, [R0, R10]      // Cargar el byte en la posición (R0 + R10 + 1) en R5
    STRB R5, [R2, #3]       // Guardar el byte en la posición (0,3) de temp_pixel
	DSB            // Asegurar que la escritura se complete

    ADD R10, R10, R3
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
	
	//LDRB R5, [R2, R0]      // Cargar el byte en la posición (0,0) de temp_pixel en R5
	//LDRB R6, [R2, R1]      // Cargar el byte en la posición (0,3) de temp_pixel en R6

	bl _get_lateral_values	//Guarda en R5 y R6 los valores de posición en el array temp_pixel, segun R0 y R1


	//Calculamos primero los valores verticales (0,1), (0,2), (3,1), (3,2)

	//Calculamos las pocisiones de (0,1)
	MOV R8, #0
	MOV R9, #1
	
	
	bl _bilinear_interpolation_equation

	//Calculamos las pocisiones de (0,2)
	MOV R8, #0
	MOV R9, #2

	bl _bilinear_interpolation_equation

	//Calculamos las pocisiones de (3,1)
	MOV R8, #3
	MOV R9, #1

	bl _bilinear_interpolation_equation

	//Calculamos las pocisiones de (3,2)
	MOV R8, #3
	MOV R9, #2

	bl _bilinear_interpolation_equation


_bilinear_interpolation_x_values:
	//Posicion de esquina (0,0) y (3,0)
	MOV R0, #0	//Posicion de (0,0)
	MOV R1, #3  //Posicion de (3,0)
	bl _get_lateral_values	//Guarda en R5 y R6 los valores de posición en el array temp_pixel, segun R0 y R1

	//Calculamos las pocisiones de (1,0)
	MOV R8, #1
	MOV R9, #0
	bl _bilinear_interpolation_equation

	//Calculamos las pocisiones de (2,0)
	MOV R8, #2
	MOV R9, #0
	bl _bilinear_interpolation_equation

	//Actualizamos laterales con +4 en R0 y R1
	ADD R0, R0, #4
	ADD R1, R1, #4
	bl _get_lateral_values	//Guarda en R5 y R6 los valores de posición en el array temp_pixel, segun R0 y R1


	//Calculamos las pocisiones de (1,1)
	MOV R8, #1
	MOV R9, #1
	bl _bilinear_interpolation_equation

	//Calculamos las pocisiones de (2,1)
	MOV R8, #2
	MOV R9, #1
	bl _bilinear_interpolation_equation

	//Actualizamos laterales con +4 en R0 y R1
	ADD R0, R0, #4
	ADD R1, R1, #4
	bl _get_lateral_values	//Guarda en R5 y R6 los valores de posición en el array temp_pixel, segun R0 y R1

	//Calculamos las pocisiones de (1,2)
	MOV R8, #1
	MOV R9, #2
	bl _bilinear_interpolation_equation

	//Calculamos las pocisiones de (2,2)
	MOV R8, #2
	MOV R9, #2
	bl _bilinear_interpolation_equation

	// Actualizamos laterales con +4 en R0 y R1
	MOV R0, #1	//Posicion de (1,0)
	MOV R1, #2  //Posicion de (2,0)
	bl _get_lateral_values	//Guarda en R5 y R6 los valores de posición en el array temp_pixel, segun R0 y R1

	//Calculamos las pocisiones de (1,3)
	MOV R8, #1
	MOV R9, #3
	bl _bilinear_interpolation_equation

	//Calculamos las pocisiones de (2,3)
	MOV R8, #2
	MOV R9, #3
	bl _bilinear_interpolation_equation



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
	// Calculamos la pos del pixel en temp_pixel
	MOV R4, #4
	MUL R3, R9, R4
	ADD R3, R3, R8


	//Pixel = (y2-y)/(y2-y1)*R5 + (y-y1)/(y2-y1)*R6
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


