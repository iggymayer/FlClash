//go:build !cgo && !windows

package main

import "io"

func dialPipe(path string) (io.ReadWriteCloser, error) {
	// Never called on non-Windows platforms; the runtime.GOOS check in
	// startServer() ensures this. Defined so the package compiles.
	panic("dialPipe called on non-Windows platform")
}
