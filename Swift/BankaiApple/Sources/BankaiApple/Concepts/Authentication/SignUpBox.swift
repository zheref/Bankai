//
//  SignUpBox.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 21/01/25.
//

import SwiftUI

public enum SignUpStepIntention {
    case identity
    case security
    case profileInfo
    case verification
    case custom
    case completion
}

public struct SignUpStep {
    public var prompt: String
    public var placeholder: String?
    public var intention: SignUpStepIntention
}

public struct SignUpBox: View {
    
    let imageName: String?
    var steps: [SignUpStep]
    var currentStepPosition: Int = 0
    
    @Binding var emailInput: String
    
    let theme: StyleTheme
    
    init(
        imageName: String? = nil,
        steps: [SignUpStep]? = nil,
        emailInput: Binding<String>,
        theme: StyleTheme = .cocoa
    ) {
        self.imageName = imageName
        self.steps = steps ?? Self.defaultSteps
        self._emailInput = emailInput
        self.theme = theme
    }
    
    public var body: some View {
        GroupBox {
            VStack(spacing: theme.regularSurroundingPadding) {
                headerImage
                Text("Start creating your account")
                    .font(.title.bold())
                Text(currentStep.prompt)
                
                switch currentStep.intention {
                case .identity:
                    TextField(currentStep.placeholder ?? "", text: $emailInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .modify { view in
                            if #available(macOS 12.0, *) {
                                AnyView(
                                    view
                                        .padding(10.0)
                                        .background(Color.white)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 10.0)
                                                .stroke(Color.white)
                                        }
                                )
                            } else {
                                AnyView(view)
                            }
                        }
                        
//                        .textFieldStyle(
//                            ThemedTextFieldStyle(base: theme.base,
//                                                 padding: 10.0)
//                        )
//                        .background(
//                            RoundedRectangle(
//                                cornerRadius: theme.textFieldCornerRadius
//                            )
//                        )
//                        .frame(minHeight: theme.textFieldHeight)
                default:
                    EmptyView()
                }
            }
            .padding(theme.regularSurroundingPadding)
        }
        .padding(theme.regularMajorPadding)
    }
    
    @ViewBuilder
    private var headerImage: some View {
        if let imageName {
            Image(imageName)
                .renderingMode(.template)
        } else {
            let defaultSymbolName = "person.crop.circle.badge.plus"
            if #available(macOS 12.0, *) {
                Image(systemName: defaultSymbolName)
                    .symbolRenderingMode(.multicolor)
                    .foregroundStyle(Color.accentColor, Color.green)
                    .font(.system(size: 73))
            } else {
                if #available(macOS 11.0, *) {
                    Image(systemName: defaultSymbolName)
                } else {
                    EmptyView()
                }
            }
        }
    }
}

// MARK: - Computed

extension SignUpBox {
    
    var currentStep: SignUpStep { steps[currentStepPosition] }
    
}

// MARK: - Defaults

extension SignUpBox {
    
    static let defaultSteps: [SignUpStep] = [
            .init(prompt: "Please enter your email to continue",
                  placeholder: "Your email",
                  intention: .identity)
        ]
    
}

#Preview("Expecting Information") {
    @State var email: String = ""
    
    SignUpBox(
        emailInput: $email
    )
    #if os(macOS)
        .frame(width: 480, height: 300)
    #endif
}
