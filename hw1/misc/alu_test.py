import serial
import time
from threading import Thread
import struct

# Opcodes
OPCODE_ECHO = 0xEC
OPCODE_ADD32 = 0xAD
OPCODE_MUL32 = 0x1E
OPCODE_DIV32 = 0xD1


def create_packet(opcode: int, data: bytes) -> bytes:
    packet_len = len(data) + 4  # data length + header size
    header = bytes([
        opcode,              # Operation opcode
        0x00,               # Reserved
        packet_len & 0xFF,  # Length LSB
        packet_len >> 8     # Length MSB
    ])
    return header + data


def add32(operands: list) -> bytes:
    # Pack integers as little-endian 32-bit values
    data = b''.join(struct.pack('<i', x) for x in operands)
    return create_packet(OPCODE_ADD32, data)


def mul32(operands: list) -> bytes:
    data = b''.join(struct.pack('<i', x) for x in operands)
    return create_packet(OPCODE_MUL32, data)


def div32(numerator: int, denominator: int) -> bytes:
    data = struct.pack('<ii', numerator, denominator)
    return create_packet(OPCODE_DIV32, data)


def main():
    # Open serial port
    ser = serial.Serial(
        port='/dev/ttyUSB1',  # Adjust as needed
        baudrate=115200,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE
    )

    # Test arithmetic packets
    test_msgs = [
        b"Hello World!",
    ]
    add_test = [7, 3]  # Should sum to 60
    mul_test = [2, 3, 4]     # Should multiply to 24
    div_test = (100, 5)      # Should divide to 20


    # # Test echo packets
    # for msg in test_msgs:
    #     packet = create_packet(OPCODE_ECHO, msg)
    #     print(f"\nSending echo packet: {packet.hex()}")
    #     print(f"Data: {msg}")
    #     ser.write(packet)
    #     time.sleep(1)

    # Test arithmetic packets
    add_packet = add32(add_test)
    print(f"\nSending add packet: {add_packet.hex()}")
    print(f"Add operands: {add_test}")
    ser.write(add_packet)
    time.sleep(1)

    # mul_packet = mul32(mul_test)
    # print(f"\nSending multiply packet: {mul_packet.hex()}")
    # print(f"Multiply operands: {mul_test}")
    # ser.write(mul_packet)
    # time.sleep(1)

    # div_packet = div32(*div_test)
    # print(f"\nSending divide packet: {div_packet.hex()}")
    # print(f"Divide operands: {div_test}")
    # ser.write(div_packet)
    # time.sleep(1)

    ser.close()


if __name__ == "__main__":
    main()