//
//  KeyboardAction+Test.swift
//  KeyboardKit
//
//  Created by Daniel Saidi on 2019-05-11.
//  Copyright © 2021 Daniel Saidi. All rights reserved.
//

import Quick
import Nimble
import KeyboardKit
import UIKit

extension KeyboardAction {
    
    static var testActions: [KeyboardAction] {
        [
            .none,
            .dismissKeyboard,
            .done,
            .character(""),
            .command,
            .control,
            .custom(name: ""),
            .dictation,
            .escape,
            .emoji(Emoji("")),
            .emojiCategory(.smileys),
            .function,
            .image(description: "", keyboardImageName: "", imageName: ""),
            
            .keyboardType(.alphabetic(.lowercased)),
            .keyboardType(.alphabetic(.uppercased)),
            .keyboardType(.alphabetic(.capsLocked)),
            .keyboardType(.numeric),
            .keyboardType(.symbolic),
            .keyboardType(.email),
            .keyboardType(.emojis),
            .keyboardType(.images),
            .keyboardType(.custom("")),
            
            .moveCursorBackward,
            .moveCursorForward,
            .newLine,
            .nextKeyboard,
            .option,
            .search,
            .shift(currentState: .lowercased),
            .shift(currentState: .uppercased),
            .shift(currentState: .capsLocked),
            .space,
            .systemImage(description: "", keyboardImageName: "", imageName: ""),
            .tab
        ]
    }
}
