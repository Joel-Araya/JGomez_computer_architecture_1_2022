import customtkinter as ctk
import tkinter as tk
from PIL import Image, ImageTk
import subprocess
import struct

# Convertir la imagen a escala de grises y redimensionarla
imagen_original = Image.open("input.jpg").convert("L").resize((390, 390))
imagen_original.save("input_gray.jpg")  # Guardamos la versión en grises
partes = []  # Lista de partes de la imagen
seleccionada = None  # Parte seleccionada
rectangulo_id = None  # Para borrar selección previa

# Crear ventana
app = ctk.CTk()
app.title("Selecciona una parte")
app.geometry("820x460")  # Más ancho para mostrar la imagen de salida

# Marco para las imágenes
frame = ctk.CTkFrame(app)
frame.pack(pady=10, side="left")

canvas = tk.Canvas(frame, width=390, height=390)
canvas.pack()

# Cargar y dividir la imagen en 4x4
for i in range(4):
    for j in range(4):
        x1, y1 = j * 97, i * 97
        x2, y2 = x1 + 97, y1 + 97
        parte = imagen_original.crop((x1, y1, x2, y2))
        parte_tk = ImageTk.PhotoImage(parte)
        id_img = canvas.create_image(x1, y1, anchor="nw", image=parte_tk)
        partes.append((id_img, parte, parte_tk, (i, j)))  # Guardamos cada parte

# Función para seleccionar una parte
def seleccionar(event):
    global seleccionada, rectangulo_id

    if rectangulo_id:
        canvas.delete(rectangulo_id)  # Borra la selección previa

    for item in partes:
        id_img, img, img_tk, (i, j) = item
        x1, y1 = j * 97, i * 97
        x2, y2 = x1 + 97, y1 + 97

        if x1 <= event.x <= x2 and y1 <= event.y <= y2:
            seleccionada = img  # Guarda la parte seleccionada
            rectangulo_id = canvas.create_rectangle(x1, y1, x2, y2, outline="red", width=3)
            break

# Guardar la imagen seleccionada como "input.img"
def guardar_como_binario():
    if seleccionada:
        ancho, largo = seleccionada.size  # Obtener dimensiones
        pixeles = list(seleccionada.getdata())  # Obtener valores de píxeles

        with open("input.img", "wb") as f:
            f.write(struct.pack("II", largo, ancho))  # Escribir largo y ancho
            f.write(bytes(pixeles))  # Escribir valores de píxeles

        print("Imagen guardada como input.img")

# Ejecutar código ensamblador y mostrar imagen de salida
def execute_assembly():
    subprocess.run(["arm-linux-gnueabi-as", "test.s", "-o", "test.o"])
    subprocess.run(["arm-linux-gnueabi-ld", "test.o", "-o", "test"])
    subprocess.run(["./test"])

    # Cargar y mostrar la imagen de salida
    mostrar_output()

# Mostrar la imagen procesada
def mostrar_output():
    try:
        output_img = Image.open("output.jpg").resize((390, 390))  # Escalar la imagen de salida
        output_tk = ImageTk.PhotoImage(output_img)
        output_canvas.create_image(0, 0, anchor="nw", image=output_tk)
        output_canvas.image = output_tk  # Mantener referencia
    except FileNotFoundError:
        print("Error: output.jpg no encontrado.")

# Guardar la parte seleccionada y ejecutar ensamblador
def guardar_y_procesar():
    guardar_como_binario()
    execute_assembly()  # Ejecuta el código en ensamblador

# Enlazar clic en la imagen
canvas.bind("<Button-1>", seleccionar)

# Botón para guardar y procesar
btn_guardar = ctk.CTkButton(app, text="Guardar y Procesar", command=guardar_y_procesar)
btn_guardar.pack(pady=10)

# Marco para la imagen de salida
frame_output = ctk.CTkFrame(app)
frame_output.pack(pady=10, side="right")

output_canvas = tk.Canvas(frame_output, width=390, height=390)
output_canvas.pack()

app.mainloop()
