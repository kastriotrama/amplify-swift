//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

enum SignInChallengeState: State {

    case notStarted

    case waitingForAnswer(RespondToAuthChallenge, SignInMethod, AuthSignInStep)

    case verifying(RespondToAuthChallenge, SignInMethod, String, AuthSignInStep)

    case verified

    case error(RespondToAuthChallenge, SignInMethod, SignInError, AuthSignInStep)
}

extension SignInChallengeState {

    var type: String {
        switch self {
        case .notStarted: return "SignInChallengeState.notStarted"
        case .waitingForAnswer: return "SignInChallengeState.waitingForAnswer"
        case .verifying: return "SignInChallengeState.verifying"
        case .verified: return "SignInChallengeState.verified"
        case .error: return "SignInChallengeState.error"
        }
    }
}

extension SignInChallengeState: Equatable {
    static func == (lhs: SignInChallengeState, rhs: SignInChallengeState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
            (.waitingForAnswer, .waitingForAnswer),
            (.verifying, .verifying),
            (.verified, .verified),
            (.error, .error):
            return true
        default: return false
        }
    }

}
