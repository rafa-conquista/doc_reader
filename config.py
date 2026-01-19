import os

from dotenv import load_dotenv

load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

EMBEDDING_MODEL = "text-embedding-3-small"
TOP_K = 4

KNOWLEDGE_BASE_PATH = "knowledge_base"
DATA_PATH = "data"
