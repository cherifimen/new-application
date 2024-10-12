
pipeline {
    environment {
        frontendImageName = "imenc531/front-service"
        frontendImageTag = "${BUILD_NUMBER}"
        backendImageName = "imenc531/back-service"
        backendImageTag = "${BUILD_NUMBER}"
    }
    agent any
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', changelog: false, credentialsId: 'github-token', poll: false, url: 'https://github.com/cherifimen/new-application/'
            }
        }
        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }
        stage('Test Unitaire Mocha') {
            steps {
                sh 'npm test'
            }
        }
        stage('SonarQube Code Analysis') {
            steps {
                sh '''
                    sonar-scanner \
                    -Dsonar.projectKey=backend \
                    -Dsonar.projectName=backend \
                    -Dsonar.projectVersion=1.0 \
                    -Dsonar.sources=. \
                    -Dsonar.exclusions=/node_modules/* \
                    -Dsonar.language=js \
                    -Dsonar.sourceEncoding=UTF-8 \
                    -Dsonar.host.url=http://192.168.184.3:9000/ \
                    -Dsonar.login=sqp_f40be3188ce3826f4f32227798d36f749755dabc
                '''
            }
        }
        stage('OWASP Dependency Check') {
            steps {
                script {
                    // OWASP Dependency Check
                    sh '/opt/dependency-check/bin/dependency-check.sh --project new-application --scan . --format XML --out dependency-check-report.xml'

                    // Publish Dependency-Check Results
                    dependencyCheckPublisher pattern: 'dependency-check-report.xml'
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'dependency-check-report.xml', allowEmptyArchive: true
                }
            }
        }
        stage('Lynis Security Scan') {
            steps {
                sh '''
                    sudo /usr/sbin/lynis audit system | ansi2html > ${WORKSPACE}/lynis.html
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'lynis.html', allowEmptyArchive: true
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                dir('client') {
                    script {
                        sh "docker build -t ${backendImageName}:${backendImageTag} ."
                        sh "docker build -t ${frontendImageName}:${frontendImageTag} ."
                    }
                }
            }
        }
        stage('Trivy Image Scan') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    script {
                        sh "trivy image ${backendImageName}:${backendImageTag} > trivy-backend-report.txt"
                        sh "trivy image ${frontendImageName}:${frontendImageTag} > trivy-frontend-report.txt"
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-backend-report.txt', allowEmptyArchive: true
                    archiveArtifacts artifacts: 'trivy-frontend-report.txt', allowEmptyArchive: true
                }
            }
        }
        stage('Login & Push to DockerHub') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'dockerhub-token2', variable: 'DOCKER_TOKEN')]) {
                        // Docker login using token
                        sh "echo ${DOCKER_TOKEN} | docker login -u imenc531 --password-stdin"
                        // Push images
                        sh '''
                        docker push ${backendImageName}:${backendImageTag}
                        docker push ${frontendImageName}:${frontendImageTag}
                        '''
                    }
                }
            }
        }
        stage('Remove Docker Image') {
            steps {
                sh "docker rmi ${backendImageName}:${backendImageTag}"
                sh "docker rmi ${frontendImageName}:${frontendImageTag}"
            }
        }
        stage('Deploying App to Kubernetes') {
            steps {
                script {
                  //kubernetesDeploy(configs: "mongodb-deployment.yaml", kubeconfigId: "kube-config")
                }
                script {
                   //sh "sed -i 's|__IMAGE_NAME__|${backendImageName}|g; s|__IMAGE_TAG__|${backendImageTag}|g' backend-deployment.yaml"
                   //kubernetesDeploy(configs: "backend-deployment.yaml", kubeconfigId: "kube-config")
                   sh "sed -i 's|__IMAGE_NAME__|${frontendImageName}|g; s|__IMAGE_TAG__|${frontendImageTag}|g' frontend-deployment.yaml"
                   kubernetesDeploy(configs: "frontend-deployment.yaml", kubeconfigId: "kube-config")
                }    
            }
        }
    }
    post {
        always {
            //this block will be executed regardless of the build result
            echo 'Pipeline completed'
        }
        success {
            //this block will be executed if the pipeline succeeds
            script {
                sendEmailNotification('success')
            }
        }
        failure {
        // this block will be executed if the pipeline faileds
            script {
                sendEmailNotification('failure')
            }
        }
    }  
}    
    
def sendEmailNotification(buildStatus) {
    emailext (
        subject: "Rapport d'exécution de la pipeline CI/CD",
        body: """${buildStatus}: job '${env.JOB_NAME} [${env.Build_NUMBER}]':
        Check console output  at ${env.BUILD_URL}""",
        to: 'imenc531@gmail.com',
        attachLog: true
    )
  }
 
