import sys

from query.answer import answer

if __name__ == "__main__":
    question = sys.argv[1]
    print(answer(question))
