/**
 *  https://github.com/tadija/AEXML
 *  Copyright © Marko Tadić 2014-2021
 *  Licensed under the MIT license
 */

import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

/// Simple wrapper around `Foundation.XMLParser`.
internal class AEXMLParser: NSObject, XMLParserDelegate {
    
    // MARK: - Properties
    
    let document: AEXMLDocument
    let data: Data
    let url: URL?
    let stream: InputStream?

    var currentParent: AEXMLElement?
    var currentElement: AEXMLElement?
    var currentValue = String()
    
    var parseError: Error?

    private lazy var parserSettings: AEXMLOptions.ParserSettings = {
        return document.options.parserSettings
    }()
    
    // MARK: - Lifecycle
    
    init(document: AEXMLDocument, data: Data) {
        self.document = document
        self.data = data
        self.url = nil
        self.stream = nil
        currentParent = document
        
        super.init()
    }


    init(document: AEXMLDocument, url: URL) {
        self.document = document
        self.data = Data()
        self.url = url
        self.stream = nil
        currentParent = document
        super.init()
        
    }


    init(document: AEXMLDocument, stream: InputStream) {
        self.document = document
        self.data = Data()
        self.url = nil
        self.stream = stream
        currentParent = document
        super.init()

    }

    // MARK: - API
    
    func parse() throws {
        let parser = XMLParser(data: data)
        parser.delegate = self

        parser.shouldProcessNamespaces = parserSettings.shouldProcessNamespaces
        parser.shouldReportNamespacePrefixes = parserSettings.shouldReportNamespacePrefixes
        parser.shouldResolveExternalEntities = parserSettings.shouldResolveExternalEntities
        
        let success = parser.parse()
        
        if !success {
            guard let error = parseError else { throw AEXMLError.parsingFailed }
            throw error
        }
    }

    func parseFile() throws {
        guard let url = url else { throw AEXMLError.parsingFailed }
        guard let parser = XMLParser(contentsOf: url) else { throw AEXMLError.parsingFailed }

        parser.delegate = self
        parser.shouldProcessNamespaces = parserSettings.shouldProcessNamespaces
        parser.shouldReportNamespacePrefixes = parserSettings.shouldReportNamespacePrefixes
        parser.shouldResolveExternalEntities = parserSettings.shouldResolveExternalEntities

        let success = parser.parse()

        if !success {
            guard let error = parseError else { throw AEXMLError.parsingFailed }
            throw error
        }
    }

    func parseStream() throws {
        guard let stream = stream else { throw AEXMLError.parsingFailed }
        let parser = XMLParser(stream: stream)

        parser.delegate = self
        parser.shouldProcessNamespaces = parserSettings.shouldProcessNamespaces
        parser.shouldReportNamespacePrefixes = parserSettings.shouldReportNamespacePrefixes
        parser.shouldResolveExternalEntities = parserSettings.shouldResolveExternalEntities

        let success = parser.parse()

        if !success {
            guard let error = parseError else { throw AEXMLError.parsingFailed }
            throw error
        }
    }

    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String]) {
        currentValue = String()
        currentElement = currentParent?.addChild(name: elementName, attributes: attributeDict)
        currentParent = currentElement
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue.append(string)
        currentElement?.value = currentValue.isEmpty ? nil : currentValue
    }
    
    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        if parserSettings.shouldTrimWhitespace {
            currentElement?.value = currentElement?.value?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        currentParent = currentParent?.parent
        currentElement = nil
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }
    
}
