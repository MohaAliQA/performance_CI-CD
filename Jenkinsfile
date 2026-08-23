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

        string(
            name: 'MAX_ERROR_RATE',
            defaultValue: '1',
            description: 'Maximum allowed error rate in percentage'
        )

        string(
            name: 'MAX_95TH_PERCENTILE',
            defaultValue: '2000',
            description: 'Maximum allowed 95th percentile response time in miliseconds'
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
		    double maxErrorRate = params.MAX_ERROR_RATE as Double
		    int max95thPercentile = params.MAX_95TH_PERCENTILE as Integer

                    if (threads <= 0) {
                        error "THREADS must be greater than zero. Received: ${threads}"
                    }

                    if (rampUp <= 0) {
                        error "RAMP_UP must be greater than zero. Received: ${rampUp}"
                    }

                    if (!(params.ENVIRONMENT in ['PERFORMANCE', 'QA', 'UAT'])) {
                        error "Invalid ENVIRONMENT: ${params.ENVIRONMENT}"
                    }

		    if (maxErrorRate < 0) {
			error "MAX_ERROR_RATE cannot be negative. Received: ${maxErrorRate}"
		    }

		    if (max95thPercentile <= 0) {
			error "MAX_95TH_PERCENTILE must be greater than zero. Received: ${max95thPercentile}"
		    }

                    echo '===== PARAMETER VALIDATION PASSED ====='
                    echo "THREADS=${threads}"
                    echo "RAMP_UP=${rampUp}"
                    echo "ENVIRONMENT=${params.ENVIRONMENT}"
                    echo "MAX_ERROR_RATE=${maxErrorRate}"
                    echo "MAX_95TH_PERCENTILE=${max95thPercentile} ms"
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

        stage('Validate JMeter SLA') {
            steps {
                bat '''
                    echo ===== VALIDATING JMETER SLA =====

                    powershell -ExecutionPolicy Bypass -File "%WORKSPACE%\\JMeter\\Validate-JMeterSLA.ps1" ^
                    -JtlFile "%WORKSPACE%\\jenkins_results.jtl" ^
                    -MaximumErrorRate 1 ^
                    -Maximum95thPercentile 2000

                    if %ERRORLEVEL% NEQ 0 (
                        echo ===== JMETER SLA VALIDATION FAILED =====
                        exit /b %ERRORLEVEL%
                    )

                    echo ===== JMETER SLA VALIDATION PASSED =====
                '''
            }
        }

        stage('Save Performance History') {
            steps {
                bat '''
                    echo ===== SAVING PERFORMANCE HISTORY =====

                    powershell -NoProfile -ExecutionPolicy Bypass -File "%WORKSPACE%\\JMeter\\Save-PerformanceHistory.ps1" ^
                    -JtlFile "%WORKSPACE%\\jenkins_results.jtl" ^
                    -HistoryFile "%WORKSPACE%\\performance-history.csv" ^
                    -BuildNumber "%BUILD_NUMBER%" ^
                    -Environment "%ENVIRONMENT%" ^
                    -Threads "%THREADS%" ^
                    -RampUp "%RAMP_UP%"

                    if %ERRORLEVEL% NEQ 0 (
                        echo ===== PERFORMANCE HISTORY FAILED =====
                        exit /b %ERRORLEVEL%
                    )

                    echo ===== PERFORMANCE HISTORY COMPLETED =====
                '''
            }
        }

        stage('Validate Performance Regression') {
            steps {
                bat '''
                    echo ===== VALIDATING PERFORMANCE REGRESSION =====

                    powershell -NoProfile -ExecutionPolicy Bypass -File "%WORKSPACE%\\JMeter\\Validate-PerformanceRegression.ps1" ^
                    -HistoryFile "%WORKSPACE%\\performance-history.csv" ^
                    -CurrentBuildNumber %BUILD_NUMBER% ^
                    -AllowedDegradationPercent 20

                    if %ERRORLEVEL% NEQ 0 (
                        echo ===== PERFORMANCE REGRESSION DETECTED =====
                        exit /b %ERRORLEVEL%
                    )

                    echo ===== PERFORMANCE REGRESSION VALIDATION PASSED =====
                '''
            }
        }

        stage('Generate Performance Trend') {
            steps {
                bat '''
                    echo ===== GENERATING PERFORMANCE TREND REPORT =====

                    if exist "%WORKSPACE%\\PerformanceTrend" (
                       rmdir /S /Q "%WORKSPACE%\\PerformanceTrend"
                    )

                    mkdir "%WORKSPACE%\\PerformanceTrend"

                    powershell -NoProfile -ExecutionPolicy Bypass -File "%WORKSPACE%\\JMeter\\Generate-PerformanceTrend.ps1" ^
                    -HistoryFile "%WORKSPACE%\\performance-history.csv" ^
                    -OutputFile "%WORKSPACE%\\PerformanceTrend\\index.html"

                    if %ERRORLEVEL% NEQ 0 (
                        echo ===== PERFORMANCE TREND REPORT FAILED =====
                        exit /b %ERRORLEVEL%
                    )

                    echo ===== PERFORMANCE TREND REPORT COMPLETED =====
                '''
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

            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'PerformanceTrend',
                reportFiles: 'index.html',
                reportName: 'Performance Trend Report'
            ])

        }
    }
}