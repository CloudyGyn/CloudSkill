### 💡 Lab Link: [VPC Flow Logs - Analyzing Network Traffic - GSP212](https://www.skills.google/focuses/1236?catalog_rank=%7B%22rank%22%3A1%2C%22num_filters%22%3A0%2C%22has_search%22%3Atrue%7D&parent=catalog&search_id=72594698)

---

### ⚠️ Disclaimer
- **This script and guide are provided for  the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services. Ensure that you follow 'Qwiklabs' terms of service and YouTube’s community guidelines. The goal is to enhance your learning experience, not to bypass it.**

### ©Credit
- **DM for credit or removal request (no copyright intended) ©All rights and credits for the original content belong to Google Cloud [Google Cloud Skill Boost website](https://www.cloudskillsboost.google/)** 🙏

---

### 🚨Copy and run the below commands in Cloud Shell:

# Set ZONE
```
export ZONE=
```

```
curl -LO raw.githubusercontent.com/CloudyGyn/CloudSkill/master/VPC%20Flow%20Logs%20-20%Analyzing%20Network%20Traffic/CloudyGyn212.sh
sudo chmod +x CloudyGyn212.sh
./CloudyGyn212.sh
```
### Sink Name: `vpc-flows`

```
CP_IP=$(gcloud compute instances describe web-server --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

export MY_SERVER=$CP_IP

for ((i=1;i<=50;i++)); do curl $MY_SERVER; done
```

## Congratulations, you're all done with the lab 😄

### 🌐 Join our Community

- <img src="https://github.com/user-attachments/assets/a4a4b767-151c-461d-bca1-da6d4c0cd68a" alt="icon" width="25" height="25"> **Join our [Telegram Channel](https://t.me/CloudyGyn)


---

# <img src="https://github.com/user-attachments/assets/6ee41001-c795-467c-8d96-06b56c246b9c" alt="icon" width="45" height="45"> [CloudyGyn](https://www.youtube.com/@CloudyGynOfficial) Don't Forget to like share & subscribe

### Thanks for watching and stay connected :)
---