// RUN: mlir-tblgen -gen-rewriters -I %S/../../include %s | FileCheck %s

include "mlir/IR/OpBase.td"

def Test_Dialect : Dialect {
  let name = "test";
}
class NS_Op<string mnemonic, list<OpTrait> traits> :
    Op<Test_Dialect, mnemonic, traits>;

def ThreeResultOp : NS_Op<"three_result_op", []> {
  let arguments = (ins I32:$input);
  let results = (outs I32:$r1, I32:$r2, I32:$r3);
}

def TwoResultOp : NS_Op<"two_result_op", []> {
  let arguments = (ins I32:$input);
  let results = (outs I32:$r1, I32:$r2);
}

def OneResultOp : NS_Op<"one_result_op", []> {
  let arguments = (ins I32:$input);
  let results = (outs I32:$r1);
}

def : Pattern<(ThreeResultOp $input), [
        (OneResultOp $input),
        (OneResultOp $input),
        (OneResultOp $input)
      ]>;

// CHECK-LABEL: struct GeneratedConvert0

// CHECK: void rewrite(
// CHECK: 	auto vOneResultOp0 = rewriter.create<OneResultOp>(
// CHECK: 	auto vOneResultOp1 = rewriter.create<OneResultOp>(
// CHECK: 	auto vOneResultOp2 = rewriter.create<OneResultOp>(
// CHECK: 	rewriter.replaceOp(op, {vOneResultOp0, vOneResultOp1, vOneResultOp2});

def : Pattern<(ThreeResultOp $input), [
        (OneResultOp (OneResultOp:$interm $input)),
        (OneResultOp $interm),
        (OneResultOp (OneResultOp $interm))
      ]>;

// CHECK-LABEL: struct GeneratedConvert1

// CHECK:      void rewrite(
// CHECK:        auto interm = rewriter.create<OneResultOp>(
// CHECK-NEXT:     /*input=*/s.input
// CHECK:        auto vOneResultOp0 = rewriter.create<OneResultOp>(
// CHECK-NEXT:     /*input=*/interm
// CHECK:        auto vOneResultOp1 = rewriter.create<OneResultOp>(
// CHECK-NEXT:     /*input=*/interm
// CHECK:        auto vOneResultOp2 = rewriter.create<OneResultOp>(
// CHECK-NEXT:     /*input=*/interm
// CHECK:        auto vOneResultOp3 = rewriter.create<OneResultOp>(
// CHECK-NEXT:     /*input=*/vOneResultOp2
// CHECK:        rewriter.replaceOp(op, {vOneResultOp0, vOneResultOp1, vOneResultOp3});

// Test more result patterns than needed for replacement
// ---
def AdditionalOp : NS_Op<"additional_one_result_op", []> {
  let arguments = (ins I32:$input);
  let results = (outs I32:$r1);
}
def : Pattern<(TwoResultOp $input), [
        // Additional op generated to help build the final result but not
        // directly used to replace the source op
        (AdditionalOp:$interm $input),

        (OneResultOp $interm),
        (OneResultOp $input)
      ]>;

// CHECK-LABEL: struct GeneratedConvert2

// CHECK:      auto interm = rewriter.create<AdditionalOp>(
// CHECK:      auto vOneResultOp0 = rewriter.create<OneResultOp>(
// CHECK-NEXT:   /*input=*/interm
// CHECK:      auto vOneResultOp1 = rewriter.create<OneResultOp>(
// CHECK:      rewriter.replaceOp(op, {vOneResultOp0, vOneResultOp1});
