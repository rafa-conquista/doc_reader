import pickle

import faiss
import numpy as np
from openai import OpenAI

from config import DATA_PATH, EMBEDDING_MODEL, OPENAI_API_KEY

client = OpenAI(api_key=OPENAI_API_KEY)


def embed_and_store(chunks_with_meta):
    if not chunks_with_meta:
        raise ValueError("Lista de chunks vazia. Nada para indexar.")

    vectors = []
    metadatas = []

    for item in chunks_with_meta:
        emb = client.embeddings.create(model=EMBEDDING_MODEL, input=item["chunk"])
        vectors.append(emb.data[0].embedding)
        metadatas.append(item)

    dim = len(vectors[0])
    index = faiss.IndexFlatL2(dim)
    index.add(np.array(vectors).astype("float32"))

    faiss.write_index(index, f"{DATA_PATH}/faiss.index")

    with open(f"{DATA_PATH}/metadata.pkl", "wb") as f:
        pickle.dump(metadatas, f)

    print(f"[INGEST] FAISS index criado com {len(vectors)} vetores")
