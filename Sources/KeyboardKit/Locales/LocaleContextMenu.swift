//
//  LocaleContextMenu.swift
//  KeyboardKit
//
//  Created by Daniel Saidi on 2021-02-19.
//  Copyright © 2021-2023 Daniel Saidi. All rights reserved.
//

import SwiftUI

/**
 This view modifier can be used to add a locale context menu
 that changes the locale of the provided context.

 The easiest way to apply this view modifier is to apply the
 `.localeContextMenu(for:)` view extension to any view. This
 will by default sort and localize the context locales using
 the ``KeyboardContext/localePresentationLocale``, if one is
 specified. You can also specify an optional `menuItem` view
 builder to provide a custom view for every locale.

 Note that this view will only apply the context menu if the
 platform supports it and the context has multiple locales.
 */
public struct LocaleContextMenu<MenuItem: View>: ViewModifier {

    /**
     Create a context menu that lists all the locales in the
     context as a `Text` view with the full localized name.

     If no `presentationLocale` is provided, the locale text
     for each locale is localized with the locale itself.

     - Parameters:
       - keyboardContext: The keyboard context to use.
     */
    public init(
        keyboardContext: KeyboardContext
    ) where MenuItem == Text {
        self.init(keyboardContext: keyboardContext) { locale in
            Text(locale.localizedName(in: keyboardContext.localePresentationLocale ?? locale) ?? "-")
        }
    }

    /**
     Create a context menu that lists all the locales in the
     context as custom views.

     - Parameters:
       - keyboardContext: The keyboard context to use.
       - menuItem: A menu item view builder.
     */
    public init(
        keyboardContext: KeyboardContext,
        @ViewBuilder menuItem: @escaping (Locale) -> MenuItem
    ) {
        self._keyboardContext = ObservedObject(wrappedValue: keyboardContext)
        self.menuItem = menuItem
    }

    @ObservedObject
    private var keyboardContext: KeyboardContext

    private var menuItem: (Locale) -> MenuItem

    public func body(content: Content) -> some View {
        if keyboardContext.locales.count > 1 {
            content.withContextMenu(menu)
        } else {
            content
        }
    }
}

private extension View {

    func withContextMenu<MenuView: View>(_ menu: MenuView) -> some View {
        #if os(iOS) || os(macOS)
        self.contextMenu(
            ContextMenu { menu }
        )
        #else
        self
        #endif
    }
}

private extension LocaleContextMenu {

    var locales: [Locale] {
        let locale = keyboardContext.locale
        var locales = keyboardContext.locales
            .sorted { title(for: $0) < title(for: $1) }
            .filter { $0.identifier != locale.identifier }
        locales.insert(locale, at: 0)
        return locales
    }

    var menu: some View {
        ForEach(locales, id: \.identifier) { locale in
            Button(
                action: { keyboardContext.locale = locale },
                label: { menuItem(locale) }
            )
            if keyboardContext.locale == locale {
                Divider()
            }
        }
    }

    func title(for locale: Locale) -> String {
        locale.localizedName(in: keyboardContext.localePresentationLocale ?? locale) ?? locale.identifier
    }
}

public extension View {

    /**
     Apply a menu that lists all the locales in the keyboard
     context as a `Text` view with the full localized name.

     If no `presentationLocale` is provided, the locale text
     for each locale is localized with the locale itself.

     - Parameters:
       - keyboardContext: The keyboard context to use.
     */
    func localeContextMenu(
        for context: KeyboardContext,
        presentationLocale: Locale? = nil
    ) -> some View {
        self.modifier(
            LocaleContextMenu(keyboardContext: context)
        )
    }

    /**
     Apply a menu that lists all the locales in the keyboard
     context as custom views.

     - Parameters:
       - keyboardContext: The keyboard context to use.
       - menuItem: A menu item view builder.
     */
    func localeContextMenu<ButtonView: View>(
        for context: KeyboardContext,
        menuItem: @escaping (Locale) -> ButtonView
    ) -> some View {
        self.modifier(
            LocaleContextMenu(
                keyboardContext: context,
                menuItem: menuItem
            )
        )
    }
}

struct LocaleContextMenu_Previews: PreviewProvider {

    static let context: KeyboardContext = {
        let context = KeyboardContext.preview
        context.locales = KeyboardLocale.allCases.map { $0.locale }
        context.localePresentationLocale = KeyboardLocale.danish.locale
        return context
    }()

    static var previews: some View {
        VStack(spacing: 20) {
            Text("🌐").localeContextMenu(for: context)
        }
    }
}
