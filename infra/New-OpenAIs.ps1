# Provisions Azure OpenAI Service instances to all available regions and deploy models on repective locations
Param(
    [string]
    [Parameter(Mandatory=$false)]
    $ResourceGroupLocation = "koreacentral",

    [string]
    [Parameter(Mandatory=$false)]
    $AzureEnvironmentName,

    [string]
    [Parameter(Mandatory=$false)]
    $ModelName = "gpt-4-32k",

    [string]
    [Parameter(Mandatory=$false)]
    $ModelVersion = "0613",

    [string]
    [Parameter(Mandatory=$false)]
    $ApiVersion = "2023-05-01",

    [switch]
    [Parameter(Mandatory=$false)]
    $Help
)

function Show-Usage {
    Write-Output "    This provisions Azure OpenAI Service instances to all available regions and deploy models on repective locations

    Usage: $(Split-Path $MyInvocation.ScriptName -Leaf) ``
            [-ResourceGroupLocation <Resource group location>] ``
            [-AzureEnvironmentName  <Azure environment name>] ``
            [-ModelName             <Azure OpenAI model name>] ``
            [-ModelVersion          <Azure OpenAI model version>] ``
            [-ApiVersion            <API version>] ``

            [-Help]

    Options:
        -ResourceGroupLocation  Resource group name. Default value is `'koreacentral`'
        -AzureEnvironmentName   Azure eovironment name.
        -ModelName              Azure OpenAI model name. Default value is `'gpt-4-32k`'
        -ModelVersion           Azure OpenAI model version. Default value is `'0613`'
        -ApiVersion             API version. Default value is `'2023-05-01`'

        -Help:                  Show this message.
"

    Exit 0
}

# Show usage
$needHelp = $Help -eq $true
if ($needHelp -eq $true) {
    Show-Usage
    Exit 0
}

if (($ResourceGroupLocation -eq $null) -or ($AzureEnvironmentName -eq $null) -or ($ModelName -eq $null) -or ($ModelVersion -eq $null) -or ($ApiVersion -eq $null)) {
    Show-Usage
    Exit 0
}

# Get resource token
$token = "abcdefghijklmnopqrstuvwxyz"
$subscriptionId = az account show --query "id" -o tsv
$baseValue = "$AzureEnvironmentName|$subscriptionId"
$hasher = [System.Security.Cryptography.HashAlgorithm]::Create('sha256')
$hash = $hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($baseValue))
$hash | ForEach-Object { $calculated += $token[$_ % 26] }
$resourceToken = $($calculated).Substring(0, 13).ToLowerInvariant()

# Provision resource group
$resourceGroupName = "rg-$AzureEnvironmentName"

$resourceGroupExists = az group exists -n $resourceGroupName
if ($resourceGroupExists -eq $false) {
    $rg = az group create -n $resourceGroupName -l $ResourceGroupLocation
}

# Check available locations
$subscriptionId = az account show --query "id" -o tsv
$url = "/subscriptions/$subscriptionId/providers/Microsoft.CognitiveServices"

$locations = az rest --method GET `
    --uri "$url/skus?api-version=$ApiVersion" `
    --query "value[?kind=='OpenAI'] | [?resourceType == 'accounts'].locations[0]" | ConvertFrom-Json

$locations | ForEach-Object {
    $location = $_.ToLowerInvariant()

    # Check available models
    $models = az rest --method GET `
        --uri "$url/locations/$location/models?api-version=$ApiVersion" `
        --query "sort_by(value[?kind == 'OpenAI'].{ name: model.name, version: model.version, skus: model.skus }, &name)" | ConvertFrom-Json

    $model = $models | Where-Object { $_.name -eq $ModelName -and $_.version -eq $ModelVersion -and $_.skus.Count -gt 0 -and $_.skus[0].name -eq "Standard" }
    if ($model -ne $null) {
        # Provision Azure OpenAI Services
        $cogsvc = az cognitiveservices account list -g $ResourceGroupName --query "[?location=='$location']" | ConvertFrom-Json
        if ($cogsvc -eq $null) {
            $cogsvc = az cognitiveservices account create `
                -g $resourceGroupName `
                -n "cogsvc-$resourceToken-$location" `
                -l $location `
                --kind OpenAI `
                --sku S0 `
                --assign-identity `
                --tags azd-env-name=cogsvc-$AzureEnvironmentName | ConvertFrom-Json

            Write-Output "$($cogsvc.name) instance has been provisioned"
        }

        $modelNameShortened = $ModelName.Replace("-", "").Replace(".", "")
        $modelVersionShortened = $ModelVersion.Replace("-", "").Replace(".", "")
        $deploymentName = "model-$modelNameShortened-$modelVersionShortened"
        $capacity = $ModelName -eq "dall-e-3" ? 1 : 8

        $deployment = az cognitiveservices account deployment list `
            -g $resourceGroupName `
            -n "cogsvc-$resourceToken-$location" `
            --query "[?name=='$deploymentName']" | ConvertFrom-Json

        # Deploy model
        if ($deployment -eq $null) {
            $deployment = az cognitiveservices account deployment create `
                -g $resourceGroupName `
                -n "cogsvc-$resourceToken-$location" `
                --model-format OpenAI `
                --model-name $ModelName `
                --model-version $ModelVersion `
                --deployment-name $deploymentName `
                --sku-name Standard `
                --sku-capacity $capacity

            Write-Output "$deploymentName on the $($cogsvc.name) instance has been deployed"
        }
    }
}
