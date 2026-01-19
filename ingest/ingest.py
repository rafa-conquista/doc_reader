from config import KNOWLEDGE_BASE_PATH
from ingest.chunker import chunk_text
from ingest.embedder import embed_and_store
from ingest.loader import load_documents


def run():
    docs = load_documents(KNOWLEDGE_BASE_PATH)
    print(f"[INGEST] Docs carregados: {len(docs)}")

    chunks = []
    for doc in docs:
        doc_chunks = chunk_text(doc["content"])
        print(f"[INGEST] {doc['source']} → {len(doc_chunks)} chunks")

        for chunk in doc_chunks:
            if chunk.strip():
                chunks.append({"chunk": chunk, "source": doc["source"]})

    print(f"[INGEST] Total de chunks: {len(chunks)}")

    if not chunks:
        raise RuntimeError("Nenhum chunk gerado. Verifique knowledge_base.")

    embed_and_store(chunks)


if __name__ == "__main__":
    run()
