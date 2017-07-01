@echo off


SETLOCAL 

set JAVA_HOME=C:\Program Files\Java\jdk1.8.0_102

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
set job=%2
set step=%3

if "%1" == "IN" (
	set GatewaySource=gateway_prod_internal_01.properties
	set GatewayTarget=gateway_prod_external_01.properties
	set PREFIX=I2E
) else if "%1" == "EX" (
	set GatewaySource=gateway_prod_external_01.properties
	set GatewayTarget=gateway_prod_internal_01.properties
	set PREFIX=E2I
) else (
	goto :HELP
)


:: [Folder based Export]
set Today=%date%
set DefaultDIR=%Today%\P2P_%PREFIX%

:: TARGET BACKUP
set TargetBackup=%DefaultDIR%\TARGET_backup
set TargetFolderRestore=%DefaultDIR%\TARGET_folder
set TargetFolderRestoreWork=%DefaultDIR%\TARGET_folder_work
set TargetFolderDisable=%DefaultDIR%\TARGET_folder_disable
set TargetFolderName=@SKT-MAG

:: SOURCE ALL
set TargetALL=SOURCE_all
set LocalMigFolder=%DefaultDIR%\%TargetALL%
set LocalMigWorkFolder=%LocalMigFolder%_Work

:: SOURCE @SKT-MAG FOLDER
set TargetFolder=SOURCE_folder
set LocalMigFolderOnly=%DefaultDIR%\%TargetFolder%
set LocalMigWorkFolderOnly=%LocalMigFolderOnly%_Work
set SourceFolderName=@SKT-MAG



::cls
echo --------------------------------------------------------------------------
echo Date : %Today% (백업본을 사용하려면 수정해야함)
echo Base DIR : %DefaultDIR%
echo source gateway : %GatewaySource% , source folder : %SourceFolderName%
echo target gateway : %GatewayTarget% , target folder : %TargetFolderName%
echo job : %job%, step : %step%
echo --------------------------------------------------------------------------
if "%1" == "?" (
	goto :HELP
) else (
	if /i "%job%" == "Export" goto :EXPORT
	if /i "%job%" == "Migrate" goto :MIGRATE
	if /i "%job%" == "Disable" goto :DISABLE else :HELP
)


rem *************** start of procedure HELP
:HELP
echo Usage
echo    "%0 [IN|EX] [Export|Migrate|Disable] { 1 | 2 | 3 ..} "
echo Parameters:
echo    IN                to Migrate Internal to External
echo    EX                to Migrate External to Internal
echo    Export
echo    	Export  1     to Backup(MigrateOut) Target Gateway - All
echo    	Export  2     to Backup(MigrateOut) Target Gateway - only specific folder for disabling services
echo    	Export  3     to Export(MigrateOut) Source Gateway - All
echo    	Export  4     to Export(MigrateOut) Source Gateway - only specific folder 
echo    Migrate
echo    	Migrate 1     to manage mappings of entities(특정 Service/Policy) in FOLDER exports
echo    	Migrate 21    to manage mappings of CLUSTER_PROPERTY in ALL exports
echo    	Migrate run   to import(MigrateIn) FOLDER to the Target Gateway
echo    	Migrate run2   to import(MigrateIn) CLUSTER_PROPERTY to the Target Gateway
echo    Disable
echo    	Disable 1     to manage mappings of target entities for disable services
echo    	Disable 2     to manage mappings of target entities for enable services
echo    	Disable 3     to run migratein for Disable services
echo    	Disable 4     to run migratein for Enable services
goto :EOF
rem *************** end of procedure HELP

:EXPORT
:: EXPORT 1. Backup TARGET
if "%step%" == "1" (
	echo INFO: will remove existing directories : 
	call :REMOVEDIR .\%TargetBackup%
	echo INFO: migrateOut -z %GatewayTarget% --dest %TargetBackup% --format=directory --all --defaultAction NewOrUpdate
    call GatewayMigrationUtility.bat migrateOut -z %GatewayTarget% --dest %TargetBackup% --format=directory --all --defaultAction NewOrUpdate
    echo INFO: EXPORT 1. Backup TARGET.. done
	exit /b 1
)
:: EXPORT 2. Backup TARGET to disable and restore services
if "%step%" == "2" (
	echo INFO: will remove existing directories : 
	call :REMOVEDIR .\%TargetFolderRestore% 
	call :REMOVEDIR .\%TargetFolderRestoreWork%
	call :REMOVEDIR .\%TargetFolderDisable%
	
	echo INFO: migrateOut -z %GatewayTarget% --dest %TargetFolderRestore% --folderName "/%TargetFolderName%" --format=directory --defaultAction NewOrExisting
	call GatewayMigrationUtility.bat migrateOut -z %GatewayTarget% --dest %TargetFolderRestore% --folderName "/%TargetFolderName%" --format=directory --defaultAction NewOrExisting
	xcopy %TargetFolderRestore% %TargetFolderRestoreWork% /s /e /y /i
	xcopy %TargetFolderRestore% %TargetFolderDisable% /s /e /y /i
	
	call GatewayMigrationUtility.bat template --bundle %TargetFolderDisable% --template %TargetFolderDisable%/TARGET-templatized.properties
	copy /Y .\%TargetFolderDisable%\TARGET-templatized.properties .\%TargetFolderDisable%\TARGET-templatized-backup.properties
    echo INFO: EXPORT 2. Backup TARGET.. done
	exit /b 1
)

:: EXPORT 3. MigrateOut SOURCE ALL 
if "%step%" == "3" (
	echo INFO: will remove existing directories : 
    ::rmdir /s /q .\%LocalMigFolder% .\%LocalMigWorkFolder%
	call :REMOVEDIR .\%LocalMigFolder% 
	call :REMOVEDIR .\%LocalMigWorkFolder%
	
	echo INFO: migrateOut -z %GatewaySource% --dest %LocalMigFolder% --format=directory --all --defaultAction NewOrExisting
    call GatewayMigrationUtility.bat migrateOut -z %GatewaySource% --dest %LocalMigFolder% --format=directory --all --defaultAction NewOrExisting
    
    xcopy %LocalMigFolder% %LocalMigWorkFolder% /s /e /y /i
    echo INFO: EXPORT 3. MigrateOut SOURCE ALL.. done
	exit /b 1
)

:: EXPORT 4. MigrateOut SOURCE FOLDER(@SKT-MAG) ONLY
if "%step%" == "4" (
    ::rmdir /s /q .\%LocalMigFolderOnly% .\%LocalMigWorkFolderOnly%
	echo INFO: will remove existing directories : 
	call :REMOVEDIR .\%LocalMigFolderOnly% 
	call :REMOVEDIR .\%LocalMigWorkFolderOnly%

	echo INFO: migrateOut -z %GatewaySource% --dest %LocalMigFolderOnly% --folderName "/%SourceFolderName%" --format=directory --defaultAction NewOrUpdate
    call GatewayMigrationUtility.bat migrateOut -z %GatewaySource% --dest %LocalMigFolderOnly% --folderName "/%SourceFolderName%" --format=directory --defaultAction NewOrUpdate
    
    xcopy %LocalMigFolderOnly% %LocalMigWorkFolderOnly% /s /e /y /i
 
	echo EXPORT 4. MigrateOut SOURCE FOLDER [%SourceFolderName%] done
	exit /b 1
)

:: 5. MigrateOut SOURCE services ONLY (Service  또는 Policy 단위로 export 할때 사용)
if "%step%" == "5" (
	echo INFO: will remove existing directories : 
	call :REMOVEDIR .\%LocalMigFolderOnly% 
	call :REMOVEDIR .\%LocalMigWorkFolderOnly%

	echo INFO: migrateOut -z %GatewaySource% --dest %LocalMigFolderOnly% --serviceName "/@SKT-MAG/15.install.do" --format=directory --defaultAction NewOrUpdate
    call GatewayMigrationUtility.bat migrateOut -z %GatewaySource% --dest %LocalMigFolderOnly% --serviceName "/@SKT-MAG/15.install.do" --format=directory --defaultAction NewOrUpdate

    xcopy %LocalMigFolderOnly% %LocalMigWorkFolderOnly% /s /e /y /i

	echo EXPORT 5. MigrateOut SOURCE Servie/Policy Only done.
	exit /b 1
)


goto :HELP


:MIGRATE
:: MIGRATE 1. manageMappings FOLDER ONLY
:: 우선 targetName 을 다르게 하여 PRD service 용으로만 사용하도록 한다.
if "%step%" == "1" (
    copy /Y %LocalMigFolderOnly%\mappings.xml %LocalMigWorkFolderOnly%\

	:: -- Existing -----------------
	call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type CLUSTER_PROPERTY --action Ignore
	call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SSG_KEY_ENTRY --action Ignore
	call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type JDBC_CONNECTION --srcName MAG --targetName MAG --action Ignore

	:: [SITEMINDER_CONFIGURATION] - You might need to set the configuration for Cluster(SSO) IP
	call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SITEMINDER_CONFIGURATION --srcName "CA_SSO" --targetName "CA_SSO" --action NewOrExisting
	call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SITEMINDER_CONFIGURATION --srcName "CA_SSO_SVC" --targetName "CA_SSO_SVC" --action NewOrExisting
	call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SECURE_PASSWORD --srcName siteminder --targetName siteminder --action NewOrExisting

	:: [ENCAPSULATED_ASSERTION]
	call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type ENCAPSULATED_ASSERTION --srcName "GenesisTech_RoutingPolicy" --targetName "GenesisTech_RoutingPolicy" --action NewOrExisting
	call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type ENCAPSULATED_ASSERTION --srcName "GenesisTech_ServerSetting" --targetName "GenesisTech_ServerSetting" --action NewOrExisting
	call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type ENCAPSULATED_ASSERTION --srcName "GenesisTech_OTPSession" --targetName "GenesisTech_OTPSession" --action NewOrExisting

	:: [POLICY]
    call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type POLICY --srcName ServerSetting --targetName ServerSetting --action NewOrExisting
    call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type POLICY --srcName OTPSession --targetName OTPSession --action NewOrExisting
    call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type POLICY --srcName RoutingPolicy --targetName RoutingPolicy --action NewOrExisting

	:: [FOLDER]
	call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type FOLDER --srcName "@SKT-MAG" --targetName "@SKT-MAG" --action NewOrExisting

	@REM -- Service ---------
	:: Mapping Service
	call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SERVICE --action Ignore
	::call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SERVICE --srcName "01.Authcheck" --targetName "01.Authcheck" --action Update
	call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SERVICE --srcName "02.Login" --targetName "02.Login" --action Update
	::call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SERVICE --srcName "03.RealOTPLogin" --targetName "03.RealOTPLogin" --action Update
	::call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SERVICE --srcName "04.ReLogin" --targetName "04.ReLogin" --action Update
	::call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SERVICE --srcName "05.RealSMSOrEmailSend" --targetName "05.RealSMSOrEmailSend" --action Update
	::call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SERVICE --srcName "06.RealLogOut" --targetName "06.RealLogOut" --action Update
	::call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SERVICE --srcName "07.RealAuthorize" --targetName "07.RealAuthorize" --action Update
	::call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SERVICE --srcName "08.RealGetConfig" --targetName "08.RealGetConfig" --action Update
	::call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SERVICE --srcName "09.contigencyConfig" --targetName "09.contigencyConfig" --action Update
	::call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SERVICE --srcName "10.HealthCheck" --targetName "10.HealthCheck" --action Update
	::call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SERVICE --srcName "11.Favicon" --targetName "11.Favicon" --action Update
	::call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SERVICE --srcName "12.ServerTime" --targetName "12.ServerTime" --action Update
	::call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SERVICE --srcName "14.Sessioncheck" --targetName "14.Sessioncheck" --action Update
	::call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SERVICE --srcName "15.install.do" --targetName "15.install.do" --action Update
	::call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigWorkFolderOnly% --type SERVICE --srcName "index" --targetName "index" --action Update
	echo INFO: manageMappings done..
	:: Migrate Test
	echo INFO: Start MigrateIn Test..
    call GatewayMigrationUtility.bat migrateIn -z %GatewayTarget% --bundle %LocalMigWorkFolderOnly% --results %DefaultDIR%\ResultTest_%Today%_FolderOnlyWork.xml --test
	echo INFO: MIGRATE 1. manageMappings FOLDER %SourceFolderName%.. done. 
	echo INFO: Please check %DefaultDIR%\ResultTest_%Today%_FolderOnlyWork.xml
	exit /b 1
)

:: Dependency 가 없는 entity는 전체 All exported [EXPORT 3] 로부터 작업
:: CLUSTER_PROPERTY, SSG_CONNECTOR 외에 추가할 entity 가 있을 경우 작업 추가해야함
:: 21. manageMappings global entities
:: CLUSTER_PROPERTY
if "%step%" == "21" (
    del %LocalMigWorkFolder%\mappings.xml
    call GatewayMigrationUtility.bat manageMappings --bundle %LocalMigFolder% --type CLUSTER_PROPERTY --outputFile %LocalMigWorkFolder%\mappings.xml --action NewOrExisting
	echo INFO: manageMappings done..
	copy /Y %LocalMigWorkFolder%\mappings.xml %LocalMigWorkFolder%\mappings_CLUSTER_PROPERTY.xml

	:: Migrate Test
	echo INFO: Start MigrateIn Test..
	call GatewayMigrationUtility.bat migrateIn -z %GatewayTarget% --bundle %LocalMigWorkFolder% --results %DefaultDIR%\ResultTest_%Today%_FolderWork_CLUSTER_PROPERTY.xml --test
	echo INFO: MIGRATE 21. manageMappings CLUSTER_PROPERTY done. 
	echo INFO: Please check %DefaultDIR%\ResultTest_%Today%_FolderWork_CLUSTER_PROPERTY.xml

	exit /b 1
)


:: 6. migrateIn FOLDER ONLY
if "%step%" == "run" (
	echo WARN: now magrateIn to %GatewayTarget%
	echo INFO: migrateIn -z %GatewayTarget% --bundle %LocalMigWorkFolderOnly% --results %DefaultDIR%\Result_%Today%_FolderOnlyWork.xml --comment "GMU Migration : %PREFIX%"
	PAUSE
    call GatewayMigrationUtility.bat migrateIn -z %GatewayTarget% --bundle %LocalMigWorkFolderOnly% --results %DefaultDIR%\Result_%Today%_FolderOnlyWork.xml --comment "GMU Migration : %PREFIX%"
    exit /b 1
)

:: 6. migrateIn CLUSTER_PROPERTY ONLY
if "%step%" == "run2" (
	if exist %LocalMigWorkFolder%\mappings_CLUSTER_PROPERTY.xml (
		copy /Y %LocalMigWorkFolder%\mappings_CLUSTER_PROPERTY.xml %LocalMigWorkFolder%\mappings.xml
	) else (
		echo "%LocalMigWorkFolder%\mappings_CLUSTER_PROPERTY.xml" is not exist.
		goto :HELP
	)
	call GatewayMigrationUtility.bat migrateIn -z %GatewayTarget% --bundle %LocalMigWorkFolder% --results %DefaultDIR%\Result_%Today%_FolderWork_CLUSTER_PROPERTY.xml
    
	exit /b 1
)


goto :HELP


:DISABLE
:: MUST Edit file "TARGET-templatized.properties"
:: replace ".ServiceDetail.Enabled=true" ==> ".ServiceDetail.Enabled=false"
:: disable된 서비스를 다시 enable 시키고자 할 경우, 프로퍼티를 원상복구 해주면 됨
if "%step%" == "1" (
	ECHO 
	ECHO WARN: PLEASE be sure that "TARGET-templatized.properties" is modified with ".ServiceDetail.Enabled=false"
	ECHO 
	PAUSE
    copy /Y %TargetFolderRestore%\mappings.xml %TargetFolderDisable%\
	call GatewayMigrationUtility.bat manageMappings --bundle %TargetFolderDisable% --type FOLDER --action NewOrExisting
	call GatewayMigrationUtility.bat manageMappings --bundle %TargetFolderDisable% --type SSG_KEY_ENTRY --action Existing
	call GatewayMigrationUtility.bat manageMappings --bundle %TargetFolderDisable% --type JDBC_CONNECTION --action Existing
	call GatewayMigrationUtility.bat manageMappings --bundle %TargetFolderDisable% --type SITEMINDER_CONFIGURATION --action Existing
	call GatewayMigrationUtility.bat manageMappings --bundle %TargetFolderDisable% --type SECURE_PASSWORD --action Existing
	call GatewayMigrationUtility.bat manageMappings --bundle %TargetFolderDisable% --type ENCAPSULATED_ASSERTION --action Existing
    ::call GatewayMigrationUtility.bat manageMappings --bundle %TargetFolderDisable% --type POLICY --action Existing
	:: 개발서버에 맵핑오류인 POLICY
	call GatewayMigrationUtility.bat manageMappings --bundle %TargetFolderDisable% --type POLICY --srcId 542cf8b2-4d67-4a61-bdd7-3e1c748fdc6e --action Ignore
	:: Update only services
	call GatewayMigrationUtility.bat manageMappings --bundle %TargetFolderDisable% --type SERVICE --action NewUpdate
	
	echo INFO: migrateIn -z %GatewayTarget% --bundle %TargetFolderDisable% --results %DefaultDIR%\ResultTest_%Today%_DisableWork.xml --template %TargetFolderDisable%/TARGET-templatized.properties --test
    call GatewayMigrationUtility.bat migrateIn -z %GatewayTarget% --bundle %TargetFolderDisable% --results %DefaultDIR%\ResultTest_%Today%_DisableWork.xml --template %TargetFolderDisable%/TARGET-templatized.properties --test

	exit /b 1
)

:: disable 시킨 서비스를 enable 시킴
:: 백업해 놓은 원래 templatized file (TARGET-templatized-backup.properties) 을 사용해 원상복구를 한다.
if "%step%" == "2" (
	ECHO WARN: PLEASE be sure that "TARGET-templatized-backup.properties" is modified with ".ServiceDetail.Enabled=true"
	PAUSE
    copy /Y %TargetFolderRestore%\mappings.xml %TargetFolderDisable%\
	call GatewayMigrationUtility.bat manageMappings --bundle %TargetFolderDisable% --type FOLDER --action Existing
	call GatewayMigrationUtility.bat manageMappings --bundle %TargetFolderDisable% --type SSG_KEY_ENTRY --action Existing
	call GatewayMigrationUtility.bat manageMappings --bundle %TargetFolderDisable% --type JDBC_CONNECTION --action Existing
	call GatewayMigrationUtility.bat manageMappings --bundle %TargetFolderDisable% --type SITEMINDER_CONFIGURATION --action Existing
	call GatewayMigrationUtility.bat manageMappings --bundle %TargetFolderDisable% --type SECURE_PASSWORD --action Existing
	call GatewayMigrationUtility.bat manageMappings --bundle %TargetFolderDisable% --type ENCAPSULATED_ASSERTION --action Existing
    call GatewayMigrationUtility.bat manageMappings --bundle %TargetFolderDisable% --type POLICY --action Existing
	:: 개발서버에 맵핑오류인 POLICY
	call GatewayMigrationUtility.bat manageMappings --bundle %TargetFolderDisable% --type POLICY --srcId 542cf8b2-4d67-4a61-bdd7-3e1c748fdc6e --action Ignore
	:: Update only services
	call GatewayMigrationUtility.bat manageMappings --bundle %TargetFolderDisable% --type SERVICE --action Update
	
	echo INFO: GatewayMigrationUtility.bat migrateIn -z %GatewayTarget% --bundle %TargetFolderDisable% --results %DefaultDIR%\ResultTest_%Today%_DisableWork.xml --template %TargetFolderDisable%/TARGET-templatized-backup.properties --test
    call GatewayMigrationUtility.bat migrateIn -z %GatewayTarget% --bundle %TargetFolderDisable% --results %DefaultDIR%\ResultTest_%Today%_DisableWork.xml --template %TargetFolderDisable%/TARGET-templatized-backup.properties --test

	exit /b 1
)

:: run to disable service
if "%step%" == "3" (
	echo WARN: now magrateIn to %GatewayTarget%
	echo INFO: migrateIn -z %GatewayTarget% --bundle %TargetFolderDisable% --results %DefaultDIR%\Result_%Today%_DisableWork.xml --comment "Disabled by GMU" --template %TargetFolderDisable%/TARGET-templatized.properties
	PAUSE
    call GatewayMigrationUtility.bat migrateIn -z %GatewayTarget% --bundle %TargetFolderDisable% --results %DefaultDIR%\Result_%Today%_DisableWork.xml --comment "Disabled by GMU" --template %TargetFolderDisable%/TARGET-templatized.properties

	exit /b 1
)

:: run to enable service
if "%step%" == "4" (
	echo WARN: now magrateIn to %GatewayTarget%
	echo INFO: migrateIn -z %GatewayTarget% --bundle %TargetFolderDisable% --results %DefaultDIR%\Result_%Today%_DisableWork.xml --comment "Enabled by GMU" --template %TargetFolderDisable%/TARGET-templatized-backup.properties
	PAUSE
    call GatewayMigrationUtility.bat migrateIn -z %GatewayTarget% --bundle %TargetFolderDisable% --results %DefaultDIR%\Result_%Today%_DisableWork.xml --comment "Enabled by GMU" --template %TargetFolderDisable%/TARGET-templatized-backup.properties

	exit /b 1
)
goto :HELP


:REMOVEDIR
if not "%1" == "" (
	if exist %1% (
		echo INFO:		%TargetBackup%
		PAUSE
		rmdir /s /q %1%
		echo INFO: 		%1% is removed
	)
)
goto :EOF

goto :HELP

ENDLOCAL
