# macos-vision-ocr

A tiny, dependency-free command-line OCR tool for macOS that extracts text from
PDF files using Apple's [Vision](https://developer.apple.com/documentation/vision)
framework. Each PDF page is rendered at ~300 DPI and recognized with
`VNRecognizeTextRequest`, so it works fully offline and supports multiple
languages (Japanese and English by default).

## Features

- **Offline** — uses the on-device Vision OCR engine; no network or API key required.
- **Multilingual** — recognizes any language combination supported by Vision (e.g. `ja`, `en`).
- **High accuracy** — uses `.accurate` recognition level with language correction enabled.
- **Single file** — one self-contained Swift script, no third-party dependencies.

## Requirements

- macOS (Apple Silicon or Intel)
- Swift toolchain (bundled with [Xcode](https://developer.apple.com/xcode/) or the [Command Line Tools](https://developer.apple.com/download/all/))

## Usage

The script can be run directly with the Swift interpreter:

```bash
swift ocr_pdf.swift <pdf_path> [language1,language2,...]
```

Examples:

```bash
# Japanese + English (default)
swift ocr_pdf.swift document.pdf

# Specify languages explicitly
swift ocr_pdf.swift document.pdf ja,en

# English only
swift ocr_pdf.swift invoice.pdf en
```

Recognized text is written to **stdout** (progress messages go to stderr), so you
can redirect it to a file:

```bash
swift ocr_pdf.swift document.pdf ja,en > output.txt
```

### Output format

```
=== Page 1 ===
<recognized text for page 1>

=== Page 2 ===
<recognized text for page 2>
```

## Build (optional)

For faster startup you can compile the script into a native binary:

```bash
swiftc -O ocr_pdf.swift -o ocr_pdf
./ocr_pdf document.pdf ja,en
```

> The compiled `ocr_pdf` binary is intentionally excluded from version control
> (see `.gitignore`); build it locally as shown above.

## How it works

1. The PDF is loaded with **PDFKit** (`PDFDocument`).
2. Each page is rendered into a `CGImage` at 2× scale (≈300 DPI) on a white background.
3. The image is passed to **Vision**'s `VNRecognizeTextRequest` with
   `.accurate` recognition and language correction.
4. The top text candidate per observation is collected and printed per page.

## Supported languages

Language codes follow Vision's `recognitionLanguages`. To list the languages
supported on your machine:

```swift
import Vision
let request = VNRecognizeTextRequest()
print(try request.supportedRecognitionLanguages())
```

Common codes: `en`, `ja`, `zh-Hans`, `zh-Hant`, `ko`, `fr`, `de`, `es`, `it`, `pt`.

## License

[MIT](LICENSE) © mashi727
