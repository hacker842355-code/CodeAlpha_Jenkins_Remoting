// Runs the same work on each architecture through Jenkins Remoting agents.
pipeline {
  agent none
  options { timestamps(); timeout(time: 10, unit: 'MINUTES') }
  stages {
    stage('Run on all architectures') {
      parallel {
        stage('amd64') {
          agent { label 'amd64' }
          steps {
            sh 'echo "node=$NODE_NAME arch=$(uname -m) user=$(whoami)" | tee arch-amd64.txt'
            sh 'java -version'
            archiveArtifacts artifacts: 'arch-amd64.txt'
          }
        }
        stage('arm64') {
          agent { label 'arm64' }
          steps {
            sh 'echo "node=$NODE_NAME arch=$(uname -m) user=$(whoami)" | tee arch-arm64.txt'
            sh 'java -version'
            archiveArtifacts artifacts: 'arch-arm64.txt'
          }
        }
      }
    }
  }
}
