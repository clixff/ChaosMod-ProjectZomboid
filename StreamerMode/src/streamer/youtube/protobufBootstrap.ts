// Bun's `bun build --compile` does not bundle dynamic `require("long")`
// (called from `@protobufjs/inquire` inside `protobufjs/src/util/minimal.js`).
// In a compiled .exe the protobufjs `util.Long` ends up `null`, and
// `@grpc/proto-loader` later crashes with:
//   TypeError: util.Long.fromNumber is not a function
// when it resolves int64 default values during proto load.
//
// protobufjs picks up its Long class once, at module load time, via:
//   util.Long = util.global.dcodeIO?.Long || util.global.Long || util.inquire("long")
// So this module statically imports `long` and assigns it to `globalThis.Long`.
// As long as this module is imported BEFORE anything that transitively pulls
// in `protobufjs/util/minimal.js` (i.e. before `@grpc/grpc-js` or
// `@grpc/proto-loader`), protobufjs picks up the right Long class.
//
// Some bundlers wrap a default ESM export in a namespace object; defend
// against both shapes.
import LongDefault from "long";
import * as LongNS from "long";

interface MaybeLong {
  fromNumber?: unknown;
}

const candidate = LongDefault as unknown as MaybeLong;
const fallback = (LongNS as unknown as { default?: MaybeLong }).default;
const LongCtor: MaybeLong | undefined =
  typeof candidate?.fromNumber === "function"
    ? candidate
    : fallback && typeof fallback.fromNumber === "function"
      ? fallback
      : undefined;

if (!LongCtor) {
  throw new Error(
    "protobufBootstrap: failed to resolve `long` package — Long.fromNumber missing",
  );
}

(globalThis as unknown as { Long: unknown }).Long = LongCtor;
