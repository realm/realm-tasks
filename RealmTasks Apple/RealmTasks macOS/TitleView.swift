////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016-2017 Realm Inc.
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

class TitleView: NSView {

    let textField: NSTextField = {
        let textField = NSTextField()

        textField.isEditable = false
        textField.isBordered = false
        textField.drawsBackground = false
        textField.lineBreakMode = .byTruncatingTail

        return textField
    }()

    var text: String {
        get {
            return textField.stringValue
        }

        set {
            textField.stringValue = newValue
            updateTextFieldFrame()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        addSubview(textField)
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)

        updateTextFieldFrame()
    }

    private func updateTextFieldFrame() {
        textField.sizeToFit()

        var frame = textField.frame
        frame.size.width = min(bounds.width, frame.width)

        // Center text view horizontally in window ...
        frame.origin = NSPoint(x: (window!.frame.width - textField.frame.width) / 2, y: 0)
        frame.origin.x = max(convert(frame.origin, from: window?.contentView).x, 0)
        // ... and vertically in self
        frame.origin.y = (bounds.height - textField.frame.height) / 2

        // Float values leads to blurred drawing on non-retina screens
        frame = frame.integral

        textField.frame = frame
    }

}
