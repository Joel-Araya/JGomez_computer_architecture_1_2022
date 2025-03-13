import subprocess

subprocess.run(["arm-linux-gnueabi-as", "test.s", "-o", "test.o"])
subprocess.run(["arm-linux-gnueabi-ld", "test.o", "-o", "test"])


subprocess.run(["python3", "--version"])