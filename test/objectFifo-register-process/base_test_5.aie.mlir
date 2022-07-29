//===- base_test_5.aie.mlir --------------------------*- MLIR -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// (c) Copyright 2021 Xilinx Inc.
//
// Date: June 1st 2022
// 
//===----------------------------------------------------------------------===//

// RUN: aie-opt --aie-register-objectFifos %s | FileCheck %s

// CHECK: module @registerPatterns {
// CHECK:    %0 = AIE.tile(1, 2)
// CHECK:    %1 = AIE.tile(1, 3)
// CHECK:    %2 = AIE.objectFifo.createObjectFifo(%0, %1, 4) : !AIE.objectFifo<memref<16xi32>>
// CHECK:    %cst = arith.constant dense<1> : tensor<1xi32>
// CHECK:    %cst_0 = arith.constant dense<[0, 1, 1, 1, 2]> : tensor<5xi32>
// CHECK:    %c5 = arith.constant 5 : index
// CHECK:    func.func @producer_work() {
// CHECK:      return
// CHECK:    }
// CHECK:    %3 = AIE.core(%0) {
// CHECK:      %4 = AIE.objectFifo.acquire<Produce> (%2 : !AIE.objectFifo<memref<16xi32>>, 1) : !AIE.objectFifoSubview<memref<16xi32>>
// CHECK:      %5 = AIE.objectFifo.subview.access %4[0] : !AIE.objectFifoSubview<memref<16xi32>> -> memref<16xi32>
// CHECK:      func.call @producer_work() : () -> ()
// CHECK:      %c0 = arith.constant 0 : index
// CHECK:      %c3 = arith.constant 3 : index
// CHECK:      %c1 = arith.constant 1 : index
// CHECK:      scf.for %arg0 = %c0 to %c3 step %c1 {
// CHECK:        %8 = AIE.objectFifo.acquire<Produce> (%2 : !AIE.objectFifo<memref<16xi32>>, 1) : !AIE.objectFifoSubview<memref<16xi32>>
// CHECK:        %9 = AIE.objectFifo.subview.access %8[0] : !AIE.objectFifoSubview<memref<16xi32>> -> memref<16xi32>
// CHECK:        func.call @producer_work() : () -> ()
// CHECK:        AIE.objectFifo.release<Produce> (%2 : !AIE.objectFifo<memref<16xi32>>, 1)
// CHECK:      }
// CHECK:      %6 = AIE.objectFifo.acquire<Produce> (%2 : !AIE.objectFifo<memref<16xi32>>, 1) : !AIE.objectFifoSubview<memref<16xi32>>
// CHECK:      %7 = AIE.objectFifo.subview.access %6[0] : !AIE.objectFifoSubview<memref<16xi32>> -> memref<16xi32>
// CHECK:      func.call @producer_work() : () -> ()
// CHECK:      AIE.objectFifo.release<Produce> (%2 : !AIE.objectFifo<memref<16xi32>>, 2)
// CHECK:      AIE.end
// CHECK:    }
// CHECK:  }

module @registerPatterns  {
    %tile12 = AIE.tile(1, 2)
    %tile13 = AIE.tile(1, 3)

    %objFifo = AIE.objectFifo.createObjectFifo(%tile12, %tile13, 4) : !AIE.objectFifo<memref<16xi32>>

    %acquirePattern = arith.constant dense<[1]> : tensor<1xi32>
    %releasePattern = arith.constant dense<[0,1,1,1,2]> : tensor<5xi32>
    %length = arith.constant 5 : index
    func.func @producer_work() -> () { 
        return
    }

    AIE.objectFifo.registerProcess<Produce>(%objFifo : !AIE.objectFifo<memref<16xi32>>, %acquirePattern : tensor<1xi32>, %releasePattern : tensor<5xi32>, @producer_work, %length) 
}