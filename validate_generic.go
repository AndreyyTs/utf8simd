//go:build !amd64 && !arm64

package utf8simd

import (
	"unicode/utf8"
)

// func ValidString(s string) bool {
// 	if len(s) == 0 {
// 		return true
// 	}
// 	return utf8.ValidString(s)
// }

func Valid(data []byte) bool {
	if len(data) == 0 {
		return true
	}
	return utf8.Valid(data)
}
