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

	stage('Clean Previous Results') {
            steps {
                bat '''
            	echo ===== CLEANING PREVIOUS TEST RESULTS =====

            	if exist "%WORKSPACE%\\jenkins_results.jtl" (
                del /F /Q "%WORKSPACE%\\jenkins_results.jtl"
            	)

            	if exist "%WORKSPACE%\\HTMLReport" (
                rmdir /S /Q "%WORKSPACE%\\HTMLReport"
            	)

           	echo ===== OLD RESULTS CLEANED =====
        	'''
    	    }
	}

        stage('Run JMeter Test') {
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
	
	stage('Validate Error Rate') {
    	    steps {
       		script {
            	echo '===== VALIDATING JMETER ERROR RATE ====='

            	def result = bat(
                script: '''
                    powershell -NoProfile -Command ^
                    "$data = Import-Csv '%WORKSPACE%\\jenkins_results.jtl'; ^
                    $total = $data.Count; ^
                    $failed = @($data | Where-Object { $_.success -eq 'false' }).Count; ^
                    $errorRate = if ($total -gt 0) { ($failed * 100.0) / $total } else { 0 }; ^
                    Write-Host ('TOTAL_SAMPLES=' + $total); ^
                    Write-Host ('FAILED_SAMPLES=' + $failed); ^
                    Write-Host ('ERROR_RATE=' + [math]::Round($errorRate,2))"
                ''',
                returnStdout: true
            	).trim()

            	echo result

            	def totalMatch = result =~ /TOTAL_SAMPLES=(\d+)/
            	def failedMatch = result =~ /FAILED_SAMPLES=(\d+)/
            	def errorMatch = result =~ /ERROR_RATE=([\d.]+)/

            	int totalSamples = totalMatch[0][1] as Integer
            	int failedSamples = failedMatch[0][1] as Integer
            	double errorRate = errorMatch[0][1] as Double

            	double maximumErrorRate = 1.0

            	echo "Total Samples = ${totalSamples}"
            	echo "Failed Samples = ${failedSamples}"
            	echo "Error Rate = ${errorRate}%"
            	echo "Maximum Allowed Error Rate = ${maximumErrorRate}%"

            	if (errorRate > maximumErrorRate) {
                error(
                    "PERFORMANCE TEST FAILED: Error Rate ${errorRate}% exceeds allowed ${maximumErrorRate}%"
                )
            	}

            	echo '===== ERROR RATE VALIDATION PASSED ====='
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
}