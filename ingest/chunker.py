import tiktoken

tokenizer = tiktoken.get_encoding("cl100k_base")


def chunk_text(text, chunk_size=500, overlap=80):
    tokens = tokenizer.encode(text)
    chunks = []

    start = 0
    while start < len(tokens):
        end = start + chunk_size
        chunk = tokenizer.decode(tokens[start:end])
        chunks.append(chunk)
        start = end - overlap

    return chunks
