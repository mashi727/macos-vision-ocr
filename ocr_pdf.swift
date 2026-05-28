#!/usr/bin/swift
// ocr_pdf.swift
import Vision
import AppKit
import PDFKit

guard CommandLine.arguments.count > 1 else {
    print("Usage: swift ocr_pdf.swift <pdf_path> [language1,language2,...]")
    print("Example: swift ocr_pdf.swift document.pdf ja,en")
    exit(1)
}

let pdfPath = CommandLine.arguments[1]
let languages = CommandLine.arguments.count > 2
    ? CommandLine.arguments[2].split(separator: ",").map(String.init)
    : ["ja", "en"]

guard let pdfURL = URL(string: "file://\(pdfPath)") ?? URL(string: pdfPath),
      let pdfDocument = PDFDocument(url: URL(fileURLWithPath: pdfPath)) else {
    fputs("Error: Cannot open PDF: \(pdfPath)\n", stderr)
    exit(1)
}

let pageCount = pdfDocument.pageCount
fputs("Processing \(pageCount) page(s)...\n", stderr)

func ocrCGImage(_ cgImage: CGImage, languages: [String]) -> String {
    var resultText = ""
    let semaphore = DispatchSemaphore(value: 0)
    
    let request = VNRecognizeTextRequest { request, error in
        defer { semaphore.signal() }
        if let error = error {
            fputs("OCR error: \(error)\n", stderr)
            return
        }
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        resultText = observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
    
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = languages
    
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
        try handler.perform([request])
    } catch {
        fputs("Handler error: \(error)\n", stderr)
        semaphore.signal()
    }
    
    semaphore.wait()
    return resultText
}

for pageIndex in 0..<pageCount {
    guard let page = pdfDocument.page(at: pageIndex) else {
        fputs("Warning: Cannot load page \(pageIndex + 1)\n", stderr)
        continue
    }
    
    fputs("  Page \(pageIndex + 1)/\(pageCount)...\n", stderr)
    
    // PDFページをCGImageに変換（300 DPI相当）
    let pageRect = page.bounds(for: .mediaBox)
    let scale: CGFloat = 2.0  // 150dpi base × 2 = 300dpi相当
    let width = Int(pageRect.width * scale)
    let height = Int(pageRect.height * scale)
    
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
          let context = CGContext(
              data: nil,
              width: width,
              height: height,
              bitsPerComponent: 8,
              bytesPerRow: 0,
              space: colorSpace,
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          ) else {
        fputs("Warning: Cannot create CGContext for page \(pageIndex + 1)\n", stderr)
        continue
    }
    
    // 白背景
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    
    context.scaleBy(x: scale, y: scale)
    page.draw(with: .mediaBox, to: context)
    
    guard let cgImage = context.makeImage() else {
        fputs("Warning: Cannot render page \(pageIndex + 1)\n", stderr)
        continue
    }
    
    let text = ocrCGImage(cgImage, languages: languages)
    
    print("=== Page \(pageIndex + 1) ===")
    print(text)
    print("")
}

fputs("Done.\n", stderr)