@ECHO OFF
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)

net stop "OpalRAD PreFetch Listener" 
net stop "Opal Agent" 
net stop "Opal Backup" 
net stop "Opal Fax" 
net stop "OpalRad Dicom Print" 
net stop "OpalRad DicomPrint" 
net stop "OpalRad DICOM Receive" 
net stop "OpalRad Listener" 
net stop "OpalRad Query & Retrieve" 
net stop "OpalRad Router" 
taskkill /im "OpalMWL.exe" /f 
net stop "OpalRad ImageServer" 
net stop "SQL Server (MSSQLSERVER)" 
taskkill /im "TMController.exe" /f 
taskkill /im "DetectorService.exe" /f 
taskkill /im "Maven32.exe" /f 
taskkill /im "Maven64.exe" /f 
taskkill /im "OPALStudyList.exe" /f 
taskkill /im "OpalAdmin.exe" /f 
taskkill /IM OpalUAI64.exe /F 
taskkill /IM OpalUAI32.exe /F 
taskkill /IM relix32.exe /F 

cd C:\opal\bin 
del AcquirePlugin.dll 
del BasilDLL32.dll 
del BasilDLL64.dll 
rd bmp /s /Q 
del CamAgent.exe 
del changeLog.csv 
del Community.CsharpSqlite.dll 
del Community.CsharpSqlite.SQLiteClient.dll 
del CSDecoderApi.dll 
del CSNetApi.dll 
del CSPlayApi.dll 
del dellogfile.bat 
rd es /s /q  
del ExposureIndexProc.dll 
del FatalExceptionProcess.exe 
rd fr /s /q  
del GCA.exe 
del hi_h264dec.dll 
del hi_h264dec_w.dll 
del InterPix32.dll 
del InterPix64.dll 
del Ionic.Zip.dll 
del KMHCFastRegiusProcLibrary.dll 
del KMMGApolloWipeGradient.dll 
del KMMGRecognizeForAutoGp.dll 
del KMMGRecognizeForAutoGp_GaiaMovie.dll 
del km_mvk32.dll 
del km_mvk64.dll 
del libiomp5md.dll 
del libmmd.dll 
del log4net.dll 
del logclean.bat 
del LogFile.dll 
del lxm2_32.dll 
del lxm2_64.dll 
del Maven32.exe 
del Maven64.exe 
del mfc71.dll 
del Microsoft.VC80.CRT.manifest 
del Microsoft.VC90.CRT.manifest 
del msvcm80.dll 
del msvcm90.dll 
del msvcp100.dll 
del msvcp80.dll 
del msvcp90.dll 
del msvcr100.dll 
del msvcr71.dll 
del msvcr80.dll 
del msvcr90.dll 
del NonGridXImageProcessor.dll 
del ocv_core249_32.dll 
del ocv_core249_64.dll 
del ocv_imgproc249_32.dll 
del ocv_imgproc249_64.dll 
del OpalUAI.dll 
del OpalUAI.exe 
del OpalUAI32.exe 
del OpalUAI32Interface.dll 
del OpalUAI64.exe 
del OpalUAIStandalone.exe 
del opencv_core243.dll 
del opencv_imgproc243.dll 
del PreFusion.cie 
del PreRegistration.cie 
rd pt /s /q 
del RegiusProcLibrary.dll 
del relix32.exe 
rd ru /s /q  
del Sedecal.Comms.ExternalConsole.Sockets.dll 
del Sedecal.Comms.XRay.Serial.SSerialProtocol.dll 
del Sedecal.LogFile.dll 
del SubjectPackageTool.exe 
del svml_dispmd.dll 
rd tr /s /q  
del tvnviewer.exe 
del UAIDICOM.dll 
del UAIHelper.dll 
del UCL.dll 
del VizAcquire.OpalUAI.dll 
del WinBioNET.dll 
del WinTail.exe 
del xPipeCore32.dll 
del xPipeCore64.dll 
del XrayGenToPcComm06788.dll 
del OPALStudyList_prelaunch.bat 
del sendkeys.bat 
del XZ.ATD.dll 
del Intel.RealSense.dll 
rd zh-CHS /s /q 
del WinSCP.exe 
del OpalUAI64.exe.config 
del OpalUAI32.exe.config 
del PreRegistration.cie 
del PreFusion.cie 
del avcodec-58.dll 
del avdevice-58.dll 
del avfilter-7.dll 
del avformat-58.dll 
del avutil-56.dll 
del DotNetZip.dll 
del EncryptAppConfig.bat 
del libffmpeghelper.dll 
del Microsoft.Practices.Unity.dll 
del postproc-55.dll 
del RtspClientSharp.dll 
del Sedecal.Atomium.Comms.Channel.dll 
del Sedecal.Atomium.Comms.Configuration.dll 
del Sedecal.Atomium.Comms.Decoder.dll 
del Sedecal.Atomium.Comms.Entities.dll 
del Sedecal.Atomium.Comms.GPIO.dll 
del Sedecal.Atomium.Comms.GPIO.Messages.Base.dll 
del Sedecal.Atomium.Comms.GPIO.Messages.CANCommon.dll 
del Sedecal.Atomium.Comms.GPIO.Messages.dll 
del Sedecal.Atomium.Comms.GPIO.Messages.Generator.dll 
del Sedecal.Atomium.Comms.GPIO.Messages.ImageSystemUniversal.dll 
del Sedecal.Atomium.Comms.GPIO.Messages.Network.dll 
del Sedecal.Atomium.Comms.GPIO.Messages.Positioner.dll 
del Sedecal.Atomium.Comms.GPIO.Messages.System.dll 
del Sedecal.Atomium.Comms.LogManager.dll 
del Sedecal.Common.Enums.dll 
del Sedecal.GenericMessages.Controller.dll 
del sqlite3.exe 
del swresample-3.dll 
del swscale-5.dll 
del WinSCPnet.dll
del DicomSender.exe
del DicomSender.exe.config
del OpalLauncher2.exe
del OpalLauncher2.exe.config
rd zh-CHS /s /q  
rd regius32lib /s /q  
rd regius64lib /s /q  
rd Configuration /s /q  
rd zh-CHS /s /q  
rd bmp /s /q  
rd el /s /q  
rd es /s /q  
rd fr /s /q  
rd pl /s /q 
rd pt /s /q  
rd ru /s /q  
rd tr /s /q 
rd logs /s /q 


cd C:\opal\data 
rd BASIL /s /q 
rd CIE /s /q 
rd ConfigIcons /s /q  
del defaultTemplates.xml 
del DriverPacks.ini 
rd EICalibration /s /q 
rd FamilyIcons /s /q 
del fields_exam.spanish.txt 
del fields_exam.txt 
del fields_patient.spanish.txt 
del fields_patient.txt 
rd GammaTemplate /s /q 
rd IG /s /q 
del Image.db 
del IPP /s /q 
del OpalLDAPCredentialCache.db 
del OpalUAI.DL 
del OpalUAI.FL 
del OpalUAIActivity.db 
del OpalUAIPasswordHistory.db 
del OpalUAIPatientHolder.db 
del OpalUAI_02282023.DL.bak 
del OpalUAI_02282023.FL.bak 
rd PosGuide /s /q 
del PositioningGuide.pdf 
rd settingsHistory /s /q 
del Stitching Keyboard Movement.pdf 
rd StringDatabase /s /q 
rd TechniqueIcons /s /q 
del ToshibaCalibrationGuide.pdf 
del "Stitching Keyboard Movement".pdf 
rd Layout /s /q 
rd IPP /S /Q 
del emergencyName.xml 
del /S *.bak 
del /S *.bak.sp 


cd C:\opal\cfg 
del camagent.xml 
del OpalUAI.xml
del VizAcquire.OpalUAI.xml 
del /S *.bak
del /S *.xml.bak

cd C:\opal\log 
del UltraInstallationHistory.log 

cd C:\opal\cache
rd opaluai /s /q 
rd opaluaidata /s /q 

cd C:\opal 
rd plugins32 /s /q  
rd plugins64 /s /q  
rd driver /s /q 
rd UltraInsights /s /q 
rd Docs /s /q 
rd tmp /s /q 




net start "SQL Server (MSSQLSERVER)" 
net start "OpalRad ImageServer"
net start "OpalRad Dicom Print"
net start "OpalRad DICOM Receive"
net start "OpalRad Listener"
net start "OpalRad Router"
net start "Opal Agent"
net start "Opal Backup"
net start "OpalRad Modality Worklist"
net start "World Wide Web Publishing Service"
net start "Code42 CrashPlan Backup Service"

cls 
ECHO UAI has been removed from this system.