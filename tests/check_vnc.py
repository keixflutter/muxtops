#!/usr/bin/env python3
"""Authenticate to a real VNC server and verify desktop dimensions.

Requires OpenSSL 3 with its legacy provider. Passwords are read privately from
stdin or a prompt; no device alias, user credentials or IP is stored here.
"""
import argparse
import getpass
import sys
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


def connect(host, port, password):
    sock = socket.create_connection((host, port), timeout=10)
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
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=5901)
    parser.add_argument("--password-stdin", action="store_true")
    args = parser.parse_args()
    password = (sys.stdin.buffer.readline().rstrip(b"\r\n") if args.password_stdin
                else getpass.getpass("VNC password: ").encode())
    if not password:
        parser.error("A VNC password is required")
    assert connect(args.host, args.port, password), "Valid password rejected"
    print("VNC authentication and ServerInit: PASS")
