/*
* Copyright (c) 2020, Psiphon Inc.
* All rights reserved.
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
*/
import Foundation
import PsiCashClient

enum PsiCashHardCodedValues {
    static let videoAdRewardAmount = PsiCashAmount(nanoPsi: Int64(35e9))
    static let videoAdRewardTitle = "35"
    /// Amount of time to wait for PsiCash to have an earner token for modifying .
    static let getEarnerTokenTimeout: DispatchTimeInterval = .seconds(5)
    
    static let accountsLearnMoreURL = URL(string: "https://psiphon.ca/faq.html#psicash-account")!
    
}

// There is no point to load an interstitial after the user
// presses the disconnected button.
let InterstitialDelayAfterDisconnection: TimeInterval = 5.0  // 5 seconds.

// The official way to open subscription management screen.
// https://developer.apple.com/videos/play/wwdc2018/705/
let appleSubscriptionsManagementURL = URL(string: "https://apps.apple.com/account/subscriptions")!
