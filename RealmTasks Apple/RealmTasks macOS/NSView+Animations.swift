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

import Cocoa

extension NSView {

    static var defaultAnimationDuration: NSTimeInterval {
        return 0.2
    }

    static var defaultAnimationTimingFunction: CAMediaTimingFunction {
        return CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
    }

    static func animate(duration duration: NSTimeInterval = defaultAnimationDuration,
                                 timingFunction: CAMediaTimingFunction = defaultAnimationTimingFunction,
                                 animations: () -> Void,
                                 completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ context in
            context.allowsImplicitAnimation = true

            context.duration = duration
            context.timingFunction = timingFunction

            animations()
        }, completionHandler: completion)
    }

    // Convenience method for trailing closure syntax without completion handler
    static func animate(duration duration: NSTimeInterval = defaultAnimationDuration,
                                 timingFunction: CAMediaTimingFunction = defaultAnimationTimingFunction,
                                 animations: () -> Void) {
        animate(duration: duration, timingFunction: timingFunction, animations: animations, completion: nil)
    }

}
