package main

/*
#include <stdint.h>

typedef struct MarsResult {
    double  final_scores[16];
    int32_t order[16];
    int32_t type_id;
    int32_t dominant;
    int32_t auxiliary;
    int32_t nfunc;
} MarsResult;
*/
import "C"

import (
	"math"
	"sort"
	"unsafe"
)

const nfunc = 16

var auxTable = [8][4]int32{
	{4, 5, 6, 7},   // Se
	{0, 1, 8, 9},   // Si
	{0, 1, 2, 3},   // Ne
	{0, 1, 2, 3},   // Ni
	{4, 5, 6, 7},   // Te
	{4, 5, 6, 7},   // Ti
	{8, 9, 10, 11}, // Fe
	{8, 9, 10, 11}, // Fi
}

func normalizeValue(v, m float64) float64 {
	if !(m > 0.0) || math.IsNaN(v) {
		return 0.0
	}
	r := (v / m) * 100.0
	if r < 0.0 {
		r = 0.0
	}
	if r > 100.0 {
		r = 100.0
	}
	return r
}

type pair struct {
	score float64
	index int32
}

//export mars_kernel_score
func mars_kernel_score(battle *C.double, dialogue *C.double, wb C.double, wd C.double, out *C.MarsResult) C.int32_t {
	if battle == nil || dialogue == nil || out == nil {
		return 1
	}
	b := unsafe.Slice((*float64)(unsafe.Pointer(battle)), nfunc)
	d := unsafe.Slice((*float64)(unsafe.Pointer(dialogue)), nfunc)
	o := (*[nfunc]float64)(unsafe.Pointer(&out.final_scores))
	ord := (*[nfunc]C.int32_t)(unsafe.Pointer(&out.order))

	var mb, md float64
	for i := 0; i < nfunc; i++ {
		if !math.IsNaN(b[i]) && b[i] > mb {
			mb = b[i]
		}
		if !math.IsNaN(d[i]) && d[i] > md {
			md = d[i]
		}
	}

	pairs := make([]pair, nfunc)
	for i := 0; i < nfunc; i++ {
		nb := normalizeValue(b[i], mb)
		nd := normalizeValue(d[i], md)
		o[i] = nb*float64(wb) + nd*float64(wd)
		pairs[i] = pair{score: o[i], index: int32(i)}
	}

	// 稳定降序：分数降序，平分索引升序
	sort.SliceStable(pairs, func(x, y int) bool {
		if pairs[x].score == pairs[y].score {
			return pairs[x].index < pairs[y].index
		}
		return pairs[x].score > pairs[y].score
	})

	for i := 0; i < nfunc; i++ {
		ord[i] = C.int32_t(pairs[i].index)
	}

	dom := pairs[0].index
	aux := pairs[1].index

	base := dom / 2
	sub := dom % 2
	var slot int32
	for k := 0; k < 4; k++ {
		if auxTable[base][k] == aux {
			slot = int32(k)
			break
		}
	}
	tid := base*8 + sub*4 + slot

	out.type_id = C.int32_t(tid)
	out.dominant = C.int32_t(dom)
	out.auxiliary = C.int32_t(aux)
	out.nfunc = C.int32_t(nfunc)
	return 0
}

//export mars_kernel_abi_version
func mars_kernel_abi_version() C.int32_t {
	return 1
}

//export mars_kernel_impl_name
func mars_kernel_impl_name() *C.char {
	return C.CString("go")
}

func main() {}