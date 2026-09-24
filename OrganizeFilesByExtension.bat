@echo off
setlocal EnableDelayedExpansion

for %%a in (".\*") do (

    rem Skip files with no extension
    if "%%~xa" NEQ "" (

        rem Skip this batch file itself
        if /I "%%~fa" NEQ "%~f0" (

            rem Get the extension
            set "ext=%%~xa"

            rem Remove the leading dot
            set "folder=!ext:~1!"

            rem Create the folder if it does not exist
            if not exist "!folder!" (
                mkdir "!folder!"
            )

            rem Move the file into its extension folder
            move "%%a" "!folder!\"
        )
    )
)

endlocal
