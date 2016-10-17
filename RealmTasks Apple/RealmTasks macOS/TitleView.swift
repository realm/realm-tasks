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

class TitleView: NSView {

    let textField: NSTextField = {
        let textField = NSTextField()

        textField.editable = false
        textField.bordered = false
        textField.drawsBackground = false

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

    override func resizeSubviewsWithOldSize(oldSize: NSSize) {
        super.resizeSubviewsWithOldSize(oldSize)

        updateTextFieldFrame()
    }

    private func updateTextFieldFrame() {
        textField.sizeToFit()

        // Center text view horizontally in window ...
        var point = NSPoint(x: (window!.frame.width - textField.frame.width) / 2, y: 0)
        point = convertPoint(point, fromView: window?.contentView)
        // ... and vertically in self
        point.y = (bounds.height - textField.frame.height) / 2

        textField.frame.origin = point
    }

}
