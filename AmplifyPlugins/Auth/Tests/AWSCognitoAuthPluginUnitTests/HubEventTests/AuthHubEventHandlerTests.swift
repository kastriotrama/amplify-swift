//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import  Foundation

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentity
import AWSCognitoIdentityProvider

class AuthHubEventHandlerTests: XCTestCase {

    let networkTimeout = TimeInterval(2)
    var plugin: AWSCognitoAuthPlugin!

    /// Test whether HubEvent emits a signedIn event for mocked signIn operation
    ///
    /// - Given: A listener to hub events
    /// - When:
    ///    - I mock a succesful signInAPI operation event
    /// - Then:
    ///    - I should receive a signedIn hub event
    ///
    func testSignedInHubEvent() async {

        configurePluginForSignInEvent()

        let pluginOptions = AWSAuthSignInOptions(metadata: ["somekey": "somevalue"])
        let options = AuthSignInRequest.Options(pluginOptions: pluginOptions)

        let hubEventExpectation = expectation(description: "Should receive the hub event")
        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                hubEventExpectation.fulfill()
            default:
                break
            }
        }

        do {
            _ = try await plugin.signIn(username: "username", password: "password", options: options)
        } catch {
            XCTFail("Received failure with error \(error)")
        }

        await fulfillment(
            of: [hubEventExpectation],
            timeout: networkTimeout
        )
    }

    /// Test whether HubEvent emits a signOut event for mocked signOut operation
    ///
    /// - Given: A listener to hub events
    /// - When:
    ///    - I mock a succesful signOutAPI operation event
    /// - Then:
    ///    - I should receive a signedOut hub event
    ///
    func testSignedOutHubEvent() async throws {

        configurePluginForSignOutEvent()

        let hubEventExpectation = expectation(description: "Should receive the hub event")
        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedOut:
                hubEventExpectation.fulfill()
            default:
                break
            }
        }

        _ = await plugin.signOut(options: nil)
        await fulfillment(
            of: [hubEventExpectation],
            timeout: networkTimeout
        )
    }

    /// Test whether HubEvent emits a confirmSignedIn event for mocked signIn operation
    ///
    /// - Given: A listener to hub events
    /// - When:
    ///    - I mock a succesful confirmSignInAPI operation event
    /// - Then:
    ///    - I should receive a signedIn hub event
    ///
    func testConfirmSignedInHubEvent() async {

        configurePluginForConfirmSignInEvent()

        let hubEventExpectation = expectation(description: "Should receive the hub event")
        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                hubEventExpectation.fulfill()
            default:
                break
            }
        }

        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "code")
        } catch {
            XCTFail("Received failure with error \(error)")
        }

        await fulfillment(
            of: [hubEventExpectation],
            timeout: networkTimeout
        )
    }

    /// Test whether HubEvent emits a deletedUser event for mocked delete user operation
    ///
    /// - Given: A listener to hub events
    /// - When:
    ///    - I mock a succesful deleteUserAPI operation event
    /// - Then:
    ///    - I should receive a user deleted hub event
    ///
    func testUserDeletedHubEvent() async {

        configurePluginForDeleteUserEvent()

        let hubEventExpectation = expectation(description: "Should receive the hub event")
        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.userDeleted:
                hubEventExpectation.fulfill()
            default:
                break
            }
        }

        do {
            try await plugin.deleteUser()
        } catch {
            XCTFail("Received failure with error \(error)")
        }

        await fulfillment(
            of: [hubEventExpectation],
            timeout: networkTimeout
        )
    }

    /// Test whether HubEvent emits a sessionExpired event for mocked fetchSession operation with expired tokens
    ///
    /// - Given: A listener to hub events
    /// - When:
    ///    - I mock a succesful fetchSessionAPI operation event with expired tokens
    /// - Then:
    ///    - I should receive a sessionExpired hub event
    ///
    func testSessionExpiredHubEvent() async throws {

        configurePluginForSessionExpiredEvent()

        let hubEventExpectation = expectation(description: "Should receive the hub event")
        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.sessionExpired:
                hubEventExpectation.fulfill()
            default:
                break
            }
        }
        _ = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())
        await fulfillment(
            of: [hubEventExpectation],
            timeout: networkTimeout
        )
    }

#if os(iOS) || os(macOS)
    /// Test whether HubEvent emits a mocked signedIn event for webUI signIn
    ///
    /// - Given: A listener to hub events
    /// - When:
    ///    - I mock a succesful webui signIn operation event
    /// - Then:
    ///    - I should receive a signedIn hub event
    ///
    @MainActor
    func testWebUISignedInHubEvent() async {
        let mockIdentityProvider = MockIdentityProvider()

        let initialState = AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured, .notStarted)

        configurePlugin(initialState: initialState, userPoolFactory: mockIdentityProvider)
        let hubEventExpectation = expectation(description: "Should receive the hub event")
        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                hubEventExpectation.fulfill()
            default:
                break
            }
        }

        do {
            _ = try await plugin.signInWithWebUI(presentationAnchor: AuthUIPresentationAnchor(), options: nil)
        } catch {
            XCTFail("Received failure with error \(error)")
        }
        await fulfillment(of: [hubEventExpectation], timeout: 10)
    }

    /// Test whether HubEvent emits a mocked signedIn event for social provider signIn
    ///
    /// - Given: A listener to hub events
    /// - When:
    ///    - I mock a succesful social provider webui signIn operation event
    /// - Then:
    ///    - I should receive a signedIn hub event
    ///
    @MainActor
    func testSocialWebUISignedInHubEvent() async {
        let mockIdentityProvider = MockIdentityProvider()

        let initialState = AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured, .notStarted)

        configurePlugin(initialState: initialState, userPoolFactory: mockIdentityProvider)
        let hubEventExpectation = expectation(description: "Should receive the hub event")
        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                hubEventExpectation.fulfill()
            default:
                break
            }
        }
        do {
            _ = try await plugin.signInWithWebUI(for: .amazon, presentationAnchor: AuthUIPresentationAnchor(), options: nil)
        } catch {
            XCTFail("Received failure with error \(error)")
        }
        await fulfillment(of: [hubEventExpectation], timeout: 10)
    }
#endif

    /// Test whether HubEvent emits a federatedToIdentityPool event for mocked federated operation
    ///
    /// - Given: A listener to hub events
    /// - When:
    ///    - I mock a succesfull federateToIdentityPool operation event
    /// - Then:
    ///    - I should receive a federatedToIdentityPool hub event
    ///
    func testFederatedToIdentityPoolHubEvent() async throws {

        configurePluginForFederationEvent()

        let hubEventExpectation = expectation(description: "Should receive the hub event")
        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.federateToIdentityPoolAPI:
                hubEventExpectation.fulfill()
            default:
                break
            }
        }
        _ = try await  plugin.federateToIdentityPool(withProviderToken: "someToken", for: .facebook)

        await fulfillment(
            of: [hubEventExpectation],
            timeout: networkTimeout
        )
    }

    /// Test whether HubEvent emits a federationToIdentityPoolCleared event for mocked federated operation
    ///
    /// - Given: A listener to hub events
    /// - When:
    ///    - I mock a succesfull clearFederationToIdentityPool operation event
    /// - Then:
    ///    - I should receive a federationToIdentityPoolCleared hub event
    ///
    func testClearedFederationHubEvent() async throws {

        configurePluginForClearedFederationEvent()

        let hubEventExpectation = expectation(description: "Should receive the hub event")
        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.clearedFederationToIdentityPoolAPI:
                hubEventExpectation.fulfill()
            default:
                break
            }
        }

        _ = try await plugin.federateToIdentityPool(withProviderToken: "something", for: .facebook)
        try await plugin.clearFederationToIdentityPool()

        await fulfillment(
            of: [hubEventExpectation],
            timeout: networkTimeout
        )
    }

    private func configurePluginForSignInEvent() {
        let mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { _ in
            RespondToAuthChallengeOutput(
                authenticationResult: .init(
                    accessToken: Defaults.validAccessToken,
                    expiresIn: 300,
                    idToken: "idToken",
                    newDeviceMetadata: nil,
                    refreshToken: "refreshToken",
                    tokenType: ""),
                challengeName: .none,
                challengeParameters: [:],
                session: "session")
        })

        let initialState = AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured, .notStarted)

        configurePlugin(initialState: initialState, userPoolFactory: mockIdentityProvider)
    }

    private func configurePluginForConfirmSignInEvent() {
        let initialState = AuthState.configured(
            AuthenticationState.signingIn(.resolvingChallenge(
                .waitingForAnswer(.testData(), .apiBased(.userSRP), .confirmSignInWithTOTPCode),
                .smsMfa,
                .apiBased(.userSRP))),
            AuthorizationState.sessionEstablished(.testData),
            .notStarted)

        let mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                return .testData()
            })

        configurePlugin(initialState: initialState, userPoolFactory: mockIdentityProvider)
    }

    private func configurePluginForDeleteUserEvent() {
        let initialState = AuthState.configured(
            AuthenticationState.signedIn(
                SignedInData(signedInDate: Date(),
                             signInMethod: .apiBased(.userSRP),
                             cognitoUserPoolTokens: AWSCognitoUserPoolTokens.testData)),
            AuthorizationState.sessionEstablished(AmplifyCredentials.testData),
            .notStarted)

        let mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in
                RevokeTokenOutput()
            }, mockGlobalSignOutResponse: { _ in
                GlobalSignOutOutput()
            },
            mockDeleteUserOutput: { _ in
                DeleteUserOutput()
            }
        )

        configurePlugin(initialState: initialState, userPoolFactory: mockIdentityProvider)
    }

    private func configurePluginForSignOutEvent() {
        let initialState = AuthState.configured(
            AuthenticationState.signedIn(
                SignedInData(signedInDate: Date(),
                             signInMethod: .apiBased(.userSRP),
                             cognitoUserPoolTokens: AWSCognitoUserPoolTokens.testData)),
            AuthorizationState.sessionEstablished(AmplifyCredentials.testData),
            .notStarted)

        let mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in
                RevokeTokenOutput()
            },
            mockGlobalSignOutResponse: { _ in
                GlobalSignOutOutput()
            }
        )

        configurePlugin(initialState: initialState, userPoolFactory: mockIdentityProvider)
    }

    private func configurePluginForFederationEvent() {
        let initialState = AuthState.configured(
            AuthenticationState.signedOut(.testData),
            AuthorizationState.configured,
            .notStarted)

        let mockIdentityProvider = MockIdentityProvider()

        configurePlugin(initialState: initialState, userPoolFactory: mockIdentityProvider)
    }

    private func configurePluginForClearedFederationEvent() {
        let initialState = AuthState.configured(
            AuthenticationState.federatedToIdentityPool,
            AuthorizationState.sessionEstablished(AmplifyCredentials.testData),
            .notStarted)

        let mockIdentityProvider = MockIdentityProvider()

        configurePlugin(initialState: initialState, userPoolFactory: mockIdentityProvider)
    }

    private func configurePluginForSessionExpiredEvent() {
        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testDataWithExpiredTokens),
            .notStarted)

        let mockIdentityProvider = MockIdentityProvider(
            mockInitiateAuthResponse: { _ in
                throw AWSCognitoIdentityProvider.NotAuthorizedException()
            })

        configurePlugin(initialState: initialState, userPoolFactory: mockIdentityProvider)
    }

    private func urlSessionMock() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func configurePlugin(initialState: AuthState, userPoolFactory: CognitoUserPoolBehavior) {
        plugin = AWSCognitoAuthPlugin()

        let mockTokenResult = ["id_token": AWSCognitoUserPoolTokens.testData.idToken,
                               "access_token": AWSCognitoUserPoolTokens.testData.accessToken,
                               "refresh_token": AWSCognitoUserPoolTokens.testData.refreshToken,
                               "expires_in": 10] as [String: Any]
        let mockJson = try! JSONSerialization.data(withJSONObject: mockTokenResult)
        let mockState = "someState"
        let mockProof = "someProof"
        let hostedUIconfig = HostedUIConfigurationData(clientId: "clientId", oauth: .init(
            domain: "cognitodomain",
            scopes: ["name"],
            signInRedirectURI: "myapp://",
            signOutRedirectURI: "myapp://"))
        let mockHostedUIResult: Result<[URLQueryItem], HostedUIError> = .success([
            .init(name: "state", value: mockState),
            .init(name: "code", value: mockProof)
        ])
        MockURLProtocol.requestHandler = { _ in
            return (HTTPURLResponse(), mockJson)
        }

        func sessionFactory() -> HostedUISessionBehavior {
            MockHostedUISession(result: mockHostedUIResult)
        }

        func mockRandomString() -> RandomStringBehavior {
            return MockRandomStringGenerator(mockString: mockState, mockUUID: mockState)
        }

        let hostedUIEnv = BasicHostedUIEnvironment(configuration: hostedUIconfig,
                                                   hostedUISessionFactory: sessionFactory,
                                                   urlSessionFactory: urlSessionMock,
                                                   randomStringFactory: mockRandomString)

        let getId: MockIdentity.MockGetIdResponse = { _ in
            return .init(identityId: "mockIdentityId")
        }

        let getCredentials: MockIdentity.MockGetCredentialsResponse = { _ in
            let credentials = CognitoIdentityClientTypes.Credentials(accessKeyId: "accessKey",
                                                                     expiration: Date(),
                                                                     secretKey: "secret",
                                                                     sessionToken: "session")
            return .init(credentials: credentials, identityId: "responseIdentityID")
        }

        let mockIdentity = MockIdentity(
            mockGetIdResponse: getId,
            mockGetCredentialsResponse: getCredentials)

        let environment = Defaults.makeDefaultAuthEnvironment(
            identityPoolFactory: { mockIdentity },
            userPoolFactory: { userPoolFactory },
            hostedUIEnvironment: hostedUIEnv)

        let statemachine = Defaults.makeDefaultAuthStateMachine(
            initialState: initialState,
            identityPoolFactory: { mockIdentity },
            userPoolFactory: { userPoolFactory },
            hostedUIEnvironment: hostedUIEnv)

        let authHandler = AuthHubEventHandler()

        plugin?.configure(
            authConfiguration: Defaults.makeDefaultAuthConfigData(withHostedUI: hostedUIconfig),
            authEnvironment: environment,
            authStateMachine: statemachine,
            credentialStoreStateMachine: Defaults.makeDefaultCredentialStateMachine(),
            hubEventHandler: authHandler,
            analyticsHandler: MockAnalyticsHandler())
    }

    override func tearDown() async throws {
        plugin = nil
        await Amplify.reset()
    }

}
