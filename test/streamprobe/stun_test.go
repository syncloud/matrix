package main

import (
	"encoding/binary"
	"testing"
)

func bindingSuccess(transaction []byte, ip [4]byte, port uint16) []byte {
	message := make([]byte, 32)
	binary.BigEndian.PutUint16(message[0:2], stunBindingSuccess)
	binary.BigEndian.PutUint16(message[2:4], 12)
	binary.BigEndian.PutUint32(message[4:8], stunMagicCookie)
	copy(message[8:20], transaction)
	binary.BigEndian.PutUint16(message[20:22], stunXorMappedAddress)
	binary.BigEndian.PutUint16(message[22:24], 8)
	message[25] = 0x01
	binary.BigEndian.PutUint16(message[26:28], port^uint16(stunMagicCookie>>16))
	for i := 0; i < 4; i++ {
		message[28+i] = ip[i] ^ message[4+i]
	}
	return message
}

func TestParseBindingSuccessDecodesMappedAddress(t *testing.T) {
	transaction := []byte("abcdefghijkl")
	result, err := parseBindingSuccess(bindingSuccess(transaction, [4]byte{198, 51, 100, 7}, 40000), transaction)
	if err != nil {
		t.Fatal(err)
	}
	if result != "binding success 198.51.100.7:40000" {
		t.Fatal(result)
	}
}

func TestParseBindingSuccessRejectsOtherTransaction(t *testing.T) {
	message := bindingSuccess([]byte("abcdefghijkl"), [4]byte{198, 51, 100, 7}, 40000)
	if _, err := parseBindingSuccess(message, []byte("zzzzzzzzzzzz")); err == nil {
		t.Fatal("expected mismatch error")
	}
}

func TestParseBindingSuccessRejectsErrorResponse(t *testing.T) {
	transaction := []byte("abcdefghijkl")
	message := bindingSuccess(transaction, [4]byte{198, 51, 100, 7}, 40000)
	binary.BigEndian.PutUint16(message[0:2], 0x0111)
	if _, err := parseBindingSuccess(message, transaction); err == nil {
		t.Fatal("expected error response to be rejected")
	}
}
