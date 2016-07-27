/*************************************************************************
 *
 * REALM CONFIDENTIAL
 * __________________
 *
 *  [2016] Realm Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of Realm Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to Realm Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from Realm Incorporated.
 *
 **************************************************************************/

import Foundation

#if os(iOS)
    import UIKit
    
    typealias Color = UIColor
#elseif os(OSX)
    import AppKit
    
    typealias Color = NSColor
#endif

extension Color {

    var realmColors: [Color] {
        return [Color(red: 231/255, green: 167/255, blue: 118/255, alpha: 1),
                Color(red: 228/255, green: 125/255, blue: 114/255, alpha: 1),
                Color(red: 233/255, green: 99/255, blue: 111/255, alpha: 1),
                Color(red: 242/255, green: 81/255, blue: 145/255, alpha: 1),
                Color(red: 154/255, green: 80/255, blue: 164/255, alpha: 1),
                Color(red: 88/255, green: 86/255, blue: 157/255, alpha: 1),
                Color(red: 56/255, green: 71/255, blue: 126/255, alpha: 1)]
    }

    class func colorForRealmLogoGradient(offset: Double) -> Color {
        var newOffset = offset

        // Ensure offset is normalized to 1
        newOffset = min(newOffset, 1)
        newOffset = max(newOffset, 0)

        let realmLogoColors = Color().realmColors

        // Work out the 'size' that each color stop spans
        let colorStopRange = 1 / Double(realmLogoColors.count-1)

        // Determine the base stop our offset is within
        let colorRangeIndex = Int(floor(newOffset / colorStopRange))

        // Get the initial color which will serve as the origin
        let topColor = realmLogoColors[colorRangeIndex]
        var fromColors: [CGFloat] = [0, 0, 0]
        topColor.getRed(&fromColors[0], green: &fromColors[1], blue: &fromColors[2], alpha: nil)

        // Get the destination color we will lerp to
        let bottomColor = realmLogoColors[colorRangeIndex + 1]
        var toColors: [CGFloat] = [0, 0, 0]
        bottomColor.getRed(&toColors[0], green: &toColors[1], blue: &toColors[2], alpha: nil)

        // Work out the actual percentage we need to lerp, inside just that stop range
        let stopOffset = (newOffset - (Double(colorRangeIndex) * colorStopRange)) / colorStopRange

        // Perform the interpolation
        var finalColors: [CGFloat] = [0, 0, 0]
        finalColors[0] = fromColors[0] + CGFloat(stopOffset) * (toColors[0] - fromColors[0])
        finalColors[1] = fromColors[1] + CGFloat(stopOffset) * (toColors[1] - fromColors[1])
        finalColors[2] = fromColors[2] + CGFloat(stopOffset) * (toColors[2] - fromColors[2])

        return Color(red: finalColors[0], green: finalColors[1], blue: finalColors[2], alpha: 1)
    }

}

extension Color {

    static func completeDimBackgroundColor() -> Color {
        return Color(white: 0.2, alpha: 1)
    }
    
    static func completeGreenBackgroundColor() -> Color {
        return Color(red: 0, green: 0.6, blue: 0, alpha: 1)
    }
    
}
