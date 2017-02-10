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
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 27, height: 35), false, 0.0)
        //// Box Drawing
        let boxPath = UIBezierPath()
        boxPath.move(to: CGPoint(x: 22.32, y: 11.26))
        boxPath.addLine(to: CGPoint(x: 22.47, y: 11.3))
        boxPath.addCurve(to: CGPoint(x: 24.7, y: 13.53), controlPoint1: CGPoint(x: 23.51, y: 11.68), controlPoint2: CGPoint(x: 24.32, y: 12.49))
        boxPath.addCurve(to: CGPoint(x: 25, y: 17.11), controlPoint1: CGPoint(x: 25, y: 14.47), controlPoint2: CGPoint(x: 25, y: 15.35))
        boxPath.addLine(to: CGPoint(x: 25, y: 28.89))
        boxPath.addCurve(to: CGPoint(x: 24.74, y: 32.32), controlPoint1: CGPoint(x: 25, y: 30.65), controlPoint2: CGPoint(x: 25, y: 31.53))
        boxPath.addLine(to: CGPoint(x: 24.7, y: 32.47))
        boxPath.addCurve(to: CGPoint(x: 22.47, y: 34.7), controlPoint1: CGPoint(x: 24.32, y: 33.51), controlPoint2: CGPoint(x: 23.51, y: 34.32))
        boxPath.addCurve(to: CGPoint(x: 18.89, y: 35), controlPoint1: CGPoint(x: 21.53, y: 35), controlPoint2: CGPoint(x: 20.65, y: 35))
        boxPath.addLine(to: CGPoint(x: 6.11, y: 35))
        boxPath.addCurve(to: CGPoint(x: 2.68, y: 34.74), controlPoint1: CGPoint(x: 4.35, y: 35), controlPoint2: CGPoint(x: 3.47, y: 35))
        boxPath.addLine(to: CGPoint(x: 2.53, y: 34.7))
        boxPath.addCurve(to: CGPoint(x: 0.3, y: 32.47), controlPoint1: CGPoint(x: 1.49, y: 34.32), controlPoint2: CGPoint(x: 0.68, y: 33.51))
        boxPath.addCurve(to: CGPoint(x: 0, y: 28.89), controlPoint1: CGPoint(x: 0, y: 31.53), controlPoint2: CGPoint(x: 0, y: 30.65))
        boxPath.addLine(to: CGPoint(x: 0, y: 17.11))
        boxPath.addCurve(to: CGPoint(x: 0.26, y: 13.68), controlPoint1: CGPoint(x: 0, y: 15.35), controlPoint2: CGPoint(x: -0, y: 14.47))
        boxPath.addLine(to: CGPoint(x: 0.3, y: 13.53))
        boxPath.addCurve(to: CGPoint(x: 2.53, y: 11.3), controlPoint1: CGPoint(x: 0.68, y: 12.49), controlPoint2: CGPoint(x: 1.49, y: 11.68))
        boxPath.addCurve(to: CGPoint(x: 4.25, y: 11.02), controlPoint1: CGPoint(x: 3.06, y: 11.13), controlPoint2: CGPoint(x: 3.58, y: 11.06))
        boxPath.addCurve(to: CGPoint(x: 6.11, y: 11), controlPoint1: CGPoint(x: 4.75, y: 11), controlPoint2: CGPoint(x: 5.35, y: 11))
        boxPath.addLine(to: CGPoint(x: 7, y: 11))
        boxPath.addCurve(to: CGPoint(x: 7, y: 14), controlPoint1: CGPoint(x: 7, y: 12.3), controlPoint2: CGPoint(x: 7, y: 12.7))
        boxPath.addLine(to: CGPoint(x: 4.53, y: 14))
        boxPath.addCurve(to: CGPoint(x: 3.63, y: 14.07), controlPoint1: CGPoint(x: 4.09, y: 14), controlPoint2: CGPoint(x: 3.87, y: 14))
        boxPath.addCurve(to: CGPoint(x: 3.07, y: 14.63), controlPoint1: CGPoint(x: 3.37, y: 14.17), controlPoint2: CGPoint(x: 3.17, y: 14.37))
        boxPath.addCurve(to: CGPoint(x: 3, y: 15.53), controlPoint1: CGPoint(x: 3, y: 14.87), controlPoint2: CGPoint(x: 3, y: 15.09))
        boxPath.addLine(to: CGPoint(x: 3, y: 30.47))
        boxPath.addCurve(to: CGPoint(x: 3.07, y: 31.37), controlPoint1: CGPoint(x: 3, y: 30.91), controlPoint2: CGPoint(x: 3, y: 31.13))
        boxPath.addCurve(to: CGPoint(x: 3.63, y: 31.93), controlPoint1: CGPoint(x: 3.17, y: 31.63), controlPoint2: CGPoint(x: 3.37, y: 31.83))
        boxPath.addCurve(to: CGPoint(x: 4.53, y: 32), controlPoint1: CGPoint(x: 3.87, y: 32), controlPoint2: CGPoint(x: 4.09, y: 32))
        boxPath.addLine(to: CGPoint(x: 20.47, y: 32))
        boxPath.addCurve(to: CGPoint(x: 21.37, y: 31.93), controlPoint1: CGPoint(x: 20.91, y: 32), controlPoint2: CGPoint(x: 21.13, y: 32))
        boxPath.addCurve(to: CGPoint(x: 21.93, y: 31.37), controlPoint1: CGPoint(x: 21.63, y: 31.83), controlPoint2: CGPoint(x: 21.83, y: 31.63))
        boxPath.addCurve(to: CGPoint(x: 22, y: 30.47), controlPoint1: CGPoint(x: 22, y: 31.13), controlPoint2: CGPoint(x: 22, y: 30.91))
        boxPath.addLine(to: CGPoint(x: 22, y: 15.53))
        boxPath.addCurve(to: CGPoint(x: 21.93, y: 14.63), controlPoint1: CGPoint(x: 22, y: 15.09), controlPoint2: CGPoint(x: 22, y: 14.87))
        boxPath.addCurve(to: CGPoint(x: 21.37, y: 14.07), controlPoint1: CGPoint(x: 21.83, y: 14.37), controlPoint2: CGPoint(x: 21.63, y: 14.17))
        boxPath.addCurve(to: CGPoint(x: 20.47, y: 14), controlPoint1: CGPoint(x: 21.13, y: 14), controlPoint2: CGPoint(x: 20.91, y: 14))
        boxPath.addLine(to: CGPoint(x: 18, y: 14))
        boxPath.addCurve(to: CGPoint(x: 18, y: 11), controlPoint1: CGPoint(x: 18, y: 12.7), controlPoint2: CGPoint(x: 18, y: 12.3))
        boxPath.addLine(to: CGPoint(x: 18.89, y: 11))
        boxPath.addCurve(to: CGPoint(x: 22.32, y: 11.26), controlPoint1: CGPoint(x: 20.65, y: 11), controlPoint2: CGPoint(x: 21.53, y: 11))
        boxPath.close()
        UIColor.gray.setFill()
        boxPath.fill()

        //// MidStroke Drawing
        let midStrokePath = UIBezierPath(roundedRect: CGRect(x: 11, y: 1, width: 3, height: 21), cornerRadius: 1.5)
        UIColor.gray.setFill()
        midStrokePath.fill()

        //// Top Drawing
        let topPath = UIBezierPath()
        topPath.move(to: CGPoint(x: 12.48, y: 0))
        topPath.addCurve(to: CGPoint(x: 13.51, y: 0.41), controlPoint1: CGPoint(x: 12.85, y: 0), controlPoint2: CGPoint(x: 13.22, y: 0.14))
        topPath.addCurve(to: CGPoint(x: 16.66, y: 3.62), controlPoint1: CGPoint(x: 13.63, y: 0.53), controlPoint2: CGPoint(x: 16.66, y: 3.62))
        topPath.addCurve(to: CGPoint(x: 18.85, y: 5.8), controlPoint1: CGPoint(x: 19.85, y: 6.8), controlPoint2: CGPoint(x: 18.85, y: 5.8))
        topPath.addCurve(to: CGPoint(x: 18.85, y: 7.92), controlPoint1: CGPoint(x: 19.43, y: 6.39), controlPoint2: CGPoint(x: 19.43, y: 7.34))
        topPath.addCurve(to: CGPoint(x: 16.72, y: 7.92), controlPoint1: CGPoint(x: 18.26, y: 8.51), controlPoint2: CGPoint(x: 17.31, y: 8.51))
        topPath.addLine(to: CGPoint(x: 14.54, y: 5.74))
        topPath.addCurve(to: CGPoint(x: 12.45, y: 3.65), controlPoint1: CGPoint(x: 13.59, y: 4.79), controlPoint2: CGPoint(x: 12.92, y: 4.12))
        topPath.addCurve(to: CGPoint(x: 10.36, y: 5.74), controlPoint1: CGPoint(x: 11.53, y: 4.57), controlPoint2: CGPoint(x: 10.36, y: 5.74))
        topPath.addCurve(to: CGPoint(x: 8.18, y: 7.93), controlPoint1: CGPoint(x: 7.18, y: 8.93), controlPoint2: CGPoint(x: 8.18, y: 7.93))
        topPath.addCurve(to: CGPoint(x: 6.06, y: 7.93), controlPoint1: CGPoint(x: 7.6, y: 8.51), controlPoint2: CGPoint(x: 6.65, y: 8.51))
        topPath.addCurve(to: CGPoint(x: 6.06, y: 5.8), controlPoint1: CGPoint(x: 5.47, y: 7.34), controlPoint2: CGPoint(x: 5.47, y: 6.39))
        topPath.addLine(to: CGPoint(x: 8.24, y: 3.62))
        topPath.addCurve(to: CGPoint(x: 11.58, y: 0.26), controlPoint1: CGPoint(x: 9.99, y: 1.88), controlPoint2: CGPoint(x: 11.5, y: 0.31))
        topPath.addCurve(to: CGPoint(x: 12.48, y: 0), controlPoint1: CGPoint(x: 11.85, y: 0.07), controlPoint2: CGPoint(x: 12.17, y: -0.01))
        topPath.close()
        UIColor.gray.setFill()
        topPath.fill()

        let image = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()

        return image
    }
}
