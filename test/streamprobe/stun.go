package main

import (
	"bytes"
	"crypto/rand"
	"encoding/binary"
	"fmt"
	"io"
	"net"
)

const stunMagicCookie = 0x2112A442
const stunBindingRequest = 0x0001
const stunBindingSuccess = 0x0101
const stunXorMappedAddress = 0x0020

func probeSTUN(path string) (string, error) {
	transaction := make([]byte, 12)
	if _, err := rand.Read(transaction); err != nil {
		return "", err
	}
	request := make([]byte, 20)
	binary.BigEndian.PutUint16(request[0:2], stunBindingRequest)
	binary.BigEndian.PutUint32(request[4:8], stunMagicCookie)
	copy(request[8:20], transaction)
	conn, err := dial(path, request)
	if err != nil {
		return "", err
	}
	defer conn.Close()
	header := make([]byte, 20)
	if _, err := io.ReadFull(conn, header); err != nil {
		return "", fmt.Errorf("read header: %w", err)
	}
	attributes := make([]byte, binary.BigEndian.Uint16(header[2:4]))
	if _, err := io.ReadFull(conn, attributes); err != nil {
		return "", fmt.Errorf("read attributes: %w", err)
	}
	return parseBindingSuccess(append(header, attributes...), transaction)
}

func parseBindingSuccess(message []byte, transaction []byte) (string, error) {
	if len(message) < 20 {
		return "", fmt.Errorf("short message %x", message)
	}
	if binary.BigEndian.Uint16(message[0:2]) != stunBindingSuccess {
		return "", fmt.Errorf("not a binding success: %x", message[:20])
	}
	if binary.BigEndian.Uint32(message[4:8]) != stunMagicCookie || !bytes.Equal(message[8:20], transaction) {
		return "", fmt.Errorf("cookie or transaction mismatch: %x", message[:20])
	}
	key := message[4:20]
	for offset := 20; offset+4 <= len(message); {
		kind := binary.BigEndian.Uint16(message[offset : offset+2])
		length := int(binary.BigEndian.Uint16(message[offset+2 : offset+4]))
		value := message[offset+4:]
		if length > len(value) {
			return "", fmt.Errorf("truncated attribute %x", kind)
		}
		value = value[:length]
		if kind == stunXorMappedAddress && length >= 8 {
			port := binary.BigEndian.Uint16(value[2:4]) ^ uint16(stunMagicCookie>>16)
			address := make(net.IP, length-4)
			for i := range address {
				address[i] = value[4+i] ^ key[i]
			}
			return fmt.Sprintf("binding success %s", net.JoinHostPort(address.String(), fmt.Sprint(port))), nil
		}
		offset += 4 + length + (4-length%4)%4
	}
	return "", fmt.Errorf("no xor-mapped address in %x", message)
}
