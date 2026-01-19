from pathlib import Path

import pytesseract
from pdf2image import convert_from_path
from pypdf import PdfReader


def load_documents(base_path: str):
    docs = []

    for file in Path(base_path).rglob("*"):
        if file.suffix.lower() == ".md":
            docs.append(
                {"content": file.read_text(encoding="utf-8"), "source": str(file)}
            )

        elif file.suffix.lower() == ".pdf":
            reader = PdfReader(str(file))
            pages_text = []

            for page in reader.pages:
                try:
                    text = page.extract_text()
                    if text:
                        pages_text.append(text)
                except Exception:
                    pass

            # 🔥 FALLBACK OCR
            if not pages_text:
                print(f"[INFO] Usando OCR para {file}")
                images = convert_from_path(str(file))
                for img in images:
                    text = pytesseract.image_to_string(img)
                    if text.strip():
                        pages_text.append(text)

            if pages_text:
                docs.append({"content": "\n".join(pages_text), "source": str(file)})

    return docs
