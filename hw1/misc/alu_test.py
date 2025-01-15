import serial
import time
import struct

# Opcodes
OPCODE_ADD32 = 0xAD


def create_packet(opcode: int, data: bytes) -> bytes:
    packet_len = len(data) + 4
    header = bytes([
        opcode,
        0x00,
        packet_len & 0xFF,
        packet_len >> 8
    ])
    return header + data


def int_to_bytes(value: int) -> bytes:
    """Convert any integer to 32-bit unsigned bytes in big-endian format"""
    return (value & 0xFFFFFFFF).to_bytes(4, byteorder='big', signed=False)


def add32(operands: list) -> bytes:
    # Convert each number to 32-bit unsigned bytes
    data = b''.join(int_to_bytes(x) for x in operands)
    return create_packet(OPCODE_ADD32, data)


def receive_result(ser: serial.Serial) -> int:
    result_bytes = ser.read(4)
    result = int.from_bytes(result_bytes, byteorder='big', signed=False)
    return result


def print_hex_bytes(data: bytes):
    return ' '.join(f'{b:02x}' for b in data)


def print_number_details(num: int):
    """Print detailed representation of a number in different formats"""
    signed_val = num if (num & 0x80000000) == 0 else num - 0x100000000
    return (f"Decimal: {signed_val}, "
            f"Hex: 0x{num & 0xFFFFFFFF:08x}, "
            f"Binary: {num & 0xFFFFFFFF:032b}")


def main():
    ser = serial.Serial(
        port='/dev/ttyUSB1',
        baudrate=115200,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE
    )

    # Test cases focusing on negative numbers
    add_tests = [
        # Basic positive numbers
        [1, 2],
        [100, 200],

        # Testing byte ordering
        [0x12345678, 0x9ABCDEF0],

        # Testing sign handling
        [0x7FFFFFFF, 1],           # Max positive + 1
        [0xFFFFFFFF, 1],           # -1 + 1 (if treated as signed)

        # Testing overflow
        [0x80000000, 0x80000000],  # Should result in 0 with overflow
        [0xFFFFFFFF, 0xFFFFFFFF],  # Should result in 0xFFFFFFFE

        # Multiple number addition
        [0x11111111, 0x22222222, 0x33333333],
        
        # Basic negative number tests
        [-1, 1],                    # -1 + 1 = 0
        [-5, 5],                    # -5 + 5 = 0
        [-10, -20],                 # -10 + -20 = -30

        # Edge cases with negative numbers
        [-2147483648, 0],           # INT32_MIN + 0
        [-2147483648, 1],           # INT32_MIN + 1
        [-2147483648, -1],          # INT32_MIN + (-1)

        # Mixed positive and negative
        [-1000000, 2000000],        # Mixed large numbers
        [-1, -1, -1, -1],           # Multiple negatives
        [2147483647, -1],           # INT32_MAX + (-1)

        # Overflow cases
        [-2147483648, -2147483648],  # INT32_MIN + INT32_MIN
        [2147483647, -2147483648],  # INT32_MAX + INT32_MIN

        # Additional edge cases
        [0xFFFFFFFF, 0xFFFFFFFF],   # -1 + -1 = -2
        [-2147483648, 2147483647],   # INT32_MIN + INT32_MAX
    ]

    for test in add_tests:
        add_packet = add32(test)

        # Calculate expected sum (both signed and unsigned interpretations)
        masked_sum = sum(x & 0xFFFFFFFF for x in test) & 0xFFFFFFFF
        signed_sum = masked_sum if (
            masked_sum & 0x80000000) == 0 else masked_sum - 0x100000000

        print("\nTest case:", [f'{x} (0x{x & 0xFFFFFFFF:08x})' for x in test])
        print(f"Packet bytes:     {print_hex_bytes(add_packet)}")
        print(f"Expected result:  {print_number_details(masked_sum)}")

        # Send packet and receive result
        ser.write(add_packet)
        result = receive_result(ser)

        print(f"Received result:  {print_number_details(result)}")

        # Show if results match
        if result != masked_sum:
            print("*** Results don't match! ***")
            print(f"Expected bytes: {
                  print_hex_bytes(int_to_bytes(masked_sum))}")
            print(f"Received bytes: {print_hex_bytes(int_to_bytes(result))}")

        time.sleep(0.1)

    ser.close()


if __name__ == "__main__":
    main()
