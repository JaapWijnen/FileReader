import Foundation

public class FileReader {
    
    private let fileHandle: FileHandle?
    private var buffer: Data
    private let chunkSize: Int
    private let delimPattern: Data
    public let encoding: String.Encoding
    private var isAtEOF: Bool = false
    
    @inlinable
    public convenience init(fileAtPath path: String, delimiter: String = "\n", chunkSize: Int = 4096, encoding: String.Encoding = .utf8) throws {
        let url = URL(fileURLWithPath: path)
        try self.init(url: url, delimiter: delimiter, chunkSize: chunkSize, encoding: encoding)
    }
    
    @inlinable
    public convenience init(url: URL, delimiter: String = "\n", chunkSize: Int = 4096, encoding: String.Encoding = .utf8) throws {
        let fileHandle = try FileHandle(forReadingFrom: url)
        self.init(fileHandle: fileHandle, delimiter: delimiter, chunkSize: chunkSize, encoding: encoding)
    }
    
    public init(fileHandle: FileHandle, delimiter: String = "\n", chunkSize: Int = 4096, encoding: String.Encoding = .utf8) {
        self.fileHandle = fileHandle
        self.encoding = encoding
        self.delimPattern = delimiter.data(using: self.encoding)!
        self.chunkSize = chunkSize
        self.buffer = Data(capacity: self.chunkSize)
    }
    
    public init(string: String, delimiter: String = "\n") throws {
        self.encoding = .utf8
        
        guard let stringData = string.data(using: self.encoding) else {
            throw FileReaderError.cannotCreateDataFromString
        }
        self.buffer = stringData
        self.delimPattern = delimiter.data(using: self.encoding)!
        
        // unnecessary properties when reading from a string
        self.fileHandle = nil
        self.chunkSize = 0
    }
    
    deinit {
        fileHandle?.closeFile()
    }
    
    public func readLine() -> String? {
        if isAtEOF { return nil }
        
        while true {
            if let range = buffer.range(of: self.delimPattern, options: [], in: buffer.startIndex..<buffer.endIndex) {
                let subData = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
                let line = String(data: subData, encoding: self.encoding)
                buffer.replaceSubrange(buffer.startIndex..<range.upperBound, with: [])
                return line
            } else {
                if let fileHandle = self.fileHandle {
                    let temporaryData = fileHandle.readData(ofLength: self.chunkSize)
                    if temporaryData.count == 0 {
                        self.isAtEOF = true
                        return (self.buffer.count > 0) ? String(data: self.buffer, encoding: self.encoding) : nil
                    }
                    buffer.append(temporaryData)
                } else {
                    self.isAtEOF = true
                    return (buffer.count > 0) ? String(data: self.buffer, encoding: self.encoding) : nil
                }
            }
        }
    }
    
    public func lineCount() -> Int {
        
        // if initialized from a file handle create temporary buffer and restore back to old state when finished
        if let fileHandle = self.fileHandle {
            let oldBuffer = buffer
            let oldIsAtEOF = isAtEOF
            
            self.buffer = Data(capacity: self.chunkSize)
            self.isAtEOF = false
            
            var lineCount = 0
            
            while !self.isAtEOF {
                if let range = buffer.range(of: self.delimPattern, options: [], in: buffer.startIndex..<buffer.endIndex) {
                    buffer.replaceSubrange(buffer.startIndex..<range.upperBound, with: [])
                    lineCount += 1
                } else {
                    let temporaryData = fileHandle.readData(ofLength: self.chunkSize)
                    if temporaryData.count == 0 {
                        self.isAtEOF = true
                        if self.buffer.count > 0 {
                            lineCount += 1
                        }
                    }
                    buffer.append(temporaryData)
                }
            }
            
            
            // reset to previous state
            self.buffer = oldBuffer
            self.isAtEOF = oldIsAtEOF
            
            return lineCount
        } else { // if initialized from string, just count occurences in current buffer
            var lineCount = 0
            
            while !self.isAtEOF {
                if let range = self.buffer.range(of: self.delimPattern, options: [], in: buffer.startIndex..<buffer.endIndex) {
                    buffer.replaceSubrange(buffer.startIndex..<range.upperBound, with: [])
                    lineCount += 1
                } else {
                    self.isAtEOF = true
                    if buffer.count > 0 {
                        lineCount += 1
                    }
                }
            }
            
            return lineCount
        }
    }
}

enum FileReaderError: Error {
    case cannotCreateDataFromString
}
