import serial
import time

# Opcodes
OPCODE_ECHO = 0xEC
OPCODE_ADD32 = 0xAD
OPCODE_MUL32 = 0x88
OPCODE_DIV32 = 0xD1

class ALU:
    def __init__(self, port='/dev/ttyUSB1', baudrate=115200):
        self.ser = serial.Serial(
            port=port,
            baudrate=baudrate,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE
        )

    def _create_packet(self, opcode: int, data: bytes) -> bytes:
        packet_len = len(data) + 4
        header = bytes([
            opcode,
            0x00,
            packet_len & 0xFF,
            packet_len >> 8
        ])
        # print(f"Packet: {header.hex() + data.hex()}")
        return header + data

    def echo(self, data: str):
        packet = self._create_packet(OPCODE_ECHO, data.encode())
        print(f"echo(\"{data}\")")
        self.ser.write(packet)

    def add32(self, numbers: list):
        data = b''.join((x & 0xFFFFFFFF).to_bytes(4, byteorder='little', signed=False) 
                       for x in numbers)
        packet = self._create_packet(OPCODE_ADD32, data)
        print(f"add32({numbers})")
        self.ser.write(packet)

    def mul32(self, numbers: list):
        data = b''
        for x in numbers:
            # Convert to signed 32-bit
            x = x & 0xFFFFFFFF
            if x & 0x80000000:
                x = x - 0x100000000
            # Convert to unsigned 32-bit for transmission
            unsigned_x = x & 0xFFFFFFFF if x >= 0 else (abs(x) ^ 0xFFFFFFFF) + 1
            data += unsigned_x.to_bytes(4, byteorder='little', signed=False)
        packet = self._create_packet(OPCODE_MUL32, data)
        print(f"mul32({numbers})")
        self.ser.write(packet)

    def div32(self, dividend: int, divisor: int):
        # Convert to signed 32-bit
        numbers = [dividend, divisor]
        data = b''
        for x in numbers:
            x = x & 0xFFFFFFFF
            if x & 0x80000000:
                x = x - 0x100000000
            # Convert to unsigned 32-bit for transmission
            unsigned_x = x & 0xFFFFFFFF if x >= 0 else (abs(x) ^ 0xFFFFFFFF) + 1
            data += unsigned_x.to_bytes(4, byteorder='little', signed=False)
        packet = self._create_packet(OPCODE_DIV32, data)
        print(f"div32({dividend}, {divisor})")
        self.ser.write(packet)

    def receive_result(self):
        if self.ser.in_waiting >= 4:
            result_bytes = self.ser.read(4)
            result = int.from_bytes(result_bytes, byteorder='little', signed=False)
            # Convert to signed if needed
            signed_result = result if (result & 0x80000000) == 0 else result - 0x100000000
            print(f"{signed_result}")
            return signed_result
        return None

    def receive_echo(self):
        if self.ser.in_waiting:
            data = self.ser.read(self.ser.in_waiting)
            print(f"{data.decode()}")

    def close(self):
        self.ser.close()

def main():
    alu = ALU()
    
    alu.echo("Hello, ALU!")
    time.sleep(0.1)
    alu.receive_echo()

    alu.add32([1, 2, 3, 4, 5])
    time.sleep(0.1)
    alu.receive_result()

    alu.mul32([1, 2, 3, 4, 5])
    time.sleep(0.1)
    alu.receive_result()

    alu.div32(6, -2)
    time.sleep(0.1)
    alu.receive_result()

    alu.close()

if __name__ == "__main__":
    main()
