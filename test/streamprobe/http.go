package main

import (
	"bufio"
	"fmt"
	"io"
	"net/http"
)

func probeHTTP(path string, host string) (string, error) {
	request := fmt.Sprintf("GET /_matrix/client/versions HTTP/1.1\r\nHost: %s\r\nConnection: close\r\n\r\n", host)
	conn, err := dial(path, []byte(request))
	if err != nil {
		return "", err
	}
	defer conn.Close()
	response, err := http.ReadResponse(bufio.NewReader(conn), nil)
	if err != nil {
		return "", fmt.Errorf("read response: %w", err)
	}
	defer response.Body.Close()
	body, err := io.ReadAll(response.Body)
	if err != nil {
		return "", fmt.Errorf("read body: %w", err)
	}
	return fmt.Sprintf("%s %s\n%s", response.Proto, response.Status, body), nil
}
