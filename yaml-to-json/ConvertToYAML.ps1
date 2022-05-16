
param(
    [Parameter(Mandatory=$true)]$Path,
    [Parameter(Mandatory=$false)]$OutputFolder
)


function ConvertToYAMLToJSON {

    $Path = Get-Location


    if (Get-Module -ListAvailable -Name powershell-yaml) {
        Write-Verbose "Module already installed"
    }
    else {
        Write-Host "Installing PowerShell-YAML module"
        try {
            Install-Module powershell-yaml -AllowClobber -Force -ErrorAction Stop
            Import-Module powershell-yaml
        }
        catch {
            Write-Error $_.Exception.Message
            break
        }
    }

    <#
        If OutPut folder defined then test if exists otherwise create folder
    #>
    if ($OutputFolder) {
        if (Test-Path $OutputFolder) {
            $expPath = (Get-Item $OutputFolder).FullName
        }
        else {
            try {
                $script:expPath = (New-Item -Path $OutputFolder -ItemType Directory -Force).FullName
            }
            catch {
                Write-Error $_.Exception.Message
                break
            }
        } 
    }
    FolderCrawler -Path $Path

}

function FolderCrawler {
    param(
    [Parameter(Mandatory=$true)]$Path
    )

    $currentLocation = $Path
    $folderContent = Get-ChildItem -Path $currentLocation
    foreach ($item in $folderContent) {
        $Name = $item.Name
        $itemPath = "$currentLocation\$Name"
        $isFolder = Test-Path -Path $itemPath -PathType Container
        if ($isFolder){
            FolderCrawler -Path "$itemPath"
        }
        else {
            $extension = [System.IO.Path]::GetExtension($Name)
            if ($extension -in @('.yaml', '.yml')){
                ConvertToCorespondingFile -Path $itemPath
            }
        }
    }
}

function ConvertToCorespondingFile{
    param(
        [Parameter(Mandatory=$true)]$Path
    )
    $listSentinelAtrib = @('AnalyticsRules', 'HuntingRules', 'Workbooks', 'Playbooks', 'AutomationRules')
    $pathParts = $Path -split "\\"
    [array]::Reverse($pathParts)
    foreach ($part in $pathParts) {
        if ($part -in $listSentinelAtrib ){
            
        }
    }
    Write-Output $pathParts

}

ConvertToYAMLToJSON