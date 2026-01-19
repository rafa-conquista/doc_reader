import pickle

import faiss
import numpy as np
from openai import OpenAI

from config import DATA_PATH, EMBEDDING_MODEL, TOP_K

client = OpenAI()


def retrieve(query: str):
    index = faiss.read_index(f"{DATA_PATH}/faiss.index")

    with open(f"{DATA_PATH}/metadata.pkl", "rb") as f:
        metadata = pickle.load(f)

    emb = client.embeddings.create(model=EMBEDDING_MODEL, input=query).data[0].embedding

    D, I = index.search(np.array([emb]).astype("float32"), TOP_K)

    return [metadata[i] for i in I[0]]
