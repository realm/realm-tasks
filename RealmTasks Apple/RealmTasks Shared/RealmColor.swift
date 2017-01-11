////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Foundation

#if os(iOS)
    import UIKit

    typealias Color = UIColor
#elseif os(OSX)
    import AppKit

    typealias Color = NSColor
#endif

extension Color {
    static func taskColors() -> [Color] {
        return [
            Color(red: 231/255, green: 167/255, blue: 118/255, alpha: 1),
            Color(red: 228/255, green: 125/255, blue: 114/255, alpha: 1),
            Color(red: 233/255, green: 99/255, blue: 111/255, alpha: 1),
            Color(red: 242/255, green: 81/255, blue: 145/255, alpha: 1),
            Color(red: 154/255, green: 80/255, blue: 164/255, alpha: 1),
            Color(red: 88/255, green: 86/255, blue: 157/255, alpha: 1),
            Color(red: 56/255, green: 71/255, blue: 126/255, alpha: 1)
        ]
    }

    static func listColors() -> [Color] {
        return [
            Color(red: 6/255, green: 147/255, blue: 251/255, alpha: 1),
            Color(red: 16/255, green: 158/255, blue: 251/255, alpha: 1),
            Color(red: 26/255, green: 169/255, blue: 251/255, alpha: 1),
            Color(red: 33/255, green: 180/255, blue: 251/255, alpha: 1),
            Color(red: 40/255, green: 190/255, blue: 251/255, alpha: 1),
            Color(red: 46/255, green: 198/255, blue: 251/255, alpha: 1),
            Color(red: 54/255, green: 207/255, blue: 251/255, alpha: 1)
        ]
    }
}

extension Collection where Iterator.Element == Color, Index == Int {
    func gradientColor(atFraction fraction: Double) -> Color {
        // Ensure offset is normalized to 1
        let normalizedOffset = Swift.max(Swift.min(fraction, 1.0), 0.0)

        // Work out the 'size' that each color stop spans
        let colorStopRange = 1.0 / (Double(self.endIndex) - 1.0)

        // Determine the base stop our offset is within
        let colorRangeIndex = Int(floor(normalizedOffset / colorStopRange))

        // Get the initial color which will serve as the origin
        let topColor = self[colorRangeIndex]
        var fromColors: [CGFloat] = [0, 0, 0]
        topColor.getRed(&fromColors[0], green: &fromColors[1], blue: &fromColors[2], alpha: nil)

        // Get the destination color we will lerp to
        let bottomColor = self[colorRangeIndex + 1]
        var toColors: [CGFloat] = [0, 0, 0]
        bottomColor.getRed(&toColors[0], green: &toColors[1], blue: &toColors[2], alpha: nil)

        // Work out the actual percentage we need to lerp, inside just that stop range
        let stopOffset = CGFloat((normalizedOffset - (Double(colorRangeIndex) * colorStopRange)) / colorStopRange)

        // Perform the interpolation
        let finalColors = zip(fromColors, toColors).map { from, to in
            return from + stopOffset * (to - from)
        }
        return Color(red: finalColors[0], green: finalColors[1], blue: finalColors[2], alpha: 1)
    }
}

extension Color {
    class var completeDimBackground: Color {
        return Color(white: 0.2, alpha: 1)
    }

    class var completeGreenBackground: Color {
        return Color(red: 0, green: 0.6, blue: 0, alpha: 1)
    }
}
