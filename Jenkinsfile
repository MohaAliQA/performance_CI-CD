pipeline {
    agent any

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['PERFORMANCE', 'QA', 'UAT'],
            description: 'Select the environment for performance testing'
        )

        string(
            name: 'THREADS',
            defaultValue: '5',
            description: 'Number of JMeter threads/users'
        )

        string(
            name: 'RAMP_UP',
            defaultValue: '10',
            description: 'Ramp-up time in seconds'
        )
    }

    stages {

        stage('Checkout') {
            steps {
                echo '===== CHECKING OUT SOURCE CODE ====='
                echo "Environment: ${params.ENVIRONMENT}"
                echo "Threads: ${params.THREADS}"
                echo "Ramp-Up: ${params.RAMP_UP}"
            }
        }

        stage('Validate Parameters') {
            steps {
                script {
                    int threads = params.THREADS as Integer
                    int rampUp = params.RAMP_UP as Integer

                    if (threads <= 0) {
                        error "THREADS must be greater than zero. Received: ${threads}"
                    }

                    if (rampUp <= 0) {
                        error "RAMP_UP must be greater than zero. Received: ${rampUp}"
                    }

                    if (!(params.ENVIRONMENT in ['PERFORMANCE', 'QA', 'UAT'])) {
                        error "Invalid ENVIRONMENT: ${params.ENVIRONMENT}"
                    }

                    echo '===== PARAMETER VALIDATION PASSED ====='
                    echo "THREADS=${threads}"
                    echo "RAMP_UP=${rampUp}"
                    echo "ENVIRONMENT=${params.ENVIRONMENT}"
                }
            }
        }

        stage('Set Environment') {
            steps {
                script {
                    if (params.ENVIRONMENT == 'QA') {
                        env.BASE_HOST = 'qa-server'
                    } else if (params.ENVIRONMENT == 'UAT') {
                        env.BASE_HOST = 'uat-server'
                    } else {
                        env.BASE_HOST = 'localhost'
                    }

                    echo "ENVIRONMENT=${params.ENVIRONMENT}"
                    echo "BASE_HOST=${env.BASE_HOST}"
                }
            }
        }

        stage('Run JMeter') {
            steps {
                bat '''
                    echo ===== START JMETER TEST =====

                    echo THREADS=%THREADS%
                    echo RAMP_UP=%RAMP_UP%
                    echo BASE_HOST=%BASE_HOST%

                    call jmeter -n ^
                    -t "%WORKSPACE%\\JMeter\\PetClinic_Owner_Search_v2.jmx" ^
                    -JTHREADS=%THREADS% ^
                    -JRAMP_UP=%RAMP_UP% ^
                    -JBASE_HOST=%BASE_HOST% ^
                    -l "%WORKSPACE%\\jenkins_results.jtl"

                    if %ERRORLEVEL% NEQ 0 (
                        echo ===== JMETER TEST FAILED =====
                        exit /b %ERRORLEVEL%
                    )

                    echo ===== JMETER TEST COMPLETED SUCCESSFULLY =====
                '''
            }
        }
	
	stage('Generate HTML Report') {
    	    steps {
                bat '''
                    echo ===== GENERATING JMETER HTML REPORT =====

            	if exist "%WORKSPACE%\\HTMLReport" (
                rmdir /S /Q "%WORKSPACE%\\HTMLReport"
           	)

            	call jmeter -g "%WORKSPACE%\\jenkins_results.jtl" -o "%WORKSPACE%\\HTMLReport"

            	if %ERRORLEVEL% NEQ 0 (
                echo ===== HTML REPORT GENERATION FAILED =====
                exit /b %ERRORLEVEL%
            )

            echo ===== HTML REPORT GENERATION COMPLETED =====
        '''
    }
}

        stage('Test') {
            steps {
                echo '===== JENKINS PIPELINE TEST COMPLETED ====='
            }
        }
    }
}

post {
        always {
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'HTMLReport',
                reportFiles: 'index.html',
                reportName: 'JMeter Performance Report'
            ])
        }
    }