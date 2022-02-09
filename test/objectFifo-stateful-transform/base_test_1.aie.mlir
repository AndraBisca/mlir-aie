//===- base_test_1.aie.mlir --------------------------*- MLIR -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// (c) Copyright 2021 Xilinx Inc.
//
// Date: October 26th 2021
// 
//===----------------------------------------------------------------------===//

// RUN: aie-opt --aie-objectFifo-stateful-transform %s | FileCheck %s

// CHECK-LABEL: module @singleCoreSingleFifo  {
// CHECK-NEXT:    %0 = AIE.tile(1, 2)
// CHECK-NEXT:    %1 = AIE.tile(1, 3)
// CHECK-NEXT:    %2 = AIE.buffer(%0) {sym_name = "buff0"} : memref<16xi32>
// CHECK-NEXT:    %3 = AIE.lock(%0, 0)
// CHECK-NEXT:    %4 = AIE.buffer(%0) {sym_name = "buff1"} : memref<16xi32>
// CHECK-NEXT:    %5 = AIE.lock(%0, 1)
// CHECK-NEXT:    %6 = AIE.buffer(%0) {sym_name = "buff2"} : memref<16xi32>
// CHECK-NEXT:    %7 = AIE.lock(%0, 2)
// CHECK-NEXT:    %8 = AIE.buffer(%0) {sym_name = "buff3"} : memref<16xi32>
// CHECK-NEXT:    %9 = AIE.lock(%0, 3)
// CHECK-NEXT:    func @some_work(%arg0: memref<16xi32>) {
// CHECK-NEXT:      return
// CHECK-NEXT:    }
// CHECK-NEXT:    %10 = AIE.core(%0)  {
// CHECK-NEXT:      AIE.useLock(%3, Acquire, 0)
// CHECK-NEXT:      AIE.useLock(%5, Acquire, 0)
// CHECK-NEXT:      call @some_work(%2) : (memref<16xi32>) -> ()
// CHECK-NEXT:      call @some_work(%4) : (memref<16xi32>) -> ()
// CHECK-NEXT:      AIE.useLock(%7, Acquire, 0)
// CHECK-NEXT:      call @some_work(%2) : (memref<16xi32>) -> ()
// CHECK-NEXT:      call @some_work(%4) : (memref<16xi32>) -> ()
// CHECK-NEXT:      call @some_work(%6) : (memref<16xi32>) -> ()
// CHECK-NEXT:      AIE.useLock(%3, Release, 1)
// CHECK-NEXT:      AIE.useLock(%5, Release, 1)
// CHECK-NEXT:      AIE.useLock(%9, Acquire, 0)
// CHECK-NEXT:      call @some_work(%6) : (memref<16xi32>) -> ()
// CHECK-NEXT:      call @some_work(%8) : (memref<16xi32>) -> ()
// CHECK-NEXT:      call @some_work(%6) : (memref<16xi32>) -> ()
// CHECK-NEXT:      call @some_work(%8) : (memref<16xi32>) -> ()
// CHECK-NEXT:      AIE.end
// CHECK-NEXT:    }
// CHECK-NEXT:  }

module @singleCoreSingleFifo {
    %tile12 = AIE.tile(1, 2)
    %tile13 = AIE.tile(1, 3)

    %objFifo = AIE.objectFifo.createObjectFifo(%tile12, %tile13, 4) : !AIE.objectFifo<memref<16xi32>>

    func @some_work(%line_in:memref<16xi32>) -> () {
        return
    }

    %core12 = AIE.core(%tile12) {
        // this acquires 2 elements
        %subview0 = AIE.objectFifo.acquire{ port = "produce" }(%objFifo : !AIE.objectFifo<memref<16xi32>>, 2) : !AIE.objectFifoSubview<memref<16xi32>>
        %elem00 = AIE.objectFifo.subview.access %subview0[0] : !AIE.objectFifoSubview<memref<16xi32>> -> memref<16xi32>
        %elem01 = AIE.objectFifo.subview.access %subview0[1] : !AIE.objectFifoSubview<memref<16xi32>> -> memref<16xi32>
        call @some_work(%elem00) : (memref<16xi32>) -> ()
        call @some_work(%elem01) : (memref<16xi32>) -> ()

        // this should only acquire one new element, previous 2 are still acquired
        %subview1 = AIE.objectFifo.acquire{ port = "produce" }(%objFifo : !AIE.objectFifo<memref<16xi32>>, 3) : !AIE.objectFifoSubview<memref<16xi32>>
        %elem10 = AIE.objectFifo.subview.access %subview1[0] : !AIE.objectFifoSubview<memref<16xi32>> -> memref<16xi32>
        %elem11 = AIE.objectFifo.subview.access %subview1[1] : !AIE.objectFifoSubview<memref<16xi32>> -> memref<16xi32>
        %elem12 = AIE.objectFifo.subview.access %subview1[2] : !AIE.objectFifoSubview<memref<16xi32>> -> memref<16xi32>
        call @some_work(%elem10) : (memref<16xi32>) -> ()
        call @some_work(%elem11) : (memref<16xi32>) -> ()
        call @some_work(%elem12) : (memref<16xi32>) -> ()

        // one new acquire should take place
        AIE.objectFifo.release{ port = "produce" }(%objFifo : !AIE.objectFifo<memref<16xi32>>, 1)
        AIE.objectFifo.release{ port = "produce" }(%objFifo : !AIE.objectFifo<memref<16xi32>>, 1)
        %subview2 = AIE.objectFifo.acquire{ port = "produce" }(%objFifo : !AIE.objectFifo<memref<16xi32>>, 2) : !AIE.objectFifoSubview<memref<16xi32>>
        %elem20 = AIE.objectFifo.subview.access %subview2[0] : !AIE.objectFifoSubview<memref<16xi32>> -> memref<16xi32>
        %elem21 = AIE.objectFifo.subview.access %subview2[1] : !AIE.objectFifoSubview<memref<16xi32>> -> memref<16xi32>
        call @some_work(%elem20) : (memref<16xi32>) -> () 
        call @some_work(%elem21) : (memref<16xi32>) -> ()

        // no new acquires should take place, elem30 should be thrid element of objFifo (with index 2)
        %subview3 = AIE.objectFifo.acquire{ port = "produce" }(%objFifo : !AIE.objectFifo<memref<16xi32>>, 2) : !AIE.objectFifoSubview<memref<16xi32>>
        %elem30 = AIE.objectFifo.subview.access %subview3[0] : !AIE.objectFifoSubview<memref<16xi32>> -> memref<16xi32>
        %elem31 = AIE.objectFifo.subview.access %subview3[1] : !AIE.objectFifoSubview<memref<16xi32>> -> memref<16xi32>
        //%elem32 = AIE.subview.access %subview3[2] : !AIE.subview<memref<16xi32>> -> memref<16xi32> // expected to fail if this line is uncommented
        call @some_work(%elem30) : (memref<16xi32>) -> ()
        call @some_work(%elem31) : (memref<16xi32>) -> ()

        AIE.end
    }
}