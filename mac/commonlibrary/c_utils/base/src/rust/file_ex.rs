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

//! File_ex provides interfaces for operating on file.

#[cxx::bridge(namespace = "OHOS")]
/// Module file_ex::ffi. Includes interfaces which will call c++ counterparts
/// via FFI.
pub mod ffi {
    #[allow(dead_code)]
    unsafe extern "C++" {
        include!("../../include/file_ex.h");
        /// Read contents as a string from the specified file.
        pub fn RustLoadStringFromFile(filePath: &String, content: &mut String) -> bool;

        /// Write contents of a string to the specified file.
        pub fn RustSaveStringToFile(filePath: &String, content: &String, truncated: bool) -> bool;

        /// Read contents as a string from the file specified by its fd.
        pub fn RustLoadStringFromFd(fd: i32, content: &mut String) -> bool;

        /// Write contents of a string to the file specified by its fd.
        pub fn RustSaveStringToFd(fd: i32, content: &String) -> bool;

        /// Read contents as a vector from the specified file.
        pub fn RustLoadBufferFromFile(filePath: &String, content: &mut Vec<c_char>) -> bool;

        /// Write contents of a vector to the specified file.
        pub fn RustSaveBufferToFile(
            filePath: &String,
            content: &Vec<c_char>,
            truncated: bool,
        ) -> bool;

        /// Check if the specified file exists.
        pub fn RustFileExists(fileName: &String) -> bool;

        /// Check if the file contains specified contents in string.
        pub fn RustStringExistsInFile(
            fileName: &String,
            subStr: &String,
            caseSensitive: bool,
        ) -> bool;

        /// Get amount of the specified string in the file.
        pub fn RustCountStrInFile(fileName: &String, subStr: &String, caseSensitive: bool) -> i32;
    }
}
