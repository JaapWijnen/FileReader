import Foundation

public class FileReader {
    
    private let fileHandle: FileHandle?
    private var buffer: Data
    private var bufferIndex: Int?
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
        self.bufferIndex = self.buffer.startIndex
        
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
        
        if let fileHandle = self.fileHandle { // FileReader created from FileHandle
            while true {
                if let range = buffer.range(of: self.delimPattern, options: [], in: buffer.startIndex..<buffer.endIndex) {
                    let subData = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
                    let line = String(data: subData, encoding: self.encoding)
                    buffer.replaceSubrange(buffer.startIndex..<range.upperBound, with: [])
                    return line
                } else {
                    let temporaryData = fileHandle.readData(ofLength: self.chunkSize)
                    if temporaryData.count == 0 {
                        self.isAtEOF = true
                        return (self.buffer.count > 0) ? String(data: self.buffer, encoding: self.encoding) : nil
                    }
                    buffer.append(temporaryData)
                }
            }
        } else if let bufferIndex = bufferIndex { // FileReader created from String
            if let range = buffer.range(of: self.delimPattern, options: [], in: bufferIndex..<buffer.endIndex) {
                let subData = buffer.subdata(in: bufferIndex..<range.lowerBound)
                let line = String(data: subData, encoding: self.encoding)
                
                // update bufferIndex
                self.bufferIndex = range.upperBound
                
                return line
            } else {
                self.isAtEOF = true
                let subData = buffer.subdata(in: bufferIndex..<buffer.endIndex)
                return (subData.count > 0) ? String(data: subData, encoding: self.encoding) : nil
            }
        } else {
            fatalError("Neither filehandle nor bufferindex is found. But one or the other should be created when working with a file or direct string.")
        }
    }
    
    public func lineCount() -> Int {
        if let fileHandle = self.fileHandle { // FileReader created from FileHandle
            // save current state
            let oldBuffer = self.buffer
            let oldIsAtEOF = self.isAtEOF
            let oldOffset = fileHandle.offsetInFile
            
            // reset fileHandle
            fileHandle.seek(toFileOffset: 0)
            
            var lineCount = 0
            
            while !isAtEOF {
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
            
            // reset to old state
            self.buffer = oldBuffer
            self.isAtEOF = oldIsAtEOF
            fileHandle.seek(toFileOffset: oldOffset)
            
            return lineCount
            
        } else if var bufferIndex = self.bufferIndex { // FileReader created from String
            
            // save current state
            let oldIsAtEOF = self.isAtEOF
            let oldBufferIndex = bufferIndex
            
            bufferIndex = self.buffer.startIndex
            
            var lineCount = 0
            
            while !isAtEOF {
                if let range = buffer.range(of: self.delimPattern, options: [], in: bufferIndex..<buffer.endIndex) {
                    bufferIndex = range.upperBound
                    lineCount += 1
                } else {
                    self.isAtEOF = true
                    let subData = buffer.subdata(in: bufferIndex..<buffer.endIndex)
                    if subData.count > 0 {
                        lineCount += 1
                    }
                }
            }
            
            // reset to old state
            self.isAtEOF = oldIsAtEOF
            self.bufferIndex = oldBufferIndex
            
            return lineCount
            
        } else {
            fatalError("Neither filehandle nor bufferindex is found. But one or the other should be created when working with a file or direct string.")
        }
    }
    
    public func linesLeft() -> Int {

        if let fileHandle = self.fileHandle { // FileReader created from FileHandle
            
            // save current state
            let oldBuffer = self.buffer
            let oldIsAtEOF = self.isAtEOF
            let oldOffset = fileHandle.offsetInFile
            
            var lineCount = 0
            
            while !isAtEOF {
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
            
            // reset to old state
            self.buffer = oldBuffer
            self.isAtEOF = oldIsAtEOF
            fileHandle.seek(toFileOffset: oldOffset)
            
            return lineCount
            
        } else if var bufferIndex = self.bufferIndex { // FileReader created from String
            
            // save current state
            let oldIsAtEOF = self.isAtEOF
            let oldBufferIndex = bufferIndex
                        
            var lineCount = 0
            
            while !isAtEOF {
                if let range = buffer.range(of: self.delimPattern, options: [], in: bufferIndex..<buffer.endIndex) {
                    bufferIndex = range.upperBound
                    lineCount += 1
                } else {
                    self.isAtEOF = true
                    let subData = buffer.subdata(in: bufferIndex..<buffer.endIndex)
                    if subData.count > 0 {
                        lineCount += 1
                    }
                }
            }
            
            // reset to old state
            self.isAtEOF = oldIsAtEOF
            self.bufferIndex = oldBufferIndex
            
            return lineCount
            
        } else {
            fatalError("Neither filehandle nor bufferindex is found. But one or the other should be created when working with a file or direct string.")
        }
    }
}

enum FileReaderError: Error {
    case cannotCreateDataFromString
}
