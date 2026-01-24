

### 💡 Lab Link: [Configuring IAM Permissions with gcloud - GSP647](https://www.cloudskillsboost.google/focuses/7678?parent=catalog)

---

### ⚠️ Disclaimer
- **This script and guide are provided for  the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services. Ensure that you follow 'Qwiklabs' terms of service and YouTube’s community guidelines. The goal is to enhance your learning experience, not to bypass it.**

### ©Credit
- **DM for credit or removal request (no copyright intended) ©All rights and credits for the original content belong to Google Cloud [Google Cloud Skill Boost website](https://www.cloudskillsboost.google/)** 🙏

---

### 🚀 Copy and run the below commands in Cloud Shell:

```
export ZONE=$(gcloud compute instances list --filter="name=centos-clean" --format="value(zone)")
gcloud compute ssh centos-clean --zone=$ZONE --quiet
```

```
curl -LO raw.githubusercontent.com/FutureCloudSkill/CloudSkill/master/Configuring%20IAM%20Permissions%20with%20gcloud/fcs647.sh
sudo chmod +x fcs647.sh
./fcs647.sh
```

---

### Congratulations, you're all done with the lab 😄

---

### 🌐 Join our Community

- <img src="https://github.com/user-attachments/assets/a4a4b767-151c-461d-bca1-da6d4c0cd68a" alt="icon" width="25" height="25"> **Join our [Telegram Channel](https://t.me/FutureCloudSkill) for the latest updates.

---

# <img src="https://github.com/user-attachments/assets/6ee41001-c795-467c-8d96-06b56c246b9c" alt="icon" width="45" height="45"> [Future Cloud Skill](https://www.youtube.com/@FutureCloudSkill) Don't Forget to like share & subscribe

### Thanks for watching and stay connected :)
---
