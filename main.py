import subprocess

def execute_assembly():
    # Ensamblar el código
    result = subprocess.run(["arm-linux-gnueabi-as", "test.s", "-o", "test.o"])
    if result.returncode != 0:
        print("Error: Failed to assemble the source code.")
        return
    
    # Enlazar el código
    result = subprocess.run(["arm-linux-gnueabi-ld", "test.o", "-o", "test"])
    if result.returncode != 0:
        print("Error: Failed to link the object file.")
        return
    
    # Ejecutar el binario con QEMU
    result = subprocess.run(["qemu-arm", "-L", "/usr/arm-linux-gnueabi/", "./test"])
    if result.returncode != 0:
        print("Error: Failed to run the executable.")
        return
    
    print("Assembly code executed successfully")

execute_assembly()
