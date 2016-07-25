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
        return [Color(red: 231.0/255.0, green: 167.0/255.0, blue: 118.0/255.0, alpha: 1.0),
                Color(red: 228.0/255.0, green: 125.0/255.0, blue: 114.0/255.0, alpha: 1.0),
                Color(red: 233.0/255.0, green: 99.0/255.0, blue: 111.0/255.0, alpha: 1.0),
                Color(red: 242.0/255.0, green: 81.0/255.0, blue: 145.0/255.0, alpha: 1.0),
                Color(red: 154.0/255.0, green: 80.0/255.0, blue: 164.0/255.0, alpha: 1.0),
                Color(red: 88.0/255.0, green: 86.0/255.0, blue: 157.0/255.0, alpha: 1.0),
                Color(red: 56.0/255.0, green: 71.0/255.0, blue: 126.0/255.0, alpha: 1.0)]
    }

    class func colorForRealmLogoGradient(offset: Double) -> Color {
        var newOffset = offset

        // Ensure offset is normalized to 1.0
        newOffset = min(newOffset, 1.0)
        newOffset = max(newOffset, 0.0)

        let realmLogoColors = Color().realmColors

        // Work out the 'size' that each color stop spans
        let colorStopRange = 1.0 / Double(realmLogoColors.count-1)

        // Determine the base stop our offset is within
        let colorRangeIndex = Int(floor(newOffset / colorStopRange))

        // Get the initial color which will serve as the origin
        let topColor = realmLogoColors[colorRangeIndex]
        var fromColors: [CGFloat] = [0.0, 0.0, 0.0]
        topColor.getRed(&fromColors[0], green: &fromColors[1], blue: &fromColors[2], alpha: nil)

        // Get the destination color we will lerp to
        let bottomColor = realmLogoColors[colorRangeIndex + 1]
        var toColors: [CGFloat] = [0.0, 0.0, 0.0]
        bottomColor.getRed(&toColors[0], green: &toColors[1], blue: &toColors[2], alpha: nil)

        // Work out the actual percentage we need to lerp, inside just that stop range
        let stopOffset = (newOffset - (Double(colorRangeIndex) * colorStopRange)) / colorStopRange

        // Perform the interpolation
        var finalColors: [CGFloat] = [0.0, 0.0, 0.0]
        finalColors[0] = fromColors[0] + CGFloat(stopOffset) * (toColors[0] - fromColors[0])
        finalColors[1] = fromColors[1] + CGFloat(stopOffset) * (toColors[1] - fromColors[1])
        finalColors[2] = fromColors[2] + CGFloat(stopOffset) * (toColors[2] - fromColors[2])

        return Color(red: finalColors[0], green: finalColors[1], blue: finalColors[2], alpha: 1.0)
    }

}