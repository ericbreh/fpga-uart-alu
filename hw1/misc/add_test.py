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


def add32(operands: list) -> bytes:
    # Convert integers to bytes in little-endian format
    data = b''.join((x & 0xFFFFFFFF).to_bytes(
        4, byteorder='little', signed=False) for x in operands)
    return create_packet(OPCODE_ADD32, data)


def receive_result(ser: serial.Serial) -> int:
    result_bytes = ser.read(4)
    result = int.from_bytes(result_bytes, byteorder='little', signed=False)
    return result


def print_number(num: int) -> str:
    """Print number in decimal, hex bytes, and binary formats"""
    signed_val = num if (num & 0x80000000) == 0 else num - 0x100000000
    bytes_val = (num & 0xFFFFFFFF).to_bytes(4, byteorder='little', signed=False)
    hex_bytes = ' '.join(f'{b:02x}' for b in bytes_val)

    return (f"Decimal: {signed_val}, "
            f"Hex bytes: {hex_bytes}, "
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

        # list(range(1, 16383)),
    ]

    tests_passed = 0
    total_tests = len(add_tests)

    for test in add_tests:
        add_packet = add32(test)

        # Calculate expected sum (both signed and unsigned interpretations)
        masked_sum = sum(x & 0xFFFFFFFF for x in test) & 0xFFFFFFFF

        print("\nTest case:", [f'{x} (0x{x & 0xFFFFFFFF:08x})' for x in test])
        print(f"Expected result:  {print_number(masked_sum)}")

        # Send packet and receive result
        ser.write(add_packet)
        result = receive_result(ser)

        print(f"Received result:  {print_number(result)}")

        # Show if results match
        if result != masked_sum:
            print(f"FAIL")
        else:
            print(f"PASS")
            tests_passed += 1

        time.sleep(0.1)

    print("\n=== Test Summary ===")
    print(f"Tests passed: {
          tests_passed}/{total_tests} ({(tests_passed/total_tests)*100:.1f}%)")

    ser.close()


if __name__ == "__main__":
    main()
