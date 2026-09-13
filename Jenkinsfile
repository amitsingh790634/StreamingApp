pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '15'))
  }

  environment {
    DOCKERHUB_USER = 'amitsingh790634'
    IMAGE_TAG = "${env.BUILD_NUMBER}"
    RELEASE_TAG = '1.0.0'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build images') {
      parallel {
        stage('auth') {
          steps {
            sh 'docker build -t $DOCKERHUB_USER/streaming-auth:$RELEASE_TAG -t $DOCKERHUB_USER/streaming-auth:$IMAGE_TAG backend/authService'
          }
        }
        stage('streaming') {
          steps {
            sh 'docker build -t $DOCKERHUB_USER/streaming-stream:$RELEASE_TAG -t $DOCKERHUB_USER/streaming-stream:$IMAGE_TAG -f backend/streamingService/Dockerfile backend'
          }
        }
        stage('admin') {
          steps {
            sh 'docker build -t $DOCKERHUB_USER/streaming-admin:$RELEASE_TAG -t $DOCKERHUB_USER/streaming-admin:$IMAGE_TAG -f backend/adminService/Dockerfile backend'
          }
        }
        stage('chat') {
          steps {
            sh 'docker build -t $DOCKERHUB_USER/streaming-chat:$RELEASE_TAG -t $DOCKERHUB_USER/streaming-chat:$IMAGE_TAG -f backend/chatService/Dockerfile backend'
          }
        }
        stage('frontend') {
          steps {
            sh '''
              docker build \
                --build-arg REACT_APP_AUTH_API_URL=http://streamingapp.local/api \
                --build-arg REACT_APP_STREAMING_API_URL=http://streamingapp.local/api \
                --build-arg REACT_APP_STREAMING_PUBLIC_URL=http://streamingapp.local \
                --build-arg REACT_APP_ADMIN_API_URL=http://streamingapp.local/api/admin \
                --build-arg REACT_APP_CHAT_API_URL=http://streamingapp.local/api/chat \
                --build-arg REACT_APP_CHAT_SOCKET_URL=http://streamingapp.local \
                -t $DOCKERHUB_USER/streaming-frontend:$RELEASE_TAG \
                -t $DOCKERHUB_USER/streaming-frontend:$IMAGE_TAG \
                frontend
            '''
          }
        }
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          sh '''
            echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
            for svc in auth stream admin chat frontend; do
              docker push $DOCKERHUB_USER/streaming-$svc:$RELEASE_TAG
              docker push $DOCKERHUB_USER/streaming-$svc:$IMAGE_TAG
            done
          '''
        }
      }
    }
  }

  post {
    success {
      echo "Images pushed: $DOCKERHUB_USER/streaming-*:$RELEASE_TAG"
      sh '''
        if [ -n "${SNS_TOPIC_ARN:-}" ] && command -v aws >/dev/null 2>&1; then
          aws sns publish --topic-arn "$SNS_TOPIC_ARN" --subject "StreamingApp CI success" --message "Build ${BUILD_NUMBER} pushed ${RELEASE_TAG}"
        fi
      '''
    }
    failure {
      echo "Pipeline failed — see console output."
      sh '''
        if [ -n "${SNS_TOPIC_ARN:-}" ] && command -v aws >/dev/null 2>&1; then
          aws sns publish --topic-arn "$SNS_TOPIC_ARN" --subject "StreamingApp CI failure" --message "Build ${BUILD_NUMBER} failed. ${BUILD_URL}"
        fi
      '''
    }
  }
}
