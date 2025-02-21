//
//  ErrorEnhancers.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 20/02/25.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Error {
    var isRecoveryAvailable: Bool {
        let nsError = self as NSError
        return (nsError.localizedRecoveryOptions?.count ?? 0) > 0
    }
}
