//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify

import AWSS3StoragePlugin
import ClientRuntime
import AWSClientRuntime
import CryptoKit
import XCTest
import AWSS3

class AWSS3StoragePluginListObjectsIntegrationTests: AWSS3StoragePluginTestBase {

    /// Given: Multiple data object which is uploaded to a public path
    /// When: `Amplify.Storage.list` is run
    /// Then: The API should execute successfully and list objects for path
    func testListObjectsUploadedPublicData() async throws {
        let key = UUID().uuidString
        let data = Data(key.utf8)
        let uniqueStringPath = "public/\(key)"

        _ = try await Amplify.Storage.uploadData(path: .fromString(uniqueStringPath + "/test1"), data: data, options: nil).value

        let firstListResult = try await Amplify.Storage.list(path: .fromString(uniqueStringPath))

        // Validate the item was uploaded.
        XCTAssertEqual(firstListResult.items.filter({ $0.path.contains(uniqueStringPath)
        }).count, 1)

        _ = try await Amplify.Storage.uploadData(path: .fromString(uniqueStringPath + "/test2"), data: data, options: nil).value

        let secondListResult = try await Amplify.Storage.list(path: .fromString(uniqueStringPath))

        // Validate the item was uploaded.
        XCTAssertEqual(secondListResult.items.filter({ $0.path.contains(uniqueStringPath)
        }).count, 2)

        // Clean up
        _ = try await Amplify.Storage.remove(path: .fromString(uniqueStringPath + "/test1"))
        _ = try await Amplify.Storage.remove(path: .fromString(uniqueStringPath + "/test2"))
    }

    /// Given: Multiple data object which is uploaded to a protected path
    /// When: `Amplify.Storage.list` is run
    /// Then: The API should execute successfully and list objects for path
    func testListObjectsUploadedProtectedData() async throws {
        let key = UUID().uuidString
        let data = Data(key.utf8)
        var uniqueStringPath = ""

        // Sign in
        _ = try await Amplify.Auth.signIn(username: Self.user1, password: Self.password)

        _ = try await Amplify.Storage.uploadData(
            path: .fromIdentityID({ identityId in
                uniqueStringPath = "protected/\(identityId)/\(key)"
                return uniqueStringPath + "test1"
            }),
            data: data,
            options: nil).value

        let firstListResult = try await Amplify.Storage.list(path: .fromString(uniqueStringPath))

        // Validate the item was uploaded.
        XCTAssertEqual(firstListResult.items.filter({ $0.path.contains(uniqueStringPath)
        }).count, 1)

        _ = try await Amplify.Storage.uploadData(
            path: .fromIdentityID({ identityId in
                uniqueStringPath = "protected/\(identityId)/\(key)"
                return uniqueStringPath + "test2"
            }),
            data: data,
            options: nil).value

        let secondListResult = try await Amplify.Storage.list(path: .fromString(uniqueStringPath))

        // Validate the item was uploaded.
        XCTAssertEqual(secondListResult.items.filter({ $0.path.contains(uniqueStringPath)
        }).count, 2)

        // clean up
        _ = try await Amplify.Storage.remove(path: .fromString(uniqueStringPath + "test1"))
        _ = try await Amplify.Storage.remove(path: .fromString(uniqueStringPath + "test2"))

    }

    /// Given: Multiple data object which is uploaded to a private path
    /// When: `Amplify.Storage.list` is run
    /// Then: The API should execute successfully and list objects for path
    func testListObjectsUploadedPrivateData() async throws {
        let key = UUID().uuidString
        let data = Data(key.utf8)
        var uniqueStringPath = ""

        // Sign in
        _ = try await Amplify.Auth.signIn(username: Self.user1, password: Self.password)

        _ = try await Amplify.Storage.uploadData(
            path: .fromIdentityID({ identityId in
                uniqueStringPath = "private/\(identityId)/\(key)"
                return uniqueStringPath + "test1"
            }),
            data: data,
            options: nil).value

        let firstListResult = try await Amplify.Storage.list(path: .fromString(uniqueStringPath))

        // Validate the item was uploaded.
        XCTAssertEqual(firstListResult.items.filter({ $0.path.contains(uniqueStringPath)
        }).count, 1)

        _ = try await Amplify.Storage.uploadData(
            path: .fromIdentityID({ identityId in
                uniqueStringPath = "private/\(identityId)/\(key)"
                return uniqueStringPath + "test2"
            }),
            data: data,
            options: nil).value

        let secondListResult = try await Amplify.Storage.list(path: .fromString(uniqueStringPath))

        // Validate the item was uploaded.
        XCTAssertEqual(secondListResult.items.filter({ $0.path.contains(uniqueStringPath)
        }).count, 2)

        // clean up
        _ = try await Amplify.Storage.remove(path: .fromString(uniqueStringPath + "test1"))
        _ = try await Amplify.Storage.remove(path: .fromString(uniqueStringPath + "test2"))

    }

    /// Given: Give a unique key that does not exist
    /// When: `Amplify.Storage.list` is run
    /// Then: The API should execute and throw an error
    func testRemoveKeyDoesNotExist() async throws {
        let key = UUID().uuidString
        let uniqueStringPath = "public/\(key)"

        do {
            _ = try await Amplify.Storage.list(path: .fromString(uniqueStringPath))
        }
        catch {
            guard let storageError = error as? StorageError else {
                XCTFail("Error should be of type StorageError but got \(error)")
                return
            }
            guard case .keyNotFound(_, _, _, let underlyingError) = storageError else {
                XCTFail("Error should be of type keyNotFound but got \(error)")
                return
            }

            guard underlyingError is AWSS3.NotFound else {
                XCTFail("Underlying error should be of type AWSS3.NotFound but got \(error)")
                return
            }
        }
    }

    /// Given: Give a unique key where is user is NOT logged in
    /// When: `Amplify.Storage.list` is run
    /// Then: The API should execute and throw an error
    func testRemoveKeyWhenNotSignedInForPrivateKey() async throws {
        let key = UUID().uuidString
        let uniqueStringPath = "private/\(key)"

        do {
            _ = try await Amplify.Storage.list(path: .fromString(uniqueStringPath))
        }
        catch {
            guard let storageError = error as? StorageError else {
                XCTFail("Error should be of type StorageError but got \(error)")
                return
            }
            guard case .accessDenied(_, _, let underlyingError) = storageError else {
                XCTFail("Error should be of type keyNotFound but got \(error)")
                return
            }

            guard underlyingError is UnknownAWSHTTPServiceError else {
                XCTFail("Underlying error should be of type UnknownAWSHTTPServiceError but got \(error)")
                return
            }
        }
    }

}
