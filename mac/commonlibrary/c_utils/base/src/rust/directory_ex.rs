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

//! Directory_ex provides an enhanced interface for some file and path related
//! operations.

/// File permissions for the owner of the file (user) - Read, write, and
/// execute.
pub const S_IRWXU: u32 = 0o700;

/// File permissions for the group - Read, write, and execute.
pub const S_IRWXG: u32 = 0o070;

/// File permissions for others (non-owner/non-group members) - Read, write, and
/// execute.
pub const S_IRWXO: u32 = 0o007;

/// File permission for the owner to read.
pub const S_IRUSR: u32 = 0o400;

/// File permission for the group to read.
pub const S_IRGRP: u32 = 0o040;

/// File permission for others (non-owner/non-group members) to read.
pub const S_IROTH: u32 = 0o004;

/// Maximum length of a file path in characters
pub const PATH_MAX: usize = 4096;

#[cxx::bridge(namespace = "OHOS")]
/// Module directory_ex::ffi. Includes interfaces which will call c++
/// counterparts via FFI.
pub mod ffi {
    #[allow(dead_code)]
    unsafe extern "C++" {
        include!("../../include/directory_ex.h");
        /// Get the full absolute path to the current program.
        pub fn RustGetCurrentProcFullFileName() -> String;

        /// Get the absolute path of the current program.
        pub fn RustGetCurrentProcPath() -> String;

        /// Obtain the path to the corresponding file by the full path.
        pub fn RustExtractFilePath(fileFullName: &String) -> String;

        /// Obtain the name to the corresponding file by the full path.
        pub fn RustExtractFileName(fileFullName: &String) -> String;

        /// Obtain the filename extension to the corresponding file by the full
        /// path.
        pub fn RustExtractFileExt(fileName: &String) -> String;

        /// Determine whether the path has ended with '/', and returns the path
        /// after removing '/', otherwise returns the path directly.
        pub fn RustExcludeTrailingPathDelimiter(path: &String) -> String;

        /// Determine whether the path has ended with "/", and returns the path
        /// after adding '/', otherwise returns the path directly.
        pub fn RustIncludeTrailingPathDelimiter(path: &String) -> String;

        /// Get names of all files under `path` recursively.
        pub fn RustGetDirFiles(path: &String, files: &mut Vec<String>);

        /// Judge if the path is empty.
        pub fn IsEmptyFolder(path: &CxxString) -> bool;

        /// If there are problems such as 'Permission Denied', the creation may
        /// also fail.
        pub fn ForceCreateDirectory(path: &CxxString) -> bool;

        /// Delete the specified dir.
        pub fn ForceRemoveDirectory(path: &CxxString) -> bool;

        /// Remove the file specified by fileName.
        pub fn RemoveFile(fileName: &CxxString) -> bool;

        /// Get the folder size(bytes).
        pub fn GetFolderSize(path: &CxxString) -> u64;

        /// Change the file authority.
        pub fn ChangeModeFile(fileName: &CxxString, mode: &u32) -> bool;

        /// Change authority of the directory specified by path and all of its
        /// subdirectories.
        pub fn ChangeModeDirectory(path: &CxxString, mode: &u32) -> bool;

        /// Get real path from relative path.
        pub fn RustPathToRealPath(path: &String, realPath: &mut String) -> bool;
    }
}
