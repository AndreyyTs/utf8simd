//go:build amd64 || arm64

package utf8simd

import (
	_ "unsafe"
)

//go:noescape
// func ValidString(s string) bool

//go:noescape
func Valid(data []byte) bool
