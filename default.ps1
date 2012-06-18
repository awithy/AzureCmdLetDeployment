$framework = '4.0'
properties {
  $buildConfiguration='Release'
  $global:rootDir = Resolve-Path .
  $srcDir = Join-Path $rootDir 'src'
  $binDir = Join-Path $rootDir 'bin'
  $msbuild = "c:/Windows/Microsoft.NET/Framework/v4.0.30319/msbuild.exe"
  $solutionName = "AzureCmdLetDeployment.sln"
  $subscriptionId = "<subscription-id>"    #<--modify
  $certificate = Get-Cert
}

task ? -description "Helper to display task info" {
    Write-Documentation
}

task default -depends Compile

task Compile -description "Simple compile" { 
  RunMsBuild "Build" $solutionName
}

function RunMsBuild($target, $solutionName, $additionalArgs) {
  $env:MSBuildExtensionsPath32 = [System.IO.Path]::Combine($binDir, 'MicrosoftMSBuild\')
  $env:MSBuildExtensionsPath = [System.IO.Path]::Combine($binDir, 'MicrosoftMSBuild\')
  $env:CloudExtensionsDir = [System.IO.Path]::Combine($binDir, 'Azure\MSBuild\')
  $env:ServiceHostingSDKInstallDir=[System.IO.Path]::Combine($binDir, 'Azure\SDK\')
  $env:ServiceHostingSDKSupport=7 
  $env:ActiveAzureSdkVersion='1.6'
  $env:ServiceHostingSDKBinDir=[System.IO.Path]::Combine($binDir, 'Azure\SDK\bin\')
  
  Write-Host "Service Hosting SDK Install dir: " $env:ServiceHostingSDKInstallDir
  Write-Host "$srcDir\$solutionName" /target:"$target" /verbosity:minimal /nologo /p:Configuration=$buildConfiguration $additionalArgs
  exec { 
    & $msbuild "$srcDir\$solutionName" /target:"$target" /verbosity:minimal /nologo /p:Configuration=$buildConfiguration $additionalArgs
  }
}

task Deploy -depends ImportAzureCmdlets {
  $serviceName = "<service-name>"    #<--modify
  $storageAccountKey = "<storage-key>"    #<--modify
  Create-Deployment $serviceName $storageAccountKey
}

task ImportAzureCmdlets {
   "Importing WAPPSCmdlets"
   import-module "$binDir\AzurePowershellScripts\WAPPSCmdlets.dll"
}

function Create-Deployment($serviceName, $storageAccountKey) {
   $appPublishPath = Join-Path $srcDir "AzureService\bin\Release\app.publish"  
   
   "Publishing cspkg"
   RunMsBuild "Publish" "AzureService\AzureService.ccproj" "/p:TargetProfile=$serviceName"

   "Uploading blob"
   add-blob -BlobType block -FilePath "$appPublishPath\AzureService.cspkg" -ContainerName "packages" -StorageAccountName $serviceName -StorageAccountKey $storageAccountKey

   Delete-DeploymentIfExists $serviceName

   "Creating deployment"   
   WaitFor-Operation(new-deployment -Slot Production -Package "http://$serviceName.blob.core.windows.net/packages/AzureService.cspkg" -Configuration "$appPublishPath\ServiceConfiguration.cscfg" -Label $serviceName -Name $serviceName -ServiceName $serviceName -StorageAccountName $serviceName -SubscriptionId $subscriptionId -Certificate $certificate)
   
   "Starting deployment"
   WaitFor-Operation(Set-DeploymentStatus -Status Running -Slot Production -ServiceName $serviceName -SubscriptionId $subscriptionId -Certificate $certificate)
}

function Delete-DeploymentIfExists($serviceName) {
   $deployment = get-deployment -Slot Production -ServiceName $serviceName -SubscriptionId $subscriptionId -Certificate $certificate
   if($deployment -ne $Null) {
     "Delete existing deployment"
     WaitFor-Operation(remove-deployment -Slot Production -ServiceName $serviceName -SubscriptionId $subscriptionId -Certificate $certificate)
   }
}

function Get-Cert {
   return New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(".\lib\AzureCertificate\AzureMgmt.pfx", "<certificate-password>")    #<--modify
}

function WaitFor-Operation($operation) {
   "Waiting..."
   Get-OperationStatus $operation.OperationId -WaitToComplete -SubscriptionId $subscriptionId -Certificate $certificate
}