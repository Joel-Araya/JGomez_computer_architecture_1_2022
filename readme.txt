#Antes de ejecutar el código del archivo main.py es necesario instalar las siguientes bibliotecas

pip install customtkinter
pip install Pillow


#También es necesario realizar la instalación de las herramientas de ejecución de ARM

sudo apt-get install gcc-arm-linux-gnueabi gcc-arm-none-eabi


#En caso de fallar algo es posible realizar debug al ARM, para ello es necesaria la intalación de qemu

sudo apt get install qemu
qemu-arm test


#El debug se realiza de la siguiente manera:
Abrimos 2 terminales, una hostea el Qemu y la otra el debug del ensamblador con gdb

##Terminal que hostea el qemu:
qemu-arm -singlestep -g 1234 bilinear_interpolation

##Terminal gdb:
arm-none-eabi-as bilinear_interpolation.s -g -o bilinear_interpolation.o && arm-none-eabi-ld bilinear_interpolation.o -o bilinear_interpolation && arm-none-eabi-gdb

##(gdb) 
file bilinear_interpolation
target remote localhost:1234


### Revisar registros
i r r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12

### Revisar buffers
x/100xb &data_buffer
x/100xb &output_buffer

### Establecer Breakpoints
b _start
b _reset_x
b _read_bytes
b _bilinear_interpolation
b _vertical_x_reset
b _vertical_interpolation
b _horizontal_setup
b _horizontal_y_reset
b _horizontal_interpolation
b _save_image
b _end


### Ejemplo - Breakpoint en end, para visualizar valores finales

file bilinear_interpolation
target remote localhost:1234
b _end
c

