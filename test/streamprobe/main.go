package main

import (
	"fmt"
	"os"
)

const socketPath = "/var/snap/matrix/common/stream.socket"
const proxyHeader = "PROXY TCP4 198.51.100.7 10.0.0.1 40000 443\r\n"

func main() {
	if len(os.Args) < 2 {
		fail(fmt.Errorf("usage: streamprobe http <host> | stun"))
	}
	var result string
	var err error
	switch os.Args[1] {
	case "http":
		if len(os.Args) != 3 {
			fail(fmt.Errorf("usage: streamprobe http <host>"))
		}
		result, err = probeHTTP(socketPath, os.Args[2])
	case "stun":
		result, err = probeSTUN(socketPath)
	default:
		err = fmt.Errorf("unknown probe %q", os.Args[1])
	}
	if err != nil {
		fail(err)
	}
	fmt.Println(result)
}

func fail(err error) {
	fmt.Fprintln(os.Stderr, "streamprobe:", err)
	os.Exit(1)
}
