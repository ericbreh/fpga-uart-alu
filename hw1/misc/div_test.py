import serial
import time
import struct

# Opcodes
OPCODE_DIV32 = 0xD1


def create_packet(opcode: int, data: bytes) -> bytes:
    packet_len = len(data) + 4
    header = bytes([
        opcode,
        0x00,
        packet_len & 0xFF,
        packet_len >> 8
    ])
    return header + data


def div32(operands: list) -> bytes:
    # Convert each operand to a signed 32-bit integer
    values = []
    for x in operands:
        if isinstance(x, str):
            x = int(x.split()[0])
        # Ensure the value is in signed 32-bit range
        x = x & 0xFFFFFFFF
        if x & 0x80000000:
            x = x - 0x100000000
        values.append(x)

    # Convert to little-endian bytes, handling negative numbers correctly
    data = b''
    for x in values:
        # Convert to unsigned 32-bit for transmission
        unsigned_x = x & 0xFFFFFFFF if x >= 0 else (abs(x) ^ 0xFFFFFFFF) + 1
        data += unsigned_x.to_bytes(4, byteorder='little', signed=False)
    return create_packet(OPCODE_DIV32, data)


def receive_result(ser: serial.Serial) -> int:
    result_bytes = ser.read(4)
    # First interpret as unsigned
    result = int.from_bytes(result_bytes, byteorder='little', signed=False)
    # Convert to signed if necessary
    if result & 0x80000000:
        result = result - 0x100000000
    return result & 0xFFFFFFFF


def print_number(num: int) -> str:
    """Print number in decimal, hex bytes, and binary formats"""
    # Ensure num is within 32-bit range and handle sign
    num = num & 0xFFFFFFFF
    signed_val = num if (num & 0x80000000) == 0 else num - 0x100000000

    # Convert to bytes using unsigned conversion
    bytes_val = num.to_bytes(4, byteorder='little', signed=False)
    hex_bytes = ' '.join(f'{b:02x}' for b in bytes_val)

    return (f"Decimal: {signed_val}, "
            f"Hex bytes: {hex_bytes}, "
            f"Binary: {num:032b}")


def main():
    ser = serial.Serial(
        port='/dev/ttyUSB1',
        baudrate=115200,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE
    )

    div_tests = [
        # Basic cases
        [10, 2],                    # 5
        [-10, 2],                   # -5
        [-10, -2],                  # 5
        [10, -2],                   # -5

        # Identity cases
        [42, 1],                    # Identity
        [-42, 1],                   # Identity negative
        [0, 1],                     # Zero dividend

        # Division by powers of 2
        [1024, 2],                  # 512
        [-1024, 2],                 # -512
        [0x40000000, 2],           # Large number divided by 2

        # Edge cases
        [0x7FFFFFFF, 1],           # INT32_MAX / 1
        [0x7FFFFFFF, -1],          # INT32_MAX / -1
        [-0x80000000, 1],          # INT32_MIN / 1
        [-0x80000000, -1],         # INT32_MIN / -1 (overflow)

        # Exact division
        [100, 5],                   # 20
        [-100, 5],                  # -20
        [100, -5],                  # -20

        # Division with remainder (should truncate toward zero)
        [7, 2],                     # 3
        [-7, 2],                    # -3
        [7, -2],                    # -3
        [-7, -2],                   # 3

        # Large numbers
        [0x40000000, 0x10000],     # Large division
        [-0x40000000, 0x10000],    # Large negative division
    ]

    tests_passed = 0
    total_tests = len(div_tests)

    for test in div_tests:
        div_packet = div32(test)

        # Initialize division result as 32-bit signed value
        try:
            # Handle string inputs and convert to signed 32-bit integers
            dividend = test[0]
            divisor = test[1]
            if isinstance(dividend, str):
                dividend = int(dividend.split()[0])
            if isinstance(divisor, str):
                divisor = int(divisor.split()[0])

            # Convert to signed 32-bit values
            dividend = dividend & 0xFFFFFFFF
            dividend_signed = dividend if (
                dividend & 0x80000000) == 0 else dividend - 0x100000000

            divisor = divisor & 0xFFFFFFFF
            divisor_signed = divisor if (
                divisor & 0x80000000) == 0 else divisor - 0x100000000

            if divisor_signed == 0:
                raise ZeroDivisionError("Division by zero")

            # Perform signed division
            expected = int(dividend_signed / divisor_signed)
            expected = expected & 0xFFFFFFFF

            print("\nTest case:", [
                  f'{x} (0x{x & 0xFFFFFFFF:08x})' for x in test])
            print(f"Expected result:  {print_number(expected)}")

            # Send packet and receive result
            ser.write(div_packet)
            result = receive_result(ser)

            print(f"Received result:  {print_number(result)}")

            # Show if results match
            if result != expected:
                print(f"FAIL")
            else:
                print(f"PASS")
                tests_passed += 1

        except ZeroDivisionError:
            print(f"\nTest case: {test}")
            print("Division by zero detected - skipping")

        time.sleep(0.1)

    print("\n=== Test Summary ===")
    print(f"Tests passed: {
          tests_passed}/{total_tests} ({(tests_passed/total_tests)*100:.1f}%)")

    ser.close()


if __name__ == "__main__":
    main()
