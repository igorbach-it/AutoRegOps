
TASKKIll /F /FI "IMAGENAME eq rphost*"
TASKKIll /F /FI "IMAGENAME eq rmngr*"
TASKKIll /F /FI "IMAGENAME eq ragent*"

net stop "1C:Enterprise 8.3 Server Agent (x86-64)"
@FOR /D %%i in ("C:\Users\*") do ( 
@FOR /D %%j in ("%%i\Local settings\Application data\1C\1Cv81\????????-????-????-????-????????????") do rd /s /q "%%j"
@FOR /D %%j in ("%%i\Local settings\Application data\1C\1Cv82\????????-????-????-????-????????????") do rd /s /q "%%j" 
@FOR /D %%j in ("%%i\Local settings\Application data\1C\1Cv8\????????-????-????-????-????????????") do rd /s /q "%%j" 
@FOR /D %%j in ("%%i\AppData\Roaming\1C\1Cv81\????????-????-????-????-????????????") do rd /s /q "%%j"
@FOR /D %%j in ("%%i\AppData\Roaming\1C\1Cv82\????????-????-????-????-????????????") do rd /s /q "%%j"  
@FOR /D %%j in ("%%i\AppData\Roaming\1C\1Cv8\????????-????-????-????-????????????") do rd /s /q "%%j" 
)
@FOR /D %%i in ("C:\Program Files\1cv8\srvinfo\reg_1541\*") do ( 
@FOR /D %%j in ("%%i\1Cv8FTxt") do rd /s /q %%j 
)
net start "1C:Enterprise 8.3 Server Agent (x86-64)"
