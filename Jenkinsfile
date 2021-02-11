pipeline {
  agent {
    label 'X86_64'
  }

  options {
    buildDiscarder(logRotator(numToKeepStr: '5', daysToKeepStr: '60'))
    parallelsAlwaysFailFast()
  }

  environment {
    TKF_USER = 'teknofile'
    TKF_REPO = 'gogs'
    DOCKERHUB_IMAGE = "${TKF_USER}" + "/" + "${TKF_REPO}"

    GITHUB_URL = 'https://github.com/${TKF_USER}/${TKF_REPO}.git'
  }

  stages {
    stage('Docker Build amd64') {
      steps {
        //git([url: 'https://github.com/teknofile/tkf-docker-openldap.git', branch: 'master', credentialsId: 'teknofile-github-user-token'])
        git([url: ${GITHUB_URL}, branch: 'main', credentialsId: 'teknofile-github-user-token'])
        script {
          withDockerRegistry(credentialsId: 'teknofile-dockerhub') {
            sh '''
              docker build --no-cache --pull -t ${DOCKERHUB_IMAGE}:amd64 .
              docker push ${DOCKERHUB_IMAGE}:amd64
              docker rmi ${DOCKERHUB_IMAGE}:amd64
            '''
          }
        }
      }
    }
    stage('Build aarch64') {
      agent {
        label 'aarch64'
      }
      steps {
        //git([url: 'https://github.com/teknofile/tkf-docker-openldap.git', branch: 'master', credentialsId: 'teknofile-github-user-token'])
        git([url: ${GITHUB_URL}, branch: 'main', credentialsId: 'teknofile-github-user-token'])
        script {
          withDockerRegistry(credentialsId: 'teknofile-dockerhub') {
            sh '''
              docker build --no-cache --pull -t ${DOCKERHUB_IMAGE}:aarch64 .
              docker push ${DOCKERHUB_IMAGE}:aarch64
              docker rmi ${DOCKERHUB_IMAGE}:aarch64
            '''
          }
        }
      }
    }
    stage('Create Manifest') {
      agent {
        label 'x86_64'
      }
      steps {
        script {
          withDockerRegistry(credentialsId: 'teknofile-dockerhub') {
            sh '''
              docker pull ${DOCKERHUB_IMAGE}:amd64
              docker pull ${DOCKERHUB_IMAGE}:aarch64

              docker manifest create ${DOCKERHUB_IMAGE} \
                ${DOCKERHUB_IMAGE}:amd64 \
                ${DOCKERHUB_IMAGE}:aarch64

              docker manifest inspect ${DOCKERHUB_IMAGE}
              docker manifest push ${DOCKERHUB_IMAGE}

              docker rmi ${DOCKERHUB_IMAGE}:aarch64
              docker rmi ${DOCKERHUB_IMAGE}:amd64
            '''
          }
        }
      }
    }
  }

  post {
    cleanup {
      cleanWs()
    }
  }
}
