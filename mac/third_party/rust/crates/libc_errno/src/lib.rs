// darwin port: libc_errno mini implementation
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct Errno(pub i32);

#[inline]
pub fn errno() -> Errno {
    #[cfg(any(target_os = "macos", target_os = "ios"))]
    unsafe {
        Errno(*libc::__error())
    }
    #[cfg(not(any(target_os = "macos", target_os = "ios")))]
    unsafe {
        Errno(*libc::__errno_location())
    }
}

#[inline]
pub fn set_errno(errno: Errno) {
    #[cfg(any(target_os = "macos", target_os = "ios"))]
    unsafe {
        *libc::__error() = errno.0;
    }
    #[cfg(not(any(target_os = "macos", target_os = "ios")))]
    unsafe {
        *libc::__errno_location() = errno.0;
    }
}
