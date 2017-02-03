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
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 33, height: 47), false, 0.0)

        //// Box Drawing
        let boxPath = UIBezierPath()
        boxPath.move(to: CGPoint(x: 30.32, y: 13.26))
        boxPath.addLine(to: CGPoint(x: 30.47, y: 13.3))
        boxPath.addCurve(to: CGPoint(x: 32.7, y: 15.53), controlPoint1: CGPoint(x: 31.51, y: 13.68), controlPoint2: CGPoint(x: 32.32, y: 14.49))
        boxPath.addCurve(to: CGPoint(x: 33, y: 19.11), controlPoint1: CGPoint(x: 33, y: 16.47), controlPoint2: CGPoint(x: 33, y: 17.35))
        boxPath.addLine(to: CGPoint(x: 33, y: 39.89))
        boxPath.addCurve(to: CGPoint(x: 32.74, y: 43.32), controlPoint1: CGPoint(x: 33, y: 41.65), controlPoint2: CGPoint(x: 33, y: 42.53))
        boxPath.addLine(to: CGPoint(x: 32.7, y: 43.47))
        boxPath.addCurve(to: CGPoint(x: 30.47, y: 45.7), controlPoint1: CGPoint(x: 32.32, y: 44.51), controlPoint2: CGPoint(x: 31.51, y: 45.32))
        boxPath.addCurve(to: CGPoint(x: 26.89, y: 46), controlPoint1: CGPoint(x: 29.53, y: 46), controlPoint2: CGPoint(x: 28.65, y: 46))
        boxPath.addLine(to: CGPoint(x: 6.11, y: 46))
        boxPath.addCurve(to: CGPoint(x: 2.68, y: 45.74), controlPoint1: CGPoint(x: 4.35, y: 46), controlPoint2: CGPoint(x: 3.47, y: 46))
        boxPath.addLine(to: CGPoint(x: 2.53, y: 45.7))
        boxPath.addCurve(to: CGPoint(x: 0.3, y: 43.47), controlPoint1: CGPoint(x: 1.49, y: 45.32), controlPoint2: CGPoint(x: 0.68, y: 44.51))
        boxPath.addCurve(to: CGPoint(x: 0, y: 39.89), controlPoint1: CGPoint(x: 0, y: 42.53), controlPoint2: CGPoint(x: 0, y: 41.65))
        boxPath.addLine(to: CGPoint(x: 0, y: 19.11))
        boxPath.addCurve(to: CGPoint(x: 0.26, y: 15.68), controlPoint1: CGPoint(x: 0, y: 17.35), controlPoint2: CGPoint(x: -0, y: 16.47))
        boxPath.addLine(to: CGPoint(x: 0.3, y: 15.53))
        boxPath.addCurve(to: CGPoint(x: 2.53, y: 13.3), controlPoint1: CGPoint(x: 0.68, y: 14.49), controlPoint2: CGPoint(x: 1.49, y: 13.68))
        boxPath.addCurve(to: CGPoint(x: 4.25, y: 13.02), controlPoint1: CGPoint(x: 3.06, y: 13.13), controlPoint2: CGPoint(x: 3.58, y: 13.06))
        boxPath.addCurve(to: CGPoint(x: 6.11, y: 13), controlPoint1: CGPoint(x: 4.75, y: 13), controlPoint2: CGPoint(x: 5.35, y: 13))
        boxPath.addLine(to: CGPoint(x: 11, y: 13))
        boxPath.addCurve(to: CGPoint(x: 11, y: 16), controlPoint1: CGPoint(x: 11, y: 14.3), controlPoint2: CGPoint(x: 11, y: 14.7))
        boxPath.addLine(to: CGPoint(x: 4.53, y: 16))
        boxPath.addCurve(to: CGPoint(x: 3.63, y: 16.07), controlPoint1: CGPoint(x: 4.09, y: 16), controlPoint2: CGPoint(x: 3.87, y: 16))
        boxPath.addCurve(to: CGPoint(x: 3.07, y: 16.63), controlPoint1: CGPoint(x: 3.37, y: 16.17), controlPoint2: CGPoint(x: 3.17, y: 16.37))
        boxPath.addCurve(to: CGPoint(x: 3, y: 17.53), controlPoint1: CGPoint(x: 3, y: 16.87), controlPoint2: CGPoint(x: 3, y: 17.09))
        boxPath.addLine(to: CGPoint(x: 3, y: 41.47))
        boxPath.addCurve(to: CGPoint(x: 3.07, y: 42.37), controlPoint1: CGPoint(x: 3, y: 41.91), controlPoint2: CGPoint(x: 3, y: 42.13))
        boxPath.addCurve(to: CGPoint(x: 3.63, y: 42.93), controlPoint1: CGPoint(x: 3.17, y: 42.63), controlPoint2: CGPoint(x: 3.37, y: 42.83))
        boxPath.addCurve(to: CGPoint(x: 4.53, y: 43), controlPoint1: CGPoint(x: 3.87, y: 43), controlPoint2: CGPoint(x: 4.09, y: 43))
        boxPath.addLine(to: CGPoint(x: 28.47, y: 43))
        boxPath.addCurve(to: CGPoint(x: 29.37, y: 42.93), controlPoint1: CGPoint(x: 28.91, y: 43), controlPoint2: CGPoint(x: 29.13, y: 43))
        boxPath.addCurve(to: CGPoint(x: 29.93, y: 42.37), controlPoint1: CGPoint(x: 29.63, y: 42.83), controlPoint2: CGPoint(x: 29.83, y: 42.63))
        boxPath.addCurve(to: CGPoint(x: 30, y: 41.47), controlPoint1: CGPoint(x: 30, y: 42.13), controlPoint2: CGPoint(x: 30, y: 41.91))
        boxPath.addLine(to: CGPoint(x: 30, y: 17.53))
        boxPath.addCurve(to: CGPoint(x: 29.93, y: 16.63), controlPoint1: CGPoint(x: 30, y: 17.09), controlPoint2: CGPoint(x: 30, y: 16.87))
        boxPath.addCurve(to: CGPoint(x: 29.37, y: 16.07), controlPoint1: CGPoint(x: 29.83, y: 16.37), controlPoint2: CGPoint(x: 29.63, y: 16.17))
        boxPath.addCurve(to: CGPoint(x: 28.47, y: 16), controlPoint1: CGPoint(x: 29.13, y: 16), controlPoint2: CGPoint(x: 28.91, y: 16))
        boxPath.addLine(to: CGPoint(x: 22, y: 16))
        boxPath.addCurve(to: CGPoint(x: 22, y: 13), controlPoint1: CGPoint(x: 22, y: 14.7), controlPoint2: CGPoint(x: 22, y: 14.3))
        boxPath.addLine(to: CGPoint(x: 26.89, y: 13))
        boxPath.addCurve(to: CGPoint(x: 30.32, y: 13.26), controlPoint1: CGPoint(x: 28.65, y: 13), controlPoint2: CGPoint(x: 29.53, y: 13))
        boxPath.close()
        UIColor.gray.setFill()
        boxPath.fill()

        //// MidStroke Drawing
        let midStrokePath = UIBezierPath(roundedRect: CGRect(x: 15, y: 1, width: 3, height: 28), cornerRadius: 1.5)
        UIColor.gray.setFill()
        midStrokePath.fill()

        //// Top Drawing
        let topPath = UIBezierPath()
        topPath.move(to: CGPoint(x: 16.48, y: 0))
        topPath.addCurve(to: CGPoint(x: 17.51, y: 0.41), controlPoint1: CGPoint(x: 16.85, y: 0), controlPoint2: CGPoint(x: 17.22, y: 0.14))
        topPath.addCurve(to: CGPoint(x: 20.66, y: 3.62), controlPoint1: CGPoint(x: 17.63, y: 0.53), controlPoint2: CGPoint(x: 20.66, y: 3.62))
        topPath.addCurve(to: CGPoint(x: 24.85, y: 7.8), controlPoint1: CGPoint(x: 23.85, y: 6.8), controlPoint2: CGPoint(x: 24.85, y: 7.8))
        topPath.addCurve(to: CGPoint(x: 24.85, y: 9.92), controlPoint1: CGPoint(x: 25.43, y: 8.39), controlPoint2: CGPoint(x: 25.43, y: 9.34))
        topPath.addCurve(to: CGPoint(x: 22.72, y: 9.92), controlPoint1: CGPoint(x: 24.26, y: 10.51), controlPoint2: CGPoint(x: 23.31, y: 10.51))
        topPath.addLine(to: CGPoint(x: 18.54, y: 5.74))
        topPath.addCurve(to: CGPoint(x: 16.45, y: 3.65), controlPoint1: CGPoint(x: 17.59, y: 4.79), controlPoint2: CGPoint(x: 16.92, y: 4.12))
        topPath.addCurve(to: CGPoint(x: 14.36, y: 5.74), controlPoint1: CGPoint(x: 15.53, y: 4.57), controlPoint2: CGPoint(x: 14.36, y: 5.74))
        topPath.addCurve(to: CGPoint(x: 10.18, y: 9.93), controlPoint1: CGPoint(x: 11.18, y: 8.93), controlPoint2: CGPoint(x: 10.18, y: 9.93))
        topPath.addCurve(to: CGPoint(x: 8.06, y: 9.93), controlPoint1: CGPoint(x: 9.6, y: 10.51), controlPoint2: CGPoint(x: 8.65, y: 10.51))
        topPath.addCurve(to: CGPoint(x: 8.06, y: 7.8), controlPoint1: CGPoint(x: 7.47, y: 9.34), controlPoint2: CGPoint(x: 7.47, y: 8.39))
        topPath.addLine(to: CGPoint(x: 12.24, y: 3.62))
        topPath.addCurve(to: CGPoint(x: 15.58, y: 0.26), controlPoint1: CGPoint(x: 13.99, y: 1.88), controlPoint2: CGPoint(x: 15.5, y: 0.31))
        topPath.addCurve(to: CGPoint(x: 16.48, y: 0), controlPoint1: CGPoint(x: 15.85, y: 0.07), controlPoint2: CGPoint(x: 16.17, y: -0.01))
        topPath.close()
        UIColor.gray.setFill()
        topPath.fill()

        let image = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()

        return image
    }
}
