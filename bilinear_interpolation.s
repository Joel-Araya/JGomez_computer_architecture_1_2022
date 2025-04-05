//Código de interpolación bilineal

.data
.balign 1
input_filename: .asciz "input.img"
output_filename: .asciz "output.img"
data_buffer: .space 524288  // Reservar 500KB bytes para el buffer
output_buffer: .space 8388608  // Reservar 8MB bytes para el buffer de salida
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

    LDRH R2, [R0]       // Cargar los 2 primeros bytes del archivo en R3, largo
    LDRH R3, [R0, #2]   // Cargar los 2 siguientes bytes del archivo en R4, ancho

    ADD R0, R0, #4      // Incrementar el puntero del buffer en 4 bytes, a partir de aquí se leerán los datos

	//Guardar largo y ancho en variables globales
	LDR R4, =largo
	STR R2, [R4]	//R2 es el largo
	LDR R5, =ancho
	STR R3, [R5]	//R3 es el ancho

	//Calcular dimensiones de la nueva imagen, nueva dimension = original*3-2
	MOV R6, #3		//Constante 3 para multiplicar
	MUL R4, R2, R6  
	Mul R5, R3, R6  
	SUB R4, R4, #2	//R4 es el nuevo largo
	SUB R5, R5, #2  //R5 es el nuevo ancho


    //Hasta el momento solo se estan usando los registros R0 al R6
    //R0 es el puntero al buffer de datos, quitando los 4 bytes de largo y ancho

	MOV R7, #0              // 
    MOV R8, #0              // 
    MOV R9, #0              // 
	MOV R10, #0             //

    MOV R11, #0             // Contador de X, para el pixel de la imagen original
    MOV R12, #0             // Contador de Y, para el pixel de la imagen original

_reset_x:
	MOV R11, #0 //Contador de iteraciones en columna, pixel x

_read_bytes:
	

	//En R7 guardo la posición de la imagen original en el buffer
	MUL R7, R12, R2       // Multiplicar el contador de Y (R12) por el largo (R2)
	ADD R7, R7, R11       // Sumar el contador de X, la posición en la imagen original
	ADD R7, R7, R0		  // Sumar la dirección base del buffer

	// En R8 guardo la posición del pixel en la nueva imagen
	//Primero calulamos la X y Y de la nueva imagen, solo *3

	MUL R9, R11, R6		//R9 es la posición en X de la imagen nueva
	MUL R10, R12, R6		//R10 es la posición en Y de la imagen nueva

	//Con R9, R10 y el nuevo largo calculo la dirección del pixel en la nueva imagen
	MUL R8, R10, R4		//Y_new*Largo_nuevo
	ADD R8, R8, R9		// + X_new
	ADD R8, R1, R8 //Sumo la dirección de output_buffer, R8 aquí es la dirección del pixel en la nueva imagen

	//Cargo en R9 el pixel de la imagen original
	LDRB R9, [R7]      // Cargar el byte en la posición (R7) en R9

	//Guardar el pixel de la imagen original en output_buffer
	STRB R9, [R8]           // Guardar el byte en la posición (R8) de la nueva imagen

	//Incrementar el contador de X
	ADD R11, R11, #1

	//Comparo si X (R11) es igual al largo de la imagen original
	CMP R11, R3
	BLT _read_bytes

	//Incrementar el contador de Y
	ADD R12, R12, #1

	//Comparo si Y (R12) es igual al ancho de la imagen original
	CMP R12, R2
	BLT _reset_x

	B _bilinear_interpolation


_bilinear_interpolation:
	LDR R0, =output_buffer	//Cargar la dirección base del buffer en R0
	MOV R1, R4				//R1 es el nuevo largo
	MOV R2, R5				//R2 es el nuevo ancho

	MOV R4, #0		//R4 es el contador de Y, para el primer pixel
	MOV R5, #3		//R5 es el contador de Y, para el segundo pixel

_vertical_x_reset:
	MOV R3, #0		//R3 es el contador de X


_vertical_interpolation:
	//R6, R7, R8, R9, R10, R11, R12 para usar

	//En R6 Posicion P1 y en R7 Posicion P2
	MUL R6, R4, R1		//R6 es la posición en X de la imagen nueva
	MUL R7, R5, R1		//R7 es la posición en Y de la imagen nueva
	ADD R6, R6, R3		// + X_new
	ADD R7, R7, R3		// + X_new
	ADD R6, R6, R0		//Sumo la dirección de output_buffer, R6 aquí es la dirección del pixel en la nueva imagen
	ADD R7, R7, R0		//Sumo la dirección de output_buffer, R7 aquí es la dirección del pixel en la nueva imagen

	ADD R8, R6, R1		//R8 es la posición de PI_1 (Pixel intermedio 1)
	ADD R9, R8, R1		//R9 es la posición de PI_2 (Pixel intermedio 2)


	LDRB R10, [R6]		//En R10 leo el valor de P1
	LDRB R11, [R7]		//En R11 leo el valor de P2

	//PI_Y = (y2-y)/(y2-y1)*R10 + (y-y1)/(y2-y1)*R11, para ambos puntos siempre se cumple que:
	//Para PI_1, y1 = 0, y2 = 12, y = 4, por lo tanto PI_1 = (12-4)/12*P1 + (4-0)/12*P2 = 2/3*P1 + 1/3*P2 = (2*P1 + P2)/3
	//Para PI_2, y1 = 0, y2 = 12, y = 8, por lo tanto PI_2 = (12-8)/12*P1 + (8-0)/12*P2 = 1/3*P1 + 2/3*P2 = (P1 + 2*P2)/3

	//R12 = 3, constante para dividir
	MOV R12, #3

	// En R6 guardo el valor de PI_1
	ADD R6, R10, R10		//2*P1
	ADD R6, R6, R11			//+ P2
	SDIV R6, R6, R12		//Divido entre 3

	// En R7 guardo el valor de PI_2
	ADD R7, R10, R11		//P1 + P2
	ADD R7, R7, R11			//+ P2, = P1 + 2*P2
	SDIV R7, R7, R12		//Divido entre 3

	STRB R6, [R8]           // Guardar el byte en la posición (R8) de la nueva imagen
	STRB R7, [R9]           // Guardar el byte en la posición (R9) de la nueva imagen

	//Incrementar el contador de X
	ADD R3, R3, #3

	//Comparo si X (R3) es igual al largo de la imagen nueva
	CMP R3, R1
	BLT _vertical_interpolation

	//Incrementar el contador de Y
	ADD R4, R4, #3
	ADD R5, R5, #3

	//Comparo si Y (R5) es igual al ancho de la imagen nueva
	CMP R5, R2
	BLT _vertical_x_reset

	B _horizontal_setup


_horizontal_setup:

	MOV R4, #0		//R4 es el contador de X, para el primer pixel, el segundo pixel es 1 posicion adelante

_horizontal_y_reset:
	MOV R3, #0		//R3 es el contador de Y

_horizontal_interpolation:
	//R5, R6, R7, R8, R9, R10, R11, R12 para usar

	//En R5 Posicion P1
	MUL R5, R3, R1		//R5 es la posición en X de la imagen nueva
	ADD R5, R5, R4		// + X_new
	ADD R5, R5, R0		//Sumo la dirección de output_buffer, R5 aquí es la dirección del pixel en la nueva imagen
	ADD R11, R5, #3		//En R11 guardo la posición de P2 (Pos_P1+3)

	//En R6 guardo el valor de P1
	LDRB R6, [R5]		//En R6 leo el valor de P1
	LDRB R7, [R11]		//En R7 leo el valor de P2

	//PI_X = (x2-x)/(x2-x1)*R6 + (x-x1)/(x2-x1)*R7, para ambos puntos siempre se cumple que:
	//Para PI_1, x1 = 0, x2 = 3, x = 1, por lo tanto PI_1 = (3-1)/3*P1 + (1-0)/3*P2 = 2/3*P1 + 1/3*P2 = (2*P1 + P2)/3
	//Para PI_2, x1 = 0, x2 = 3, x = 2, por lo tanto PI_2 = (3-2)/3*P1 + (2-0)/3*P2 = 1/3*P1 + 2/3*P2 = (P1 + 2*P2)/3

	//R12 = 3, constante para dividir
	MOV R12, #3

	// En R8 guardo el valor de PI_1
	ADD R8, R6, R6
	ADD R8, R8, R7
	SDIV R8, R8, R12

	// En R9 guardo el valor de PI_2
	ADD R9, R6, R7
	ADD R9, R9, R7
	SDIV R9, R9, R12

	STRB R8, [R5, #1]           // Guardar el byte en la posición (R5+1) de la nueva imagen, PI_1
	STRB R9, [R5, #2]           // Guardar el byte en la posición (R5+2) de la nueva imagen, PI_2

	//Incrementar el contador de Y
	ADD R3, R3, #1

	//Comparo si Y (R3) es igual al ancho de la imagen nueva
	CMP R3, R2
	BLE _horizontal_interpolation

	//Incrementar el contador de X
	ADD R4, R4, #3

	//Comparo si X (R4) es igual al largo de la imagen nueva -1
	SUB R11, R1, #1
	CMP R4, R11
	BLT _horizontal_y_reset

	B _save_image

_save_image:
    // Guardar el nuevo largo y ancho en el buffer de salida
    LDR R0, =output_buffer  // Dirección del buffer de salida
    STRH R1, [R0]           // Guardar el nuevo largo (R1) en los primeros 2 bytes
    STRH R2, [R0, #2]       // Guardar el nuevo ancho (R2) en los siguientes 2 bytes

    // Abrir el archivo de salida (output.img)
    MOV R7, #5         // Número de syscall para sys_open
    LDR R0, =output_filename
    MOV R1, #577       // Flags: O_WRONLY | O_CREAT (escribir solo y crear si no existe)
    MOV R2, #438       // Permisos: 0666 (lectura y escritura para todos)
    SWI 0              // Ejecutar syscall
    MOV R4, R0         // Guardar el descriptor de archivo en R4

    // Escribir los datos en el archivo de salida
    MOV R7, #4         // Número de syscall para sys_write
    MOV R0, R4         // Descriptor de archivo (output.img)
    LDR R1, =output_buffer // Dirección del buffer de salida
    ADD R2, R1, #4     // Ajustar la cantidad de datos a escribir (incluyendo los 4 bytes de largo y ancho)
    MOV R2, #8388608    // Tamaño de los datos a escribir (8MB + 4 bytes)
    SWI 0              // Ejecutar syscall

    // Cerrar el archivo de salida
    MOV R7, #6         // Número de syscall para sys_close
    MOV R0, R4         // Descriptor de archivo
    SWI 0              // Ejecutar syscall

_end:
    // Terminar el programa
    MOV R7, #1         // Número de syscall para sys_exit
    MOV R0, #0         // Código de salida
    SWI 0              // Ejecutar syscall

