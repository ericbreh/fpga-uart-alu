import serial
import time
from threading import Thread

def create_packet(data: bytes) -> bytes:
    # Create packet with format [0xEC][0x00][LEN_LSB][LEN_MSB][DATA]
    packet_len = len(data) + 4  # data length + header size
    header = bytes([
        0xEC,                # Opcode for echo
        0x00,                # Reserved 
        packet_len & 0xFF,   # Length LSB
        packet_len >> 8      # Length MSB
    ])
    return header + data

def receive_data(ser):
    while True:
        if ser.in_waiting:
            data = ser.read(ser.in_waiting)
            print(f"Received: {data}")
        time.sleep(0.1)

def main():
    # Open serial port
    ser = serial.Serial(
        port='/dev/ttyUSB1',  # Adjust as needed
        baudrate=115200,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE
    )

    # Start receive thread
    rx_thread = Thread(target=receive_data, args=(ser,))
    rx_thread.daemon = True
    rx_thread.start()

    # Test packets
    test_msgs = [
        b"Hi",
        b"Hello World!",
        b"Test Packet"
    ]

    for msg in test_msgs:
        packet = create_packet(msg)
        print(f"\nSending packet: {packet.hex()}")
        print(f"Data: {msg}")
        ser.write(packet)
        time.sleep(1)

    ser.close()

if __name__ == "__main__":
    main()