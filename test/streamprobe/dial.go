package main

import (
	"fmt"
	"net"
	"time"
)

func dial(path string, payload []byte) (net.Conn, error) {
	conn, err := net.DialTimeout("unix", path, 10*time.Second)
	if err != nil {
		return nil, err
	}
	if err := conn.SetDeadline(time.Now().Add(20 * time.Second)); err != nil {
		conn.Close()
		return nil, err
	}
	if _, err := conn.Write(append([]byte(proxyHeader), payload...)); err != nil {
		conn.Close()
		return nil, fmt.Errorf("write: %w", err)
	}
	return conn, nil
}
