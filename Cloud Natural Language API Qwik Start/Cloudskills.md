### 💡 Lab Link: [Cloud Natural Language API: Qwik Start](https://www.skills.google/games/6981/labs/43370)
---

### ⚠️ Disclaimer
- **This script and guide are provided for  the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services. Ensure that you follow 'Qwiklabs' terms of service and YouTube’s community guidelines. The goal is to enhance your learning experience, not to bypass it.**

---

✅ **NOTE:** *Watch Full Video to get Full Scores on Check My Progress.*

🌐Launch Cloud Shell:
Start your Google CloudShell session by [clicking here](https://console.cloud.google.com/home/dashboard?project=&pli=1&cloudshell=true).

### 🚨Copy and run the below commands in Cloud Shell:

```
gcloud auth list
gcloud config list project
export GOOGLE_CLOUD_PROJECT=$(gcloud config get-value core/project)
gcloud iam service-accounts create my-natlang-sa \
  --display-name "my natural language service account"
gcloud iam service-accounts keys create ~/key.json \
  --iam-account my-natlang-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com
export GOOGLE_APPLICATION_CREDENTIALS="/home/USER/key.json"
gcloud compute ssh --zone "us-central1-a" "linux-instance" --project "$GOOGLE_CLOUD_PROJECT"
```

```
gcloud ml language analyze-entities --content="Michelangelo Caravaggio, Italian painter, is known for 'The Calling of Saint Matthew'." > result.json
```


---

### Congratulations, you're all done with the lab 😄

---

### 🌐 Join our Community

- <img src="https://github.com/user-attachments/assets/a4a4b767-151c-461d-bca1-da6d4c0cd68a" alt="icon" width="25" height="25"> **Join our [Telegram Channel](https://t.me/FutureCloudSkill) for the latest updates for the lab enquiry**


---

# <img src="https://github.com/user-attachments/assets/6ee41001-c795-467c-8d96-06b56c246b9c" alt="icon" width="45" height="45"> [Future Cloud Skill](https://www.youtube.com/@FutureCloudSkill/featured) Don't Forget to like share & subscribe

### Thanks for watching and stay connected :)


---


