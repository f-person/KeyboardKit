//
//  SystemKeyboard.swift
//  KeyboardKit
//
//  Created by Daniel Saidi on 2020-12-02.
//  Copyright © 2021 Daniel Saidi. All rights reserved.
//

#if os(iOS) || os(tvOS)
import SwiftUI

/**
 This view renders a system keyboard, which aims to mimic an
 iOS keyboard as closely as possible.

 This view can be used for keyboard like standard alphabetic,
 numeric and symbolic keyboards, as well as emoji ones if it
 is used on iOS 14 and later.

 There are several ways to create a system keyboard. Use the
 initializer without a view builder to use a standard button
 for each action. Use the `buttonContent` initializer to use
 custom content for some or all buttons, but with a standard
 shape, color, shadows etc. Use the `buttonView` initializer
 to use entirely custom views for some or all button. If you
 want to use standard content or views for some buttons, use
 `standardButtonContent` and `standardButtonView`.

 Since the keyboard depends on the available width, you must
 provide a `width`.

 The initializers may look strange, since the default values
 for `controller` and `width` are `nil` then resolved in the
 initializer. The is because there's an Xcode bug that makes
 the default parameters fail to compile when they're part of
 a binary framework. Instead, using `nil` and then resolving
 the values in the initializer body works.
 */
public struct SystemKeyboard<ButtonView: View>: View {

    /**
     Create a system keyboard that uses a custom `buttonView`
     builder to create the entire view for every layout item.
     */
    public init(
        layout: KeyboardLayout,
        appearance: KeyboardAppearance,
        actionHandler: KeyboardActionHandler,
        keyboardContext: KeyboardContext,
        calloutContext: KeyboardCalloutContext?,
        width: CGFloat,
        @ViewBuilder buttonView: @escaping ButtonViewBuilder
    ) {
        self.layout = layout
        self.layoutConfig = .standard(for: keyboardContext)
        self.actionHandler = actionHandler
        self.appearance = appearance
        self.keyboardWidth = width
        self.buttonView = buttonView
        self.inputWidth = layout.inputWidth(for: width)
        _keyboardContext = ObservedObject(wrappedValue: keyboardContext)
        _calloutContext = ObservedObject(wrappedValue: calloutContext ?? .disabled)
        _actionCalloutContext = ObservedObject(wrappedValue: calloutContext?.action ?? .disabled)
        _inputCalloutContext = ObservedObject(wrappedValue: calloutContext?.input ?? .disabled)
    }

    /**
     Create a system keyboard view that uses a standard view
     builder for every layout item.
     */
    public init(
        layout: KeyboardLayout,
        appearance: KeyboardAppearance,
        actionHandler: KeyboardActionHandler,
        keyboardContext: KeyboardContext,
        calloutContext: KeyboardCalloutContext?,
        width: CGFloat
    ) where ButtonView == SystemKeyboardButtonRowItem<SystemKeyboardActionButtonContent> {
        self.init(
            layout: layout,
            appearance: appearance,
            actionHandler: actionHandler,
            keyboardContext: keyboardContext,
            calloutContext: calloutContext,
            width: width,
            buttonView: { item, keyboardWidth, inputWidth in
                Self.standardButtonView(
                    item: item,
                    appearance: appearance,
                    actionHandler: actionHandler,
                    keyboardContext: keyboardContext,
                    calloutContext: calloutContext,
                    keyboardWidth: keyboardWidth,
                    inputWidth: inputWidth
                )
            }
        )
    }

    /**
     Create a system keyboard view, that uses `buttonContent`
     to customize the intrinsic content of every layout item.
     */
    public init<ButtonContentView: View>(
        layout: KeyboardLayout,
        appearance: KeyboardAppearance,
        actionHandler: KeyboardActionHandler,
        keyboardContext: KeyboardContext,
        calloutContext: KeyboardCalloutContext?,
        width: CGFloat,
        @ViewBuilder buttonContent: @escaping (KeyboardLayoutItem) -> ButtonContentView
    ) where ButtonView == SystemKeyboardButtonRowItem<ButtonContentView> {
        self.init(
            layout: layout,
            appearance: appearance,
            actionHandler: actionHandler,
            keyboardContext: keyboardContext,
            calloutContext: calloutContext,
            width: width,
            buttonView: { item, keyboardWidth, inputWidth in
                SystemKeyboardButtonRowItem(
                    content: buttonContent(item),
                    item: item,
                    actionHandler: actionHandler,
                    keyboardContext: keyboardContext,
                    calloutContext: calloutContext,
                    keyboardWidth: keyboardWidth,
                    inputWidth: inputWidth,
                    appearance: appearance
                )
            }
        )
    }

    /**
     Create a system keyboard view that uses a standard view
     builder for every layout item.
     */
    public init(
        controller: KeyboardInputViewController
    ) where ButtonView == SystemKeyboardButtonRowItem<SystemKeyboardActionButtonContent> {
        self.init(
            layout: controller.keyboardLayoutProvider.keyboardLayout(for: controller.keyboardContext),
            appearance: controller.keyboardAppearance,
            actionHandler: controller.keyboardActionHandler,
            keyboardContext: controller.keyboardContext,
            calloutContext: controller.calloutContext,
            width: controller.view.frame.width
        )
    }

    /**
     Create a system keyboard that uses a custom `buttonView`
     builder to create the entire view for every layout item.
     */
    public init(
        controller: KeyboardInputViewController,
        @ViewBuilder buttonView: @escaping ButtonViewBuilder
    ) {
        self.init(
            layout: controller.keyboardLayoutProvider.keyboardLayout(for: controller.keyboardContext),
            appearance: controller.keyboardAppearance,
            actionHandler: controller.keyboardActionHandler,
            keyboardContext: controller.keyboardContext,
            calloutContext: controller.calloutContext,
            width: controller.view.frame.width,
            buttonView: buttonView
        )
    }

    /**
     Create a system keyboard view, that uses `buttonContent`
     to customize the intrinsic content of every layout item.
     */
    public init<ButtonContentView: View>(
        controller: KeyboardInputViewController,
        @ViewBuilder buttonContent: @escaping (KeyboardLayoutItem) -> ButtonContentView
    ) where ButtonView == SystemKeyboardButtonRowItem<ButtonContentView> {
        self.init(
            layout: controller.keyboardLayoutProvider.keyboardLayout(for: controller.keyboardContext),
            appearance: controller.keyboardAppearance,
            actionHandler: controller.keyboardActionHandler,
            keyboardContext: controller.keyboardContext,
            calloutContext: controller.calloutContext,
            width: controller.view.frame.width,
            buttonContent: buttonContent
        )
    }

    private let actionHandler: KeyboardActionHandler
    private let appearance: KeyboardAppearance
    private let buttonView: ButtonViewBuilder
    private let keyboardWidth: CGFloat
    private let inputWidth: CGFloat
    private let layout: KeyboardLayout
    private let layoutConfig: KeyboardLayoutConfiguration

    public typealias ButtonViewBuilder = (KeyboardLayoutItem, KeyboardWidth, KeyboardItemWidth) -> ButtonView
    public typealias KeyboardWidth = CGFloat
    public typealias KeyboardItemWidth = CGFloat

    private var actionCalloutStyle: ActionCalloutStyle {
        var style = appearance.actionCalloutStyle()
        let insets = layoutConfig.buttonInsets
        style.callout.buttonInset = CGSize(width: insets.leading, height: insets.top)
        return style
    }

    private var inputCalloutStyle: InputCalloutStyle {
        var style = appearance.inputCalloutStyle()
        let insets = layoutConfig.buttonInsets
        style.callout.buttonInset = CGSize(width: insets.leading, height: insets.top)
        return style
    }

    @ObservedObject
    private var actionCalloutContext: ActionCalloutContext

    @ObservedObject
    private var calloutContext: KeyboardCalloutContext

    @ObservedObject
    private var inputCalloutContext: InputCalloutContext

    @ObservedObject
    private var keyboardContext: KeyboardContext

    public var body: some View {
        keyboardView
            .keyboardActionCallout(
                calloutContext: actionCalloutContext,
                keyboardContext: keyboardContext,
                style: actionCalloutStyle,
                emojiKeyboardStyle: .standard(for: keyboardContext)
            )
            .keyboardInputCallout(
                calloutContext: inputCalloutContext,
                keyboardContext: keyboardContext,
                style: inputCalloutStyle
            )
    }

    @ViewBuilder
    var keyboardView: some View {
        switch keyboardContext.keyboardType {
        case .emojis: emojiKeyboard
        default: systemKeyboard
        }
    }
}

public extension SystemKeyboard {

    /**
     The standard ``SystemKeyboardActionButtonContent`` view
     that will be used as intrinsic content for every layout
     item in the keyboard if you don't use a `buttonView` or
     `buttonContent` initializer.
     */
    static func standardButtonContent(
        item: KeyboardLayoutItem,
        appearance: KeyboardAppearance,
        keyboardContext: KeyboardContext
    ) -> SystemKeyboardActionButtonContent {
        SystemKeyboardActionButtonContent(
            action: item.action,
            appearance: appearance,
            keyboardContext: keyboardContext)
    }

    /**
     The standard ``SystemKeyboardButtonRowItem`` view, that
     will be used as view for every layout item if you don't
     use the `buttonView` initializer.
     */
    static func standardButtonView(
        item: KeyboardLayoutItem,
        appearance: KeyboardAppearance,
        actionHandler: KeyboardActionHandler,
        keyboardContext: KeyboardContext,
        calloutContext: KeyboardCalloutContext?,
        keyboardWidth: KeyboardWidth,
        inputWidth: KeyboardItemWidth
    ) -> SystemKeyboardButtonRowItem<SystemKeyboardActionButtonContent> {
        SystemKeyboardButtonRowItem(
            content: standardButtonContent(
                item: item,
                appearance: appearance,
                keyboardContext: keyboardContext),
            item: item,
            actionHandler: actionHandler,
            keyboardContext: keyboardContext,
            calloutContext: calloutContext,
            keyboardWidth: keyboardWidth,
            inputWidth: inputWidth,
            appearance: appearance
        )
    }
}

private extension SystemKeyboard {

    var emojiKeyboard: some View {
        EmojiCategoryKeyboard(
            actionHandler: actionHandler,
            keyboardContext: keyboardContext,
            calloutContext: calloutContext,
            appearance: appearance,
            style: .standard(for: keyboardContext)
        ).padding(.top)
    }

    var systemKeyboard: some View {
        VStack(spacing: 0) {
            itemRows(for: layout)
        }
        .padding(appearance.keyboardEdgeInsets)
        .environment(\.layoutDirection, .leftToRight)
    }
}

private extension SystemKeyboard {

    func itemRows(for layout: KeyboardLayout) -> some View {
        ForEach(Array(layout.itemRows.enumerated()), id: \.offset) {
            items(for: layout, itemRow: $0.element)
        }
    }

    func items(for layout: KeyboardLayout, itemRow: KeyboardLayoutItemRow) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(itemRow.enumerated()), id: \.offset) {
                buttonView($0.element, keyboardWidth, inputWidth)
            }.id(keyboardContext.locale.identifier)
        }
    }
}

/**
 `IMPORTANT` In previews, you must provide a custom width to
 get buttons to show up, since there is no shared controller.
 */
struct SystemKeyboard_Previews: PreviewProvider {

    @ViewBuilder
    static func previewButton(
        item: KeyboardLayoutItem,
        keyboardWidth: CGFloat,
        inputWidth: CGFloat
    ) -> some View {
        switch item.action {
        case .space:
            Text("This is a space bar replacement")
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        default:
            SystemKeyboardButtonRowItem(
                content: previewButtonContent(item: item),
                item: item,
                actionHandler: .preview,
                keyboardContext: .preview,
                calloutContext: .preview,
                keyboardWidth: keyboardWidth,
                inputWidth: inputWidth,
                appearance: .preview)
        }
    }

    @ViewBuilder
    static func previewButtonContent(
        item: KeyboardLayoutItem
    ) -> some View {
        switch item.action {
        case .backspace:
            Image(systemName: "trash").foregroundColor(Color.red)
        default:
            SystemKeyboardActionButtonContent(
                action: item.action,
                appearance: .preview,
                keyboardContext: .preview
            )
        }
    }

    static var previews: some View {
        VStack(spacing: 30) {

            // A standard system keyboard
            SystemKeyboard(
                layout: .preview,
                appearance: .preview,
                actionHandler: .preview,
                keyboardContext: .preview,
                calloutContext: nil,
                width: UIScreen.main.bounds.width)


            // A keyboard that replaces the button content
            SystemKeyboard(
                layout: .preview,
                appearance: .preview,
                actionHandler: .preview,
                keyboardContext: .preview,
                calloutContext: nil,
                width: UIScreen.main.bounds.width,
                buttonContent: previewButtonContent)

            // A keyboard that replaces entire button views
            SystemKeyboard(
                layout: .preview,
                appearance: .preview,
                actionHandler: .preview,
                keyboardContext: .preview,
                calloutContext: nil,
                width: UIScreen.main.bounds.width,
                buttonView: previewButton)
        }.background(Color.yellow)
    }
}
#endif
