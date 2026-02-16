### 💡 Lab Link: [Build an Application to Generate Text Embeddings with Gemini on Vertex AI](https://www.skills.google/games/6982/labs/43381)
---

### ⚠️ Disclaimer
- **This script and guide are provided for  the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services. Ensure that you follow 'Qwiklabs' terms of service and YouTube’s community guidelines. The goal is to enhance your learning experience, not to bypass it.**

### ©Credit
- **DM for credit or removal request (no copyright intended) ©All rights and credits for the original content belong to Google Cloud [Google Cloud Skill Boost website](https://www.cloudskillsboost.google/)** 🙏

---

### 🚨Copy and run the below commands in Cloud Shell:

```
import vertexai
from vertexai.language_models import TextEmbeddingModel

def text_embedding(prompt):
    vertexai.init(project="REPLACE_YOUR_PROJECT_ID", location="us-central1")
    model = TextEmbeddingModel.from_pretrained("text-embedding-005")
    embeddings = model.get_embeddings([prompt])
    vector = embeddings[0].values
    print(f"Length of embedding vector: {len(vector)}")
    return vector

if __name__ == "__main__":
    sample_text = "CloudyGyn"
    print(f"Processing text: '{sample_text}'")
    text_embedding(sample_text)

```
---

### Congratulations, you're all done with the lab 😄

---

### 🌐 Join our Community

- <img src="https://github.com/user-attachments/assets/a4a4b767-151c-461d-bca1-da6d4c0cd68a" alt="icon" width="25" height="25"> **Join our [Telegram Channel](https://t.me/CloudyGyn)

---

# <img src="https://github.com/user-attachments/assets/6ee41001-c795-467c-8d96-06b56c246b9c" alt="icon" width="45" height="45"> [CloudyGyn](https://www.youtube.com/@CloudyGynOfficial) Don't Forget to like share & subscribe

### Thanks for watching and stay connected :)
---
