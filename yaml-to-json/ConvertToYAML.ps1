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
                
                ConvertToCorespondingFileType -Path $itemPath
            }
        }
    }
}

function ConvertToCorespondingFileType{
    param(
        [Parameter(Mandatory=$true)]$Path
    )
    $listSentinelAtrib = @('AnalyticsRules', 'HuntingRules', 'Workbooks', 'Playbooks', 'AutomationRules')
    $pathParts = $Path -split "\\"
    [array]::Reverse($pathParts)
    foreach ($part in $pathParts) {
        if ($part -in $listSentinelAtrib ){
            $fileName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
            ConvertToJSONFile -Path $Path -Type $part -Name $fileName
            break
        }
        
    }

}

function ConvertToJSONFile{
    param(
        [Parameter()]$Path,
        [Parameter()]$Type,
        [Parameter()]$Name)

        $content = Get-Content -Path $Path

        $template = [PSCustomObject]@{
            '$schema'      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
            contentVersion = "1.0.0.0"
            Parameters     = @{
                Workspace = @{
                    type = "string"
                }
            }
            resources      = @(
                [PSCustomObject]@{
                    id         = ""
                    name       = ""
                    type       = ""
                    kind       = ""
                    apiVersion = "2021-03-01-preview"
                    properties = [PSCustomObject]@{}
                }
            )
        }

        # Update the template format with the data from YAML file
        $convert = $content | ConvertFrom-Yaml -ErrorAction Stop | Select-Object * -ExcludeProperty relevantTechniques, kind, requiredDataConnectors, version, tags

        $($template.resources).name = "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/" + $convert.id + "')]"
        $($template.resources).properties = ($convert | Select-Object * -ExcludeProperty id)
        

    if ($part -eq 'AnalyticsRules'){
        $($template.resources).id = "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/" + $convert.id + "')]"
        $($template.resources).type = "Microsoft.OperationalInsights/workspaces/providers/alertRules"
        $($template.resources).kind = "Scheduled"
        $outputFile = "AnalyticsRules\$Name.json"
    }
    elseif ($Type -eq 'HuntingRules'){

    }
    elseif ($Type -eq 'Workbooks'){

    }
    elseif ($Type -eq 'Playbooks'){

    }
    elseif ($Type -eq 'AutomationRules') {
       
    }

   

    try {
        $template | ConvertTo-Json -Depth 20 | Out-File $outputFile -ErrorAction Stop
    }
    catch {
        Write-Error $_.Exception.Message
    }
}

ConvertToYAMLToJSON