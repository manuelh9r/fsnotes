//
//  TitleTextField.swift
//  FSNotes
//
//  Created by Олександр Глущенко on 5/10/19.
//  Copyright © 2019 Oleksandr Glushchenko. All rights reserved.
//

import Cocoa
import Carbon.HIToolbox

class TitleTextField: NSTextField {
    public var restoreResponder: NSResponder?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command)
            && event.keyCode == kVK_ANSI_C
            && !event.modifierFlags.contains(.shift)
            && !event.modifierFlags.contains(.control)
            && !event.modifierFlags.contains(.option) {
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            pasteboard.setString(self.stringValue, forType: NSPasteboard.PasteboardType.string)
        }

        return super.performKeyEquivalent(with: event)
    }

    override func becomeFirstResponder() -> Bool {
        if let note = EditTextView.note {
            stringValue = note.getFileName()
        }

        return super.becomeFirstResponder()
    }

    override func textDidEndEditing(_ notification: Notification) {
        guard stringValue.count > 0, let vc = ViewController.shared(), let note = EditTextView.note else { return }

        let currentTitle = stringValue
        let currentName = note.getFileName()

        if currentName != currentTitle {
            let ext = note.url.pathExtension
            let dst = note.project.url.appendingPathComponent(currentTitle).appendingPathExtension(ext)

            if !FileManager.default.fileExists(atPath: dst.path), note.move(to: dst) {
                vc.updateTitle(newTitle: currentTitle)

                updateNotesTableView()
                return
            } else {
                let alert = NSAlert()
                alert.alertStyle = .critical
                alert.informativeText = NSLocalizedString("File with name \"\(currentTitle)\" already exists!", comment: "")
                alert.messageText = NSLocalizedString("Incorrect file name", comment: "")
                alert.runModal()
            }
        }

        vc.updateTitle(newTitle: currentName)

        updateNotesTableView()
    }

    public func updateNotesTableView() {
        guard let vc = ViewController.shared(), let note = EditTextView.note else { return }

        if note.container == .encryptedTextPack && !note.isUnlocked() {
            vc.notesTableView.reloadRow(note: note)
        }

        if let responder = restoreResponder {
            window?.makeFirstResponder(responder)
        }
    }
}
