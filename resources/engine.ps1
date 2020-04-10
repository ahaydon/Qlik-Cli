﻿function Get-QlikEngine {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipelinebyPropertyName = $true)]
        [string]$id,
        [string]$filter,
        [switch]$full,
        [switch]$raw
    )

    PROCESS {
        $path = "/qrs/engineservice"
        If ( $id ) { $path += "/$id" }
        If ( $full ) { $path += "/full" }
        If ( $raw ) { $rawOutput = $true }
        return Invoke-QlikGet $path $filter
    }
}

function Get-QlikValidEngines {
    [CmdletBinding()]
    param (
        [parameter(Position = 0)]
        [string]$proxyId,
        [parameter(Position = 1)]
        [string]$proxyPrefix,
        [parameter(Position = 2)]
        [string]$appId,
        [parameter(Position = 3)]
        [ValidateSet("Production", "Development", "Any")]
        [string]$loadBalancingPurpose,
        [switch]$raw
    )

    PROCESS {
        $json = @{
            proxyId = $proxyId;
            proxyPrefix = $proxyPrefix;
            appId = $appId;
            loadBalancingPurpose = $loadBalancingPurpose
        } | ConvertTo-Json -Compress -Depth 10

        If ( $raw ) { $rawOutput = $true }
        Invoke-QlikPost "/qrs/loadbalancing/validengines" $json
    }
}

function Update-QlikEngine {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True, Position = 0)]
        [string]$id,

        [ValidateSet("IgnoreMaxLimit", "SoftMaxLimit", "HardMaxLimit")]
        [string]$workingSetSizeMode,

        [ValidateRange(0, 100)]
        [Int]$workingSetSizeLoPct,

        [ValidateRange(0, 100)]
        [Int]$workingSetSizeHiPct,

        [ValidateRange(0, 100)]
        [Int]$cpuThrottlePercentage,

        [ValidateRange(0, 256)]
        [int]$coresToAllocate,

        [Bool]$AllowDataLineage,
        [Bool]$StandardReload,
        [string]$documentDirectory,
        [Int]$documentTimeout,
        [int]$autosaveInterval,
        [int]$genericUndoBufferMaxSize
    )

    PROCESS {
        $engine = Get-QlikEngine -Id $id -raw
        Write-Verbose $workingSetSizeMode
        if ( $workingSetSizeMode ) {
            switch ($workingSetSizeMode) {
                IgnoreMaxLimit { $sizeMode = 0 }
                SoftMaxLimit { $sizeMode = 1 }
                HardMaxLimit { $sizeMode = 2 }
            }
            $engine.settings.workingSetSizeMode = $sizeMode
        }
        if ($workingSetSizeLoPct) {
            $engine.settings.workingSetSizeLoPct = $workingSetSizeLoPct
        }
        if ($workingSetSizeHiPct) {
            $engine.settings.workingSetSizeHiPct = $workingSetSizeHiPct
        }
        if ($cpuThrottlePercentage) {
            $engine.settings.cpuThrottlePercentage = $cpuThrottlePercentage
        }
        if ($coresToAllocate) {
            $coremask = , 0 * 8
            $bin = ''.PadRight($coresToAllocate, '1').PadLeft(256, '0')
            for ($i = 0; $i -lt 8; $i++) {
                $coremask[$i] = [convert]::ToInt32($bin.Substring($i * 32, 32), 2)
            }

            $engine.settings.maxCoreMaskPersisted = $coremask[7]
            $engine.settings.maxCoreMaskHiPersisted = $coremask[6]
            $engine.settings.maxCoreMaskGrp1Persisted = $coremask[5]
            $engine.settings.maxCoreMaskGrp1HiPersisted = $coremask[4]
            $engine.settings.maxCoreMaskGrp2Persisted = $coremask[3]
            $engine.settings.maxCoreMaskGrp2HiPersisted = $coremask[2]
            $engine.settings.maxCoreMaskGrp3Persisted = $coremask[1]
            $engine.settings.maxCoreMaskGrp3HiPersisted = $coremask[0]
        }
        if ($documentDirectory) {
            $engine.settings.documentDirectory = $documentDirectory
        }
        if ($AllowDataLineage) {
            $engine.settings.allowDataLineage = $AllowDataLineage
        }
        if ($StandardReload) {
            $engine.settings.standardReload = $StandardReload
        }
        if ($documentTimeout) {
            $engine.settings.documentTimeout = $documentTimeout
        }
        if ($autosaveInterval) {
            $engine.settings.autosaveInterval = $autosaveInterval
        }
        if ($genericUndoBufferMaxSize) {
            $engine.settings.genericUndoBufferMaxSize = $genericUndoBufferMaxSize
        }
        $json = $engine | ConvertTo-Json -Compress -Depth 10
        return Invoke-QlikPut -Path "/qrs/engineservice/$id" -Body $json
    }
}
