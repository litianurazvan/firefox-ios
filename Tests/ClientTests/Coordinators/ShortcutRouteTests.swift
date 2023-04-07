// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class ShortcutRouteTests: XCTestCase {
    func testNewTabShortcut() {
        let shortcutItem = UIApplicationShortcutItem(type: "com.example.app.NewTab", localizedTitle: "New Tab")
        let route = Route(shortcutItem: shortcutItem)
        XCTAssertEqual(route, .search(url: nil, isPrivate: false))
    }

    func testNewPrivateTabShortcut() {
        let shortcutItem = UIApplicationShortcutItem(type: "com.example.app.NewPrivateTab", localizedTitle: "New Private Tab")
        let route = Route(shortcutItem: shortcutItem)
        XCTAssertEqual(route, .search(url: nil, isPrivate: true))
    }

    func testOpenLastBookmarkShortcutWithValidUrl() {
        let userInfo = [QuickActionInfos.tabURLKey: "https://www.example.com" as NSSecureCoding]
        let shortcutItem = UIApplicationShortcutItem(type: "com.example.app.OpenLastBookmark", localizedTitle: "Open Last Bookmark", localizedSubtitle: nil, icon: nil, userInfo: userInfo)
        let route = Route(shortcutItem: shortcutItem)
        XCTAssertEqual(route, .search(url: URL(string: "https://www.example.com"), isPrivate: false))
    }

    func testOpenLastBookmarkShortcutWithInvalidUrl() {
        let userInfo = [QuickActionInfos.tabURLKey: "not a url" as NSSecureCoding]
        let shortcutItem = UIApplicationShortcutItem(type: "com.example.app.OpenLastBookmark", localizedTitle: "Open Last Bookmark", localizedSubtitle: nil, icon: nil, userInfo: userInfo)
        let route = Route(shortcutItem: shortcutItem)
        XCTAssertNil(route)
    }

    func testQRCodeShortcut() {
        let shortcutItem = UIApplicationShortcutItem(type: "com.example.app.QRCode", localizedTitle: "QR Code")
        let route = Route(shortcutItem: shortcutItem)
        XCTAssertEqual(route, .action(action: .showQRCode))
    }

    func testInvalidShortcut() {
        let shortcutItem = UIApplicationShortcutItem(type: "invalid shortcut", localizedTitle: "Invalid Shortcut")
        let route = Route(shortcutItem: shortcutItem)
        XCTAssertNil(route)
    }
}
