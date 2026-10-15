pipeline {
    agent any
    environment {
       AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID') 
       AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
       AWS_DEFAULT_REGION = 'ap-south-1'
    }
    stages{
        stage('Checkout SCM'){
            steps{
                script{
                    checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/priyankadalgade-dot/terraform-jenkins-eks.git']])
                }
            }
        }
        stage('Initializing Terraform'){
            steps{
                script{
                    dir('EKS'){
                        sh 'terraform init'
                    }
                }
            }
        }
        stage('Formating terraform code'){
            steps{
                script{
                    dir('EKS'){
                        sh 'terraform fmt -recursive'
                    }
                }
            }
        }
        stage('Validating terraform'){
            steps{
                script{
                    dir('EKS'){
                        sh 'terraform validate'
                    }
                }
            }
        }
        stage('Previewing the infrastructure'){
            steps{
                script{
                    dir('EKS'){
                        if (params.action == 'destroy') {
                            sh 'terraform plan -destroy -out=tfplan'
                        } else {
                            sh 'terraform plan -out=tfplan'
                        }
                    }
                    input(
                         message: "Review the plan. Proceed with ${params.action}?",
                         ok: 'Proceed'
                         )
                }
            }
        }
        stage('Creating/Destroying an EKS cluster'){
            steps{
                script{
                    dir('EKS'){
                         sh 'terraform $action --auto-approve'
                    }
                }
            }
        }
        stage('Deploying Nginx') {
            steps {
                script {
                    dir('EKS/configuration-files') {
                         sh '''
                    set -e

                    echo "=== Checking AWS identity ==="
                    aws sts get-caller-identity

                    echo "=== Configuring EKS access ==="
                    aws eks update-kubeconfig \
                      --region ap-south-1 \
                      --name my-eks-cluster

                    echo "=== Checking Kubernetes access ==="
                    kubectl get nodes
                    kubectl auth can-i create deployments

                    echo "=== Deploying NGINX ==="
                    kubectl apply -f deployment.yml
                    kubectl apply -f service.yml

                    echo "=== Waiting for deployment ==="
                    kubectl rollout status deployment/my-nginx \
                      --timeout=180s

                    echo "=== Deployment results ==="
                    kubectl get deployments,pods,services
                '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Review the first error in the console output.'
        }
    }
}
