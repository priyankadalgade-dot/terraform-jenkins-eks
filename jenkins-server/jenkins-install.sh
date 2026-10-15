
#!/bin/bash
set -Eeuo pipefail

# Log all output for troubleshooting
exec > >(tee -a /var/log/jenkins-install.log) 2>&1
trap 'rc=$?; echo "ERROR: Installation failed near line ${LINENO} (exit ${rc}). Check /var/log/jenkins-install.log"; exit "$rc"' ERR

export DEBIAN_FRONTEND=noninteractive

echo "===== Starting Jenkins server installation ====="

# Ensure the script runs as root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Run this script as root."
    exit 1
fi

# Install prerequisites
apt-get update
apt-get install -y \
    ca-certificates \
    curl \
    wget \
    gnupg \
    fontconfig \
    openjdk-21-jre \
    unzip

java -version

# Install Jenkins LTS
install -d -m 0755 /etc/apt/keyrings

curl -fsSL \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
    -o /etc/apt/keyrings/jenkins-keyring.asc

chmod 0644 /etc/apt/keyrings/jenkins-keyring.asc

printf '%s\n' \
    "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
    > /etc/apt/sources.list.d/jenkins.list

apt-get update
apt-get install -y jenkins

# Install Terraform from HashiCorp's official repository
wget -O- https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor --yes \
        -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

chmod 0644 /usr/share/keyrings/hashicorp-archive-keyring.gpg

. /etc/os-release

printf '%s\n' \
    "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${VERSION_CODENAME} main" \
    > /etc/apt/sources.list.d/hashicorp.list

apt-get update
apt-get install -y terraform

# Determine CPU architecture for kubectl and AWS CLI
ARCH="$(dpkg --print-architecture)"

case "$ARCH" in
    amd64)
        K8S_ARCH="amd64"
        AWS_ARCH="x86_64"
        ;;
    arm64)
        K8S_ARCH="arm64"
        AWS_ARCH="aarch64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Install kubectl
K8S_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
echo "Installing kubectl ${K8S_VERSION}"

curl -fsSL \
    "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/${K8S_ARCH}/kubectl" \
    -o /tmp/kubectl

curl -fsSL \
    "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/${K8S_ARCH}/kubectl.sha256" \
    -o /tmp/kubectl.sha256

echo "$(cat /tmp/kubectl.sha256)  /tmp/kubectl" | sha256sum --check

install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
rm -f /tmp/kubectl /tmp/kubectl.sha256

# Install AWS CLI v2
curl -fsSL \
    "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" \
    -o /tmp/awscliv2.zip

rm -rf /tmp/aws
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update

rm -rf /tmp/aws /tmp/awscliv2.zip

# Enable Jenkins
systemctl enable jenkins
systemctl restart jenkins

echo "===== Verifying installed tools ====="
java -version
terraform version
kubectl version --client
aws --version
systemctl --no-pager --full status jenkins

echo "===== Jenkins server installation completed ====="
