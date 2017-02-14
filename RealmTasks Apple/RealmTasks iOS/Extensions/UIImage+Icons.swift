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
import UIKit

extension UIImage {
    public class func shareIcon() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 16, height: 24), false, 0.0)

        //// MidStroke Drawing
        let midStrokePath = UIBezierPath(roundedRect: CGRect(x: 7, y: 1, width: 2, height: 15), cornerRadius: 1)
        UIColor.gray.setFill()
        midStrokePath.fill()

        //// Top Drawing
        let topPath = UIBezierPath()
        topPath.move(to: CGPoint(x: 7.98, y: 0))
        topPath.addCurve(to: CGPoint(x: 8.59, y: 0.24), controlPoint1: CGPoint(x: 8.2, y: 0), controlPoint2: CGPoint(x: 8.42, y: 0.08))
        topPath.addCurve(to: CGPoint(x: 10.45, y: 2.16), controlPoint1: CGPoint(x: 8.66, y: 0.32), controlPoint2: CGPoint(x: 10.45, y: 2.16))
        topPath.addCurve(to: CGPoint(x: 13.74, y: 5.47), controlPoint1: CGPoint(x: 12.33, y: 4.07), controlPoint2: CGPoint(x: 13.74, y: 5.47))
        topPath.addCurve(to: CGPoint(x: 13.74, y: 6.74), controlPoint1: CGPoint(x: 14.09, y: 5.82), controlPoint2: CGPoint(x: 14.09, y: 6.39))
        topPath.addCurve(to: CGPoint(x: 12.49, y: 6.74), controlPoint1: CGPoint(x: 13.39, y: 7.09), controlPoint2: CGPoint(x: 12.83, y: 7.09))
        topPath.addLine(to: CGPoint(x: 9.2, y: 3.43))
        topPath.addCurve(to: CGPoint(x: 7.96, y: 2.18), controlPoint1: CGPoint(x: 8.63, y: 2.86), controlPoint2: CGPoint(x: 8.24, y: 2.46))
        topPath.addCurve(to: CGPoint(x: 6.73, y: 3.43), controlPoint1: CGPoint(x: 7.42, y: 2.73), controlPoint2: CGPoint(x: 6.73, y: 3.43))
        topPath.addCurve(to: CGPoint(x: 3.44, y: 6.74), controlPoint1: CGPoint(x: 4.85, y: 5.34), controlPoint2: CGPoint(x: 3.44, y: 6.74))
        topPath.addCurve(to: CGPoint(x: 2.18, y: 6.74), controlPoint1: CGPoint(x: 3.09, y: 7.09), controlPoint2: CGPoint(x: 2.53, y: 7.09))
        topPath.addCurve(to: CGPoint(x: 2.18, y: 5.47), controlPoint1: CGPoint(x: 1.84, y: 6.39), controlPoint2: CGPoint(x: 1.84, y: 5.82))
        topPath.addLine(to: CGPoint(x: 5.47, y: 2.17))
        topPath.addCurve(to: CGPoint(x: 7.44, y: 0.15), controlPoint1: CGPoint(x: 6.5, y: 1.12), controlPoint2: CGPoint(x: 7.4, y: 0.19))
        topPath.addCurve(to: CGPoint(x: 7.98, y: 0), controlPoint1: CGPoint(x: 7.6, y: 0.04), controlPoint2: CGPoint(x: 7.79, y: -0.01))
        topPath.close()
        UIColor.gray.setFill()
        topPath.fill()

        //// Bezier 2 Drawing
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 14.59, y: 9.11))
        bezier2Path.addCurve(to: CGPoint(x: 15.85, y: 10.26), controlPoint1: CGPoint(x: 15.27, y: 9.35), controlPoint2: CGPoint(x: 15.67, y: 9.76))
        bezier2Path.addCurve(to: CGPoint(x: 16, y: 12.06), controlPoint1: CGPoint(x: 16, y: 10.74), controlPoint2: CGPoint(x: 16, y: 11.18))
        bezier2Path.addLine(to: CGPoint(x: 16, y: 20.94))
        bezier2Path.addCurve(to: CGPoint(x: 15.87, y: 22.66), controlPoint1: CGPoint(x: 16, y: 21.82), controlPoint2: CGPoint(x: 16, y: 22.26))
        bezier2Path.addCurve(to: CGPoint(x: 14.74, y: 23.85), controlPoint1: CGPoint(x: 15.66, y: 23.25), controlPoint2: CGPoint(x: 15.25, y: 23.66))
        bezier2Path.addCurve(to: CGPoint(x: 12.94, y: 24), controlPoint1: CGPoint(x: 14.26, y: 24), controlPoint2: CGPoint(x: 13.82, y: 24))
        bezier2Path.addLine(to: CGPoint(x: 3.06, y: 24))
        bezier2Path.addCurve(to: CGPoint(x: 1.34, y: 23.87), controlPoint1: CGPoint(x: 2.18, y: 24), controlPoint2: CGPoint(x: 1.74, y: 24))
        bezier2Path.addCurve(to: CGPoint(x: 0.15, y: 22.74), controlPoint1: CGPoint(x: 0.75, y: 23.66), controlPoint2: CGPoint(x: 0.34, y: 23.25))
        bezier2Path.addCurve(to: CGPoint(x: 0, y: 20.94), controlPoint1: CGPoint(x: 0, y: 22.26), controlPoint2: CGPoint(x: 0, y: 21.82))
        bezier2Path.addLine(to: CGPoint(x: 0, y: 12.06))
        bezier2Path.addCurve(to: CGPoint(x: 0.13, y: 10.34), controlPoint1: CGPoint(x: 0, y: 11.18), controlPoint2: CGPoint(x: 0, y: 10.74))
        bezier2Path.addCurve(to: CGPoint(x: 1.26, y: 9.15), controlPoint1: CGPoint(x: 0.34, y: 9.75), controlPoint2: CGPoint(x: 0.75, y: 9.34))
        bezier2Path.addCurve(to: CGPoint(x: 2.59, y: 9), controlPoint1: CGPoint(x: 1.64, y: 9.03), controlPoint2: CGPoint(x: 2, y: 9.01))
        bezier2Path.addCurve(to: CGPoint(x: 3.06, y: 9), controlPoint1: CGPoint(x: 2.73, y: 9), controlPoint2: CGPoint(x: 2.88, y: 9))
        bezier2Path.addLine(to: CGPoint(x: 5, y: 9))
        bezier2Path.addCurve(to: CGPoint(x: 5, y: 11), controlPoint1: CGPoint(x: 5, y: 9.61), controlPoint2: CGPoint(x: 5, y: 10.39))
        bezier2Path.addLine(to: CGPoint(x: 3.53, y: 11))
        bezier2Path.addCurve(to: CGPoint(x: 2.63, y: 11.07), controlPoint1: CGPoint(x: 3.09, y: 11), controlPoint2: CGPoint(x: 2.87, y: 11))
        bezier2Path.addCurve(to: CGPoint(x: 2.07, y: 11.63), controlPoint1: CGPoint(x: 2.37, y: 11.17), controlPoint2: CGPoint(x: 2.17, y: 11.37))
        bezier2Path.addCurve(to: CGPoint(x: 2, y: 12.53), controlPoint1: CGPoint(x: 2, y: 11.87), controlPoint2: CGPoint(x: 2, y: 12.09))
        bezier2Path.addLine(to: CGPoint(x: 2, y: 20.47))
        bezier2Path.addCurve(to: CGPoint(x: 2.07, y: 21.37), controlPoint1: CGPoint(x: 2, y: 20.91), controlPoint2: CGPoint(x: 2, y: 21.13))
        bezier2Path.addCurve(to: CGPoint(x: 2.63, y: 21.93), controlPoint1: CGPoint(x: 2.17, y: 21.63), controlPoint2: CGPoint(x: 2.37, y: 21.83))
        bezier2Path.addCurve(to: CGPoint(x: 3.53, y: 22), controlPoint1: CGPoint(x: 2.87, y: 22), controlPoint2: CGPoint(x: 3.09, y: 22))
        bezier2Path.addLine(to: CGPoint(x: 12.47, y: 22))
        bezier2Path.addCurve(to: CGPoint(x: 13.37, y: 21.93), controlPoint1: CGPoint(x: 12.91, y: 22), controlPoint2: CGPoint(x: 13.13, y: 22))
        bezier2Path.addCurve(to: CGPoint(x: 13.93, y: 21.37), controlPoint1: CGPoint(x: 13.63, y: 21.83), controlPoint2: CGPoint(x: 13.83, y: 21.63))
        bezier2Path.addCurve(to: CGPoint(x: 14, y: 20.47), controlPoint1: CGPoint(x: 14, y: 21.13), controlPoint2: CGPoint(x: 14, y: 20.91))
        bezier2Path.addLine(to: CGPoint(x: 14, y: 12.53))
        bezier2Path.addCurve(to: CGPoint(x: 13.93, y: 11.63), controlPoint1: CGPoint(x: 14, y: 12.09), controlPoint2: CGPoint(x: 14, y: 11.87))
        bezier2Path.addCurve(to: CGPoint(x: 13.37, y: 11.07), controlPoint1: CGPoint(x: 13.83, y: 11.37), controlPoint2: CGPoint(x: 13.63, y: 11.17))
        bezier2Path.addCurve(to: CGPoint(x: 12.47, y: 11), controlPoint1: CGPoint(x: 13.13, y: 11), controlPoint2: CGPoint(x: 12.91, y: 11))
        bezier2Path.addLine(to: CGPoint(x: 11, y: 11))
        bezier2Path.addCurve(to: CGPoint(x: 11, y: 9), controlPoint1: CGPoint(x: 11, y: 10.39), controlPoint2: CGPoint(x: 11, y: 9.61))
        bezier2Path.addLine(to: CGPoint(x: 12.94, y: 9))
        bezier2Path.addCurve(to: CGPoint(x: 14.62, y: 9.12), controlPoint1: CGPoint(x: 13.8, y: 9), controlPoint2: CGPoint(x: 14.24, y: 9))
        bezier2Path.addLine(to: CGPoint(x: 14.59, y: 9.11))
        bezier2Path.close()
        UIColor.gray.setFill()
        bezier2Path.fill()

        let image = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()

        return image
    }
}
