// Copyright (c) 2023 Huawei Device Co., Ltd.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//! Ashmem provides interfaces for operating shared memory.

use std::ffi::{c_char, CString};

use cxx::SharedPtr;

/// Memory protection corresponding to PROT_NONE in C code.
pub const PROT_NONE: i32 = 0;
/// Memory protection corresponding to PROT_READ in C code.
pub const PROT_READ: i32 = 1;
/// Memory protection corresponding to PROT_WRITE in C code.
pub const PROT_WRITE: i32 = 2;
/// Memory protection corresponding to PROT_EXEC in C code.
pub const PROT_EXEC: i32 = 4;

#[cxx::bridge(namespace = "OHOS")]
/// Module Ashmem::ffi. Includes interfaces which will call c++ counterparts via
/// FFI.
pub mod ffi {
    unsafe extern "C++" {
        include!("../../include/ashmem.h");

        // global function
        /// Create an C++ Ashmem object managed by std::shared_ptr.
        /// # Safety
        /// Requires C-style string as parameter to specify the name of Ashmem.
        pub unsafe fn CreateAshmemStd(name: *const c_char, size: i32) -> SharedPtr<Ashmem>;

        /// Set protection flag of created ashmem specified by FD.
        pub fn AshmemSetProt(fd: i32, prot: i32) -> i32;

        /// Get size of created ashmem specified by FD.
        pub fn AshmemGetSize(fd: i32) -> i32;

        /// C++ void type.
        pub type c_void;
        /// Cast c_char to c_void
        /// # Safety
        pub unsafe fn AsVoidPtr(inPtr: *const c_char) -> *const c_void;

        /// Cast c_char to c_void
        /// # Safety
        pub unsafe fn AsCharPtr(inPtr: *const c_void) -> *const c_char;

        /// C++ Ashmem class.
        pub type Ashmem;

        // member function
        /// Close inner ashmem.
        pub fn CloseAshmem(self: &Ashmem) -> ();

        /// Map inner ashmem to user-space memory with specified map type.
        pub fn MapAshmem(self: &Ashmem, mapType: i32) -> bool;

        /// Map inner ashmem to user-space memory with read-write type.
        pub fn MapReadAndWriteAshmem(self: &Ashmem) -> bool;

        /// Map inner ashmem to user-space memory with read-only type.
        pub fn MapReadOnlyAshmem(self: &Ashmem) -> bool;

        /// UnMap inner ashmem.
        pub fn UnmapAshmem(self: &Ashmem) -> ();

        /// Set protection flag of inner ashmem.
        pub fn SetProtection(self: &Ashmem, protType: i32) -> bool;

        /// Get protection flag of inner ashmem.
        pub fn GetProtection(self: &Ashmem) -> i32;

        /// Get size of inner ashmem.
        pub fn GetAshmemSize(self: &Ashmem) -> i32;

        /// Write data to inner ashmem.
        /// # Safety
        /// Requires a C++-style void pointer as parameter to indicates data
        /// expected to be written.
        pub unsafe fn WriteToAshmem(
            self: &Ashmem,
            data: *const c_void,
            size: i32,
            offset: i32,
        ) -> bool;

        /// Read data from inner ashmem.
        /// # Safety
        /// Returns a C++-style void pointer to indicates data expected to be
        /// read.
        pub unsafe fn ReadFromAshmem(self: &Ashmem, size: i32, offset: i32) -> *const c_void;

        /// Get FD of inner ashmem.
        pub fn GetAshmemFd(self: &Ashmem) -> i32;
    }
}

/// Ashmem in rust.
pub struct Ashmem {
    c_ashmem: SharedPtr<ffi::Ashmem>,
}

/// Ashmem implementation.
impl Ashmem {
    /// Create an ashmem object.
    pub fn new(c_ashmem: SharedPtr<ffi::Ashmem>) -> Ashmem {
        Ashmem { c_ashmem }
    }

    /// Get corresponding fd.
    pub fn get_ashmem_fd(&self) -> i32 {
        self.c_ashmem.GetAshmemFd()
    }

    /// Get size of the shared memory.
    pub fn get_ashmem_size(&self) -> i32 {
        self.c_ashmem.GetAshmemSize()
    }

    /// Get memory protection flags.
    pub fn get_protection(&self) -> i32 {
        self.c_ashmem.GetProtection()
    }

    /// Set memory protection flags.
    pub fn set_protection(&self, prot_type: i32) -> bool {
        self.c_ashmem.SetProtection(prot_type)
    }

    /// Map the shared memory to user-space.
    pub fn map_ashmem(&self, prot_type: i32) -> bool {
        self.c_ashmem.MapAshmem(prot_type)
    }

    /// Map ashmem in read&write mode.
    pub fn map_read_write_ashmem(&self) -> bool {
        self.c_ashmem.MapReadAndWriteAshmem()
    }

    /// Map ashmem in read-only mode.
    pub fn map_read_only_ashmem(&self) -> bool {
        self.c_ashmem.MapReadOnlyAshmem()
    }

    /// Unmap ashmem.
    pub fn unmap_ashmem(&self) {
        self.c_ashmem.UnmapAshmem()
    }

    /// Close ashmem.
    pub fn close_ashmem(&self) {
        self.c_ashmem.CloseAshmem()
    }

    /// Write data to ashmem.
    /// # Safety
    /// Requires c-style data(*const c_char)
    pub unsafe fn write_to_ashmem(&self, data: *const c_char, size: i32, offset: i32) -> bool {
        let c_void_ptr = ffi::AsVoidPtr(data);
        self.c_ashmem.WriteToAshmem(c_void_ptr, size, offset)
    }

    /// Gets inner c_ashemem.
    ///
    /// # Safety
    /// Returns c++ opaque shared ptr.
    pub unsafe fn c_ashmem(&self) -> &SharedPtr<ffi::Ashmem> {
        &self.c_ashmem
    }

    /// Read data from ashmem.
    /// # Safety
    /// Returns c-style data(*const c_char)
    pub unsafe fn read_from_ashmem(&self, size: i32, offset: i32) -> *const c_char {
        let c_void_ptr = self.c_ashmem.ReadFromAshmem(size, offset);
        ffi::AsCharPtr(c_void_ptr)
    }
}

/// Create Ashmem struct in Rust, which holds a refrence to c++ Ashmem object.
/// # Safety
/// Transmits c-style string of `name`.
pub unsafe fn create_ashmem_instance(name: &str, size: i32) -> Option<Ashmem> {
    let c_name = CString::new(name).expect("CString::new Failed!");
    let name_ptr = c_name.as_ptr();
    let c_ashmem_ptr = ffi::CreateAshmemStd(name_ptr, size);

    if c_ashmem_ptr.is_null() {
        None
    } else {
        Some(Ashmem::new(c_ashmem_ptr))
    }
}
