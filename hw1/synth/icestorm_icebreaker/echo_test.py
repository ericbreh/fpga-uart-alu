import serial
import time

def test_uart_echo():
    port = '/dev/ttyUSB1'
    baudrate = 115200
    
    try:
        ser = serial.Serial(
            port=port,
            baudrate=baudrate,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=1
        )
        
        print(f"Connected to {port} at {baudrate} baud")
        success_count = 0
        
        for i in range(256):  # Test all bytes 0-255
            test_data = i.to_bytes(1, byteorder='big')
            print(f"\nSending: {i}")
            ser.write(test_data)
            
            response = ser.read(1)
            if response:
                received = int.from_bytes(response, byteorder='big')
                print(f"Received: {received}")
                
                if received == i:
                    print("PASS")
                    success_count += 1
                else:
                    print("FAIL")
            else:
                print("NO RESPONSE")
            
            time.sleep(0.1)
            
        print(f"\nResults: {success_count}/256 passed")
        ser.close()
        
    except serial.SerialException as e:
        print(f"Error opening {port}: {e}")

if __name__ == "__main__":
    test_uart_echo()