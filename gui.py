import customtkinter as ctk
import tkinter as tk
from PIL import Image, ImageTk
import subprocess
import struct

# Parámetros configurables
GRID_SIZE = 4  
SIDE_LENGTH = 390  
TARGET_SIZE = (SIDE_LENGTH, SIDE_LENGTH)  

# Cargar imagen y redimensionarla
imagen_original = Image.open("input.jpg").convert("L").resize(TARGET_SIZE)
ANCHO, ALTO = TARGET_SIZE  

# Crear ventana
tk_app = ctk.CTk()
tk_app.title("Selecciona una parte")
tk_app.geometry(f"{ANCHO * 2 + 40}x{ALTO + 140}")  

# Frame principal para las imágenes
frame_imagenes = ctk.CTkFrame(tk_app)
frame_imagenes.pack(pady=10, padx=10, side="top")

# Canvas de la imagen original (izquierda)
canvas = tk.Canvas(frame_imagenes, width=ANCHO, height=ALTO)
canvas.pack(side="left", padx=10)

# Canvas de la imagen procesada (derecha)
output_canvas = tk.Canvas(frame_imagenes, width=ANCHO, height=ALTO)
output_canvas.pack(side="right", padx=10)

# Frame para los botones (debajo de las imágenes)
frame_botones = ctk.CTkFrame(tk_app)
frame_botones.pack(pady=10)

# Botón para guardar y procesar (centrado)
btn_guardar = ctk.CTkButton(frame_botones, text="Guardar y Procesar", command=lambda: [guardar_como_binario(), execute_assembly(), mostrar_output()])
btn_guardar.pack(pady=10, anchor="center")

# División de la imagen en partes
TILE_SIZE_X = ANCHO // GRID_SIZE
TILE_SIZE_Y = ALTO // GRID_SIZE
imagen_original.save("input_gray.jpg")  

partes = []  
seleccionada = None  
rectangulo_id = None  

tile_images = []  
for i in range(GRID_SIZE):
    for j in range(GRID_SIZE):
        x1, y1 = j * TILE_SIZE_X, i * TILE_SIZE_Y
        x2, y2 = x1 + TILE_SIZE_X, y1 + TILE_SIZE_Y
        parte = imagen_original.crop((x1, y1, x2, y2))
        parte_tk = ImageTk.PhotoImage(parte)
        tile_images.append(parte_tk)
        id_img = canvas.create_image(x1, y1, anchor="nw", image=parte_tk)
        partes.append((id_img, parte, (i, j)))  

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

def guardar_como_binario():
    if seleccionada:
        ancho, alto = seleccionada.size
        pixeles = list(seleccionada.getdata())
        with open("input.img", "wb") as f:
            f.write(struct.pack("HH", alto, ancho))
            f.write(bytes(pixeles))
        print("Imagen guardada como input.img")

def execute_assembly():
    result = subprocess.run(
        "arm-none-eabi-as test.s -g -o test.o && arm-none-eabi-ld test.o -o test && ./test",
        shell=True
    )
    
    if result.returncode != 0:
        print("Error: La ejecución del ensamblador falló.")
        return
    
    print("Assembly ejecutado exitosamente.")

def mostrar_output():
    try:
        with open("output.img", "rb") as f:
            largo, ancho = struct.unpack("HH", f.read(4))
            data = f.read(largo * ancho)
            output_img = Image.frombytes("L", (ancho, largo), data)
            output_img.save("imagen_reconstruida.jpg")
            output_img = output_img.resize((ANCHO, ALTO))
            output_tk = ImageTk.PhotoImage(output_img)
            output_canvas.create_image(0, 0, anchor="nw", image=output_tk)
            output_canvas.image = output_tk  
            print("Imagen reconstruida guardada como imagen_reconstruida.jpg")
    except FileNotFoundError:
        print("Error: output.img no encontrado.")
    except Exception as e:
        print(f"Error al leer output.img: {e}")

canvas.bind("<Button-1>", seleccionar)

# Ejecutar la aplicación
tk_app.mainloop()
