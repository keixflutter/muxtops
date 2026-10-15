#!/usr/bin/env python3
"""Check the real SSH tunnel, VNC authentication and desktop dimensions.

Mac test helper: uses OpenSSL's legacy DES implementation for VNC challenge
response. Password is read over SSH and never printed or saved locally.
"""
import socket
import struct
import subprocess


def receive(sock, count):
    data = b""
    while len(data) < count:
        chunk = sock.recv(count - len(data))
        if not chunk:
            raise RuntimeError("VNC disconnected early")
        data += chunk
    return data


def connect(password):
    sock = socket.create_connection(("127.0.0.1", 15901), timeout=10)
    try:
        assert receive(sock, 12) == b"RFB 003.008\n"
        sock.sendall(b"RFB 003.008\n")
        types = receive(sock, receive(sock, 1)[0])
        assert 2 in types, "VNC password authentication unavailable"
        assert 1 not in types, "Server unexpectedly permits no authentication"
        sock.sendall(b"\x02")
        challenge = receive(sock, 16)
        key = bytes(int(f"{byte:08b}"[::-1], 2) for byte in password[:8].ljust(8, b"\0"))
        encrypted = subprocess.run(
            ["openssl", "enc", "-des-ecb", "-provider", "legacy", "-provider", "default",
             "-K", key.hex(), "-nopad", "-nosalt"],
            input=challenge, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True,
        ).stdout
        sock.sendall(encrypted)
        result = struct.unpack("!I", receive(sock, 4))[0]
        if result:
            return False
        sock.sendall(b"\x01")  # Shared viewer; do not disconnect other clients.
        init = receive(sock, 24)
        width, height = struct.unpack("!HH", init[:4])
        length = struct.unpack("!I", init[20:24])[0]
        name = receive(sock, length).decode(errors="replace")
        assert (width, height) == (1280, 720), (width, height)
        print(f"Authenticated VNC desktop: {width}x{height}; {name}")
        return True
    finally:
        sock.close()


if __name__ == "__main__":
    password = subprocess.check_output(
        ["ssh", "redmi", "cat .config/muxtops/vnc-password.txt"]
    ).strip()
    assert password, "No test password configured on Redmi"
    assert connect(password), "Valid password rejected"
    print("VNC authentication and ServerInit: PASS")
