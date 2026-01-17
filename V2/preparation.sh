# На обоих серверах выполнить:
sudo apt update
sudo apt upgrade -y
sudo apt install -y docker.io docker-compose git curl wget nano
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER