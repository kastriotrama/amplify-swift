//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS)
import Amplify
import AWSCognitoIdentityProvider
import Foundation

@available(iOS 17.4, macOS 13.5, *)
struct VerifyWebAuthnCredential: Action {
    let identifier = "VerifyWebAuthnCredential"
    let username: String
    let credentials: String
    let respondToAuthChallenge: RespondToAuthChallenge

    func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        do {
            let authEnv = try environment.authEnvironment()
            let userPoolEnv = try environment.userPoolEnvironment()
            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: username,
                credentialStoreClient: authEnv.credentialsClient
            )
            let request = await RespondToAuthChallengeInput.verifyWebauthCredential(
                username: username,
                credential: credentials,
                session: respondToAuthChallenge.session,
                asfDeviceId: asfDeviceId,
                environment: userPoolEnv
            )

            let cognitoClient = try userPoolEnv.cognitoUserPoolFactory()
            let response = try await cognitoClient.respondToAuthChallenge(input: request)

            guard let authenticationResult = response.authenticationResult,
                  let idToken = authenticationResult.idToken,
                  let accessToken = authenticationResult.accessToken,
                  let refreshToken = authenticationResult.refreshToken else {
                let message = "Response did not contain SignIn info"
                let error = SignInError.invalidServiceResponse(message: message)
                let event = SignInEvent(eventType: .throwAuthError(error))
                await dispatcher.send(event)
                return
            }
            let userPoolTokens = AWSCognitoUserPoolTokens(
                idToken: idToken,
                accessToken: accessToken,
                refreshToken: refreshToken
            )
            let signedInData = SignedInData(
                signedInDate: Date(),
                signInMethod: .apiBased(
                    .userAuth(preferredFirstFactor: .webAuthn)
                ),
                deviceMetadata: authenticationResult.deviceMetadata,
                cognitoUserPoolTokens: userPoolTokens
            )
            let event = WebAuthnEvent(
                eventType: .signedIn(signedInData)
            )
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            await dispatcher.send(event)
        } catch {
            logVerbose("\(#fileID) Caught error \(error)", environment: environment)
            let webAuthnError = WebAuthnError.service(error: error)
            let event = WebAuthnEvent(
                eventType: .error(webAuthnError, respondToAuthChallenge)
            )
            await dispatcher.send(event)
        }
    }
}

@available(iOS 17.4, macOS 13.5, *)
extension VerifyWebAuthnCredential: DefaultLogger { }

@available(iOS 17.4, macOS 13.5, *)
extension VerifyWebAuthnCredential: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "username": username.masked(),
            "credentials": credentials.masked(),
            "respondToAuthChallenge": respondToAuthChallenge.debugDictionary
        ]
    }
}

@available(iOS 17.4, macOS 13.5, *)
extension VerifyWebAuthnCredential: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

#endif
