pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code from github...'
            }
        }

        stage('Run JMeter') {
            steps {
                bat '''
                    echo ===== START JMETER TEST =====

                    call jmeter -n ^
                    -t "%WORKSPACE%\\JMeter\\PetClinic_Owner_Search_v2.jmx" ^
                    -JTHREADS=5 ^
                    -JRAMP_UP=10 ^
                    -JBASE_HOST=localhost ^
                    -l "%WORKSPACE%\\jenkins_results.jtl"

                    if %ERRORLEVEL% NEQ 0 (
                        echo ===== JMETER TEST FAILED =====
                        exit /b %ERRORLEVEL%
                    )

                    echo ===== JMETER TEST COMPLETED =====
                '''
            }
        }

        stage('Test') {
            steps {
                echo 'Jenkins Pipeline is working successfully!'
            }
        }
    }
}.
