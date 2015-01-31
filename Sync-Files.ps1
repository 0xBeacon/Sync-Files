<################################################################################
.SCRIPT           Sync-Files.ps1

.DESCRIPTION
    Syncs contents of one directory to another. Creates MD5 hashes on each file
    to verify versions.  

.USAGE
    Just run the script, however, you must verify that your source and destination 
    parameters are correct prior to running the script.  You know, for safety...

.AUTHOR
    Chris Eckert 2015 - @thatchriseckert

################################################################################>

#FUNCTIONS
function Get-FileMD5 {
    Param([string]$file)
    $md5 = [System.Security.Cryptography.HashAlgorithm]::Create("MD5")
    $IO = New-Object System.IO.FileStream($file, [System.IO.FileMode]::Open)
    $StringBuilder = New-Object System.Text.StringBuilder
    $md5.ComputeHash($IO) | % { [void] $StringBuilder.Append($_.ToString("x2")) }
    $hash = $StringBuilder.ToString()
    $IO.Dispose()
    return $hash
}

#VARIABLES
$DebugPreference = "continue"

#PARAMETERS
$SRC_DIR = '\\127.0.0.1\share'
$DST_DIR = 'C:\Files'

#MAIN
Write-Host "Verify your source and destination parameters are correct, else bad things could happen..."
Start-Sleep -s 5

$SourceFiles = GCI -Recurse $SRC_DIR | ? { $_.PSIsContainer -eq $false} #get the files in the source dir.
$SourceFiles | % { # loop through the source dir files
    $src = $_.FullName #current source dir file
    Write-Debug $src
    $dest = $src -replace $SRC_DIR.Replace('\','\\'),$DST_DIR 
    if (test-path $dest) { #if file exists, check md5 hash
        $srcMD5 = Get-FileMD5 -file $src
        Write-Debug "Source file hash: $srcMD5"
        $destMD5 = Get-FileMD5 -file $dest
        Write-Debug "Destination file hash: $destMD5"
        if ($srcMD5 -eq $destMD5) { #Check md5 hash match.
            Write-Debug "File hashes match. File already exists in destination folder and will be skipped."
            $cpy = $false
        }
        else { #if MD5 hashes do not match, overwrite
            $cpy = $true
            Write-Debug "File hashes don't match. File will be copied to destination folder."
        }
    }
    else { #New files
        Write-Debug "File doesn't exist in destination folder and will be copied."
        $cpy = $true
    }
    Write-Debug "Copy is $cpy"
    if ($cpy -eq $true) { #Copy the file if file version is newer or if it doesn't exist in the destination dir.
        Write-Debug "Copying $src to $dest"
        if (!(test-path $dest)) {
            New-Item -ItemType "File" -Path $dest -Force   
        }
        Copy-Item -Path $src -Destination $dest -Force
    }
}