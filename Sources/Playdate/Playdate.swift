@_exported import _CPlaydate
#if !hasFeature(Embedded)
import Darwin
#endif

@_cdecl("posix_memalign")
public func posix_memalign(
  _ memptr: UnsafeMutablePointer<UnsafeMutableRawPointer?>,
  _ alignment: Int,
  _ size: Int
) -> CInt {
  guard let ptr = malloc(Int(size + alignment - 1)) else {
    fatalError()
  }
  memptr.pointee = ptr
  return 0
}
