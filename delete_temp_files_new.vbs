force_cscript

dim objWSH, sProfile, objFolder
dim objFSO, sProfileRoot, objProfileFolder
dim sTemp, sWindows
dim tbk

set objFSO=CreateObject("Scripting.FileSystemObject")

' Get user profile root folder
set objWSH    = CreateObject("WScript.Shell")
sTemp = objWSH.ExpandEnvironmentStrings("%TEMP%")
sWindows = objWSH.ExpandEnvironmentStrings("%WINDIR%")
sProfile = objWSH.ExpandEnvironmentStrings("%USERPROFILE%")
sProfileRoot=objFSO.GetFolder(sProfile).ParentFolder.Path
set objWSH=nothing

set objProfileFolder=objFSO.GetFolder(sProfileRoot)
for each objFolder in objProfileFolder.SubFolders
	select case LCase(objFolder.Name)
		case "all users": ' do nothing
		case "default user": ' do nothing
		case "localservice": ' do nothing
		case "networkservice": ' do nothing
		case else:
			wscript.echo "Processing profile: " & objFolder.Name
			sProfile=sProfileRoot & "\" & objFolder.Name
			DeleteFolderContents sProfile & "\Local Settings\Temp"
			DeleteFolderContents sProfile & "\Local Settings\Temporary Internet Files\Content.IE5"
			DeleteFolderContents sProfile & "\Local Settings\Temporary Internet Files\Content.MSO"
			DeleteFolderContents sProfile & "\Local Settings\Temporary Internet Files"
			DeleteFolderContents sProfile & "\Local Settings\Application Data\Mozilla\Firefox\Profiles"
			DeleteFolderContents sProfile & "\Application Data\1C\1Cv82"
			DeleteFolderContents sProfile & "\Local Settings\Google\Chrome\User Data\Default\Cache"
	end select
next
' Now delete the folder given by the TEMP environment variable
wscript.echo "Processing folder: " & sTemp
DeleteFolderContents sTemp
' And the windows\temp folder
wscript.echo "Processing folder: " & sWindows & "\Temp"
DeleteFolderContents sWindows & "\Temp"

sub DeleteFolderContents(strFolder)
	' Deletes all files and folders within the given folder
	dim objFolder, objFile, objSubFolder
	on error resume next
	
	set objFolder=objFSO.GetFolder(strFolder)
	if Err.Number<>0 then
		Err.Clear
		Exit sub ' Couldn't get a handle to the folder, so can't do anything
	end if
	for each objSubFolder in objFolder.SubFolders
		objSubFolder.Delete true
		if Err.Number<>0 then
			'Try recursive delete (ensures better result)
			Err.Clear
			DeleteFolderContents(strFolder & "\" & objSubFolder.Name)
		end if
	next
	for each objFile in ObjFolder.Files
		objFile.Delete true
                Set tbk = objFSO.GetFile(sProfile & "\AppData\Roaming\The Bat!\autobackup.tbk")
                tbk.Delete true                                                                
		if Err.Number<>0 then Err.Clear ' In case we couldn't delete a file
	next
end sub

sub force_cscript
    dim args : args=""
    dim i, wshshell
    If right(lCase(wscript.fullname),11)= "wscript.exe" then
        for i=0 to wscript.arguments.count-1
            args = args & wscript.arguments(i) & " "
        next
        set wshshell=createobject("wscript.shell")
        wshshell.run wshshell.ExpandEnvironmentStrings("%comspec%") & _
            " /c cscript.exe //nologo """ & wscript.scriptfullname & """" & args
        set wshshell=nothing
        wscript.quit
    end if
end sub
