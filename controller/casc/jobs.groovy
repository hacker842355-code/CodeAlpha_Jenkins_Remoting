// Seed job created through Job DSL. Mirrors ../../Jenkinsfile (the Jenkinsfile is the source of truth
// when you create a "Pipeline script from SCM" job from your GitHub repo).
pipelineJob('remoting-demo') {
  description('Runs the same build on every architecture through Jenkins Remoting agents')
  definition {
    cps {
      sandbox(true)
      script('''
pipeline {
  agent none
  options { timestamps() }
  stages {
    stage('Run on all architectures') {
      parallel {
        stage('amd64') {
          agent { label 'amd64' }
          steps { sh 'echo "node=$NODE_NAME arch=$(uname -m) user=$(whoami)"; java -version' }
        }
        stage('arm64') {
          agent { label 'arm64' }
          steps { sh 'echo "node=$NODE_NAME arch=$(uname -m) user=$(whoami)"; java -version' }
        }
      }
    }
  }
}
''')
    }
  }
}
