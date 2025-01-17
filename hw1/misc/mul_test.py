import serial
import time
import struct

# Opcodes
OPCODE_MUL32 = 0x88


def create_packet(opcode: int, data: bytes) -> bytes:
    packet_len = len(data) + 4
    header = bytes([
        opcode,
        0x00,
        packet_len & 0xFF,
        packet_len >> 8
    ])
    return header + data


def mul32(operands: list) -> bytes:
    # Directly convert integers to bytes in big-endian format
    data = b''.join((x & 0xFFFFFFFF).to_bytes(
        4, byteorder='big', signed=False) for x in operands)
    return create_packet(OPCODE_MUL32, data)


def receive_result(ser: serial.Serial) -> int:
    result_bytes = ser.read(4)
    result = int.from_bytes(result_bytes, byteorder='big', signed=False)
    return result


def print_number(num: int) -> str:
    """Print number in decimal, hex bytes, and binary formats"""
    signed_val = num if (num & 0x80000000) == 0 else num - 0x100000000
    bytes_val = (num & 0xFFFFFFFF).to_bytes(4, byteorder='big', signed=False)
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

    mul_tests = [
        # Basic cases
        [1, 2],                     # 2
        [-1, 2],                    # -2
        [-1, -2],                   # 2
        [0, -5],                    # 0

        # Medium numbers
        [1000, -2000],             # -2,000,000
        [-4000, -3000],            # 12,000,000
        [0x7FFF, 0x7FFF],          # 32,767 * 32,767

        # Powers of 2
        [0x40000000, 2],           # 1,073,741,824 * 2
        [0x40000000, -2],          # 1,073,741,824 * -2

        # Edge cases
        [0x7FFFFFFF, 1],           # INT32_MAX * 1
        [-0x80000000, 1],          # INT32_MIN * 1
        [-0x80000000, -1],         # INT32_MIN * -1 (overflow)
        [0x7FFFFFFF, -1],          # INT32_MAX * -1
        [0x7FFFFFFF, 0x7FFFFFFF],  # INT32_MAX * INT32_MAX
        [-0x80000000, -0x80000000],  # INT32_MIN * INT32_MIN

        # Identity cases
        [1, 0],                    # Zero
        [-1, 0],                   # Zero
        [42, 1],                   # Identity
        [-42, 1],                  # Identity negative

        # Near overflow cases
        [0x40000000, 2],          # Near overflow positive
        [-0x40000000, 2],         # Near overflow negative
    ]

    tests_passed = 0
    total_tests = len(mul_tests)

    for test in mul_tests:
        mul_packet = mul32(test)

        product = 1
        for x in test:
            # Convert to signed 32-bit
            x_signed = x if (x & 0x80000000) == 0 else x - 0x100000000
            product_signed = product if (
                product & 0x80000000) == 0 else product - 0x100000000
            product = (product_signed * x_signed) & 0xFFFFFFFF

        print("\nTest case:", [f'{x} (0x{x & 0xFFFFFFFF:08x})' for x in test])
        print(f"Expected result:  {print_number(product)}")

        # Send packet and receive result
        ser.write(mul_packet)
        result = receive_result(ser)

        print(f"Received result:  {print_number(result)}")

        # Show if results match
        if result != product:
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
