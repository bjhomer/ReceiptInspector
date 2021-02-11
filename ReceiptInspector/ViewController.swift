//
//  ViewController.swift
//  ReceiptInspector
//
//  Created by BJ Homer on 7/5/17.
//  Copyright © 2017 BJ Homer. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, DragTargetViewDelegate {

    @IBOutlet var textView: NSTextView!
    @IBOutlet var dropTarget: DragTargetView!
    @IBOutlet var fileNameField: NSTextField!
    @IBOutlet var sandboxCheckbox: NSButton!
    
    private var url: URL? = nil {
        didSet { updateForURL() }
    }
    private var receiptContents: String = "" {
        didSet { updateTextView() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dropTarget.delegate = self
        updateForURL()
    }

    private func updateForURL() {
        fileNameField.stringValue = url?.lastPathComponent ?? ""
        startRequestForReceipt()
    }
    
    private func updateTextView() {
        let attrs = [NSAttributedString.Key.font: NSFont(name: "Menlo", size: 12)!]
        let attrString = NSAttributedString(string: receiptContents, attributes: attrs)
        
        textView.textStorage?.setAttributedString(attrString)
    }
    
    func dragTargetViewChangedURL(_ dragTargetView: DragTargetView) {
        self.url = dragTargetView.url
    }

    @IBAction func toggledSandboxMode(_ sender: Any) {
        startRequestForReceipt()
    }
    
    private func startRequestForReceipt() {
        guard
            let url = self.url,
            let contents = try? Data(contentsOf: url)
        else { return }
    
        let base64Contents = contents.base64EncodedString()
        
        let useSandbox = sandboxCheckbox.state == .on
        
        let dict: [String: Any] = ["receipt-data": base64Contents, "password": "98bfa11e610f4af9af6f2104dffade2a", "exclude-old-transactions": "true"]
        let json = try! JSONSerialization.data(withJSONObject: dict)
        
        let session = URLSession(configuration: .default)
        
        let subdomain = (useSandbox ? "sandbox" : "buy")
        
        let requestURL = URL(string: "https://\(subdomain).itunes.apple.com/verifyReceipt")!
        var urlRequest = URLRequest(url: requestURL)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = json
        
        let task = session.dataTask(with: urlRequest) { (data, _, error) in
            
            let resultToDisplay: String
            if let data = data,
                let jsonDict = (try? JSONSerialization.jsonObject(with: data)) as? Dictionary<String, Any>,
                let prettyData = try? JSONSerialization.data(withJSONObject: jsonDict, options: [.prettyPrinted])
            {
                resultToDisplay = String(data: prettyData, encoding: .utf8) ?? "(Error)"
            }
            else if let error = error {
                resultToDisplay = error.localizedDescription
            }
            else {
                resultToDisplay = "(Unknown error)"
            }
            
            DispatchQueue.main.async {
                self.receiptContents = resultToDisplay
            }
        }
        task.resume()
    }
}

extension Dictionary where Key == String {
    func prettyPrinted(indentation: Int = 0) -> String {
        
        let keys = self.keys.sorted()
        
        var lines: [String] = []
        
        let outerPrefix = String(repeating: " ", count: indentation)
        let innerPrefix = String(repeating: " ", count: indentation + 2)
        
        for key in keys {
            let value = self[key]
            var lineValue: String
            
            if let subValue = value as? Dictionary<String, Any> {
                let result = subValue.prettyPrinted(indentation: indentation+2)
                lineValue = result
            }
            else if let arrayValue = value as? Array<Any> {
                lineValue = arrayValue.prettyPrinted(indentation: indentation+2)
            }
            else if let stringValue = value as? String {
                lineValue = "\"\(stringValue)\""
            }
            else {
                let optValue = value as Optional<Any>
                lineValue = optValue.map{ String(describing: $0) } ?? "nil"
            }
            
            let keyPrefix = "\"\(key)\":  "
            lines.append(innerPrefix + keyPrefix + lineValue)
        }
        
        
        var result = ""
        result.append("{\n")
        result.append(lines.joined(separator: ",\n"))
        result.append("\n" + outerPrefix + "}")
        
        return result
    }
}

extension Array {
    func prettyPrinted(indentation: Int = 0) -> String {
        let outerPrefix = String(repeating: " ", count: indentation)
        let innerPrefix = String(repeating: " ", count: indentation + 2)
        
        let lines = self.map { (x) -> String in
            switch x {
            case let array as Array:
                return array.prettyPrinted(indentation: indentation + 2)
            case let dict as Dictionary<String, Any>:
                return dict.prettyPrinted(indentation: indentation + 2)
            case let other:
                return innerPrefix + String(describing: other)
            }
        }
        
        
        var result = ""
        result.append("[\n")
        result.append(lines.joined(separator: ",\n"))
        result.append(outerPrefix + "]")
        return result
    }
}


