pipeline{
    agent any
    stages{
        stage("Fetch code from git"){
            steps{
                git branch: 'paac', url: 'https://github.com/worachai3/vprofile-project.git'
            }
        }

        stage("Build"){
            steps{
                sh "mvn install"
            }
        }

        stage("Test"){
            steps{
                sh "mvn test"
            }
        }
    }
}