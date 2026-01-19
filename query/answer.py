from openai import OpenAI

from query.retriever import retrieve

client = OpenAI()

SYSTEM_PROMPT = """
Você é um assistente técnico.
Responda apenas com base no contexto fornecido.
Se a resposta não estiver no contexto, diga que não encontrou.
"""


def answer(question: str):
    chunks = retrieve(question)

    context = "\n\n".join(f"Fonte: {c['source']}\n{c['chunk']}" for c in chunks)

    response = client.chat.completions.create(
        model="gpt-4.1-mini",
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {
                "role": "user",
                "content": f"Contexto:\n{context}\n\nPergunta:\n{question}",
            },
        ],
    )

    return response.choices[0].message.content
