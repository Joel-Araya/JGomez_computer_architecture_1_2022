import customtkinter as ctk
import tkinter as tk
from PIL import Image, ImageTk
import subprocess
import struct

# Parámetros configurables
GRID_SIZE = 4  # Número de divisiones en filas y columnas
SIDE_LENGTH = 2000  # Longitud de un lado de la imagen con límites
TARGET_SIZE = (SIDE_LENGTH, SIDE_LENGTH)  # Tamaño deseado para la imagen procesada

# Cargar imagen y redimensionarla
imagen_original = Image.open("test.jpg").convert("L").resize(TARGET_SIZE)
ANCHO, ALTO = TARGET_SIZE  # Tamaño de la imagen procesada

# Ajustar tamaño de la ventana
VENTANA_ANCHO = ANCHO * 2 + 40  # Espacio para ambas imágenes y margen
VENTANA_ALTO = ALTO + 100  # Espacio para imágenes y botones

# Redimensionar imagen para asegurar divisibilidad
TILE_SIZE_X = ANCHO // GRID_SIZE
TILE_SIZE_Y = ALTO // GRID_SIZE
imagen_original.save("input_gray.jpg")  # Guardamos la versión en grises

partes = []  # Lista de partes de la imagen
seleccionada = None  # Parte seleccionada
rectangulo_id = None  # Para borrar selección previa

# Crear ventana
tk_app = ctk.CTk()
tk_app.title("Selecciona una parte")
tk_app.geometry(f"{VENTANA_ANCHO}x{VENTANA_ALTO}")

# Marco para las imágenes
frame = ctk.CTkFrame(tk_app)
frame.pack(pady=10, side="left")

canvas = tk.Canvas(frame, width=ANCHO, height=ALTO)
canvas.pack()

# Cargar y dividir la imagen
tile_images = []  # Lista para mantener referencia a las imágenes en Tkinter
for i in range(GRID_SIZE):
    for j in range(GRID_SIZE):
        x1, y1 = j * TILE_SIZE_X, i * TILE_SIZE_Y
        x2, y2 = x1 + TILE_SIZE_X, y1 + TILE_SIZE_Y
        parte = imagen_original.crop((x1, y1, x2, y2))
        parte_tk = ImageTk.PhotoImage(parte)
        tile_images.append(parte_tk)
        id_img = canvas.create_image(x1, y1, anchor="nw", image=parte_tk)
        partes.append((id_img, parte, (i, j)))  # Guardamos cada parte

# Función para seleccionar una parte
def seleccionar(event):
    global seleccionada, rectangulo_id
    if rectangulo_id:
        canvas.delete(rectangulo_id)
    for id_img, img, (i, j) in partes:
        x1, y1 = j * TILE_SIZE_X, i * TILE_SIZE_Y
        x2, y2 = x1 + TILE_SIZE_X, y1 + TILE_SIZE_Y
        if x1 <= event.x <= x2 and y1 <= event.y <= y2:
            seleccionada = img
            rectangulo_id = canvas.create_rectangle(x1, y1, x2, y2, outline="red", width=3)
            break

# Guardar la imagen seleccionada como "input.img"
def guardar_como_binario():
    if seleccionada:
        ancho, alto = seleccionada.size
        pixeles = list(seleccionada.getdata())
        with open("input.img", "wb") as f:
            f.write(struct.pack("HH", alto, ancho))  # Escribir largo y ancho (2 bytes cada uno)
            f.write(bytes(pixeles))  # Escribir valores de píxeles (1 byte por píxel)
        print("Imagen guardada como input.img")

# Ejecutar código ensamblador
def execute_assembly():
    subprocess.run(["arm-linux-gnueabi-as", "test.s", "-o", "test.o"])
    subprocess.run(["arm-linux-gnueabi-ld", "test.o", "-o", "test"])
    subprocess.run(["./test"])
    mostrar_output()

# Mostrar la imagen procesada
def mostrar_output():
    try:
        output_img = Image.open("output.jpg").resize((ANCHO, ALTO))
        output_tk = ImageTk.PhotoImage(output_img)
        output_canvas.create_image(0, 0, anchor="nw", image=output_tk)
        output_canvas.image = output_tk  # Mantener referencia
    except FileNotFoundError:
        print("Error: output.jpg no encontrado.")

# Guardar la parte seleccionada y ejecutar ensamblador
def guardar_y_procesar():
    guardar_como_binario()
    execute_assembly()

# Enlazar clic en la imagen
canvas.bind("<Button-1>", seleccionar)

# Botón para guardar y procesar
btn_guardar = ctk.CTkButton(tk_app, text="Guardar y Procesar", command=guardar_y_procesar)
btn_guardar.pack(pady=10)

# Marco para la imagen de salida
frame_output = ctk.CTkFrame(tk_app)
frame_output.pack(pady=10, side="right")

output_canvas = tk.Canvas(frame_output, width=ANCHO, height=ALTO)
output_canvas.pack()

# Ejecutar la aplicación
tk_app.mainloop()
