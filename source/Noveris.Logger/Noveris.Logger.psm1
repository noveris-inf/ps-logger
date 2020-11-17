<#
#>

################
# Global settings
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

<#
#>
Class LoggerType
{
    [string]$Prefix
    [Nullable[System.ConsoleColor]]$Color
    [string]$LogPath
    [bool]$WriteHost
    [bool]$WriteOutput
    [ScriptBlock]$FormatBlock
    [ScriptBlock]$OutputBlock

    <#
    #>
    LoggerType()
    {
        $this.Prefix = [string]::Empty
        $this.Color = $null
        $this.LogPath = [string]::Empty
        $this.WriteHost = $false
        $this.WriteOutput = $false
        $this.FormatBlock = $null
        $this.OutputBlock = $null
    }

    <#
    #>
    LoggerType([LoggerType] $loggerType)
    {
        $this.Prefix = $loggerType.Prefix
        $this.Color = $loggerType.Color
        $this.LogPath = $loggerType.LogPath
        $this.WriteHost = $loggerType.WriteHost
        $this.WriteOutput = $loggerType.WriteOutput
        $this.FormatBlock = $loggerType.FormatBlock
        $this.OutputBlock = $loggerType.OutputBlock
    }
}

<#
#>
Class GlobalLoggerType : LoggerType
{
    [string]$Name

    GlobalLoggerType() : base()
    {
    }

    GlobalLoggerType([string]$Name, [LoggerType]$loggerType) : base($loggerType)
    {
        $this.Name = $Name
    }

    GlobalLoggerType([GlobalLoggerType]$loggerType) : base($loggerType)
    {
        $this.Name = $loggerType.Name
    }
}

<#
    .SYNOPSIS
    Generate a new Logger Type for use by Write-Logger when generating messages.
 
    .PARAMETER Name
    The name of the Logger Type
 
    .PARAMETER Prefix
    A string value to prefix the message with. This is performed after any FormatBlock script.
 
    .PARAMETER Color
    The Color to use when writing content via Write-Host.
 
    .PARAMETER LogPath
    Path to a file to write finalised message content to. Contents are appended and written in UTF8
    format.
 
    .PARAMETER WriteHost
    Determine whether the message should be written to the console using Write-Host
 
    .PARAMETER WriteOutput
    Determine whether the message should be written as object output from the function
 
    .PARAMETER FormatBlock
    Script Block to be called for reformat the original message e.g. { "test: $_" }
 
    .PARAMETER OutputBlock
    Script Block to be called with the finalised message text.
 
    .PARAMETER Default
    Defines whether this Logger Type should be the default logger type
#>
Function New-LoggerType
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Prefix = [string]::Empty,

        [Parameter(Mandatory=$false)]
        [Nullable[System.ConsoleColor]]$Color = $null,

        [Parameter(Mandatory=$false)]
        [string]$LogPath = [string]::Empty,

        [Parameter(Mandatory=$false)]
        [switch]$WriteHost = $false,

        [Parameter(Mandatory=$false)]
        [switch]$WriteOutput = $false,

        [Parameter(Mandatory=$false)]
        [AllowNull()]
        [ScriptBlock]$FormatBlock = $null,

        [Parameter(Mandatory=$false)]
        [AllowNull()]
        [ScriptBlock]$OutputBlock = $null,

        [Parameter(Mandatory=$false)]
        [switch]$Default = $false
    )

    process
    {
        Write-Verbose "Creating new logger type"
        $newType = New-Object LoggerType
        $newType.WriteHost = $WriteHost
        $newType.WriteOutput = $WriteOutput
    
        foreach ($param in $PSBoundParameters.Keys)
        {
            switch ($param)
            {
                "Prefix" {
                    $newType.Prefix = $Prefix
                    break
                }
                "Color" {
                    $newType.Color = $Color
                    break
                }
                "LogPath" {
                    $newType.LogPath = $LogPath
                    break
                }
                "FormatBlock" {
                    $newType.FormatBlock = $FormatBlock
                    break
                }
                "OutputBlock" {
                    $newType.OutputBlock = $OutputBlock
                    break
                }
            }
        }
    
        $newType
    }
}

<#
    .SYNOPSIS
    Update-LoggerType updates an existing LoggerType with new options or may be used to remove options. LoggerType objects
    can be supplied by pipeline.
 
    .PARAMETER Name
    The name of the Logger Type to update
 
    .PARAMETER Prefix
    A string value to prefix the message with. This is performed after any FormatBlock script.
 
    .PARAMETER Color
    The Color to use when writing content via Write-Host.
 
    .PARAMETER LogPath
    Path to a file to write finalised message content to. Contents are appended and written in UTF8
    format.
 
    .PARAMETER WriteHost
    Determine whether the message should be written to the console using Write-Host
 
    .PARAMETER WriteOutput
    Determine whether the message should be written as object output from the function
 
    .PARAMETER FormatBlock
    Script Block to be called for reformat the original message e.g. { "test: $_" }
 
    .PARAMETER OutputBlock
    Script Block to be called with the finalised message text.
 
    .PARAMETER Default
    Defines whether this Logger Type should be the default logger type
#>
Function Update-LoggerType
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline,ParameterSetName="Type")]
        [LoggerType]$Type,

        [Parameter(Mandatory=$true,Position=0,ParameterSetName="Name")]
        [string]$Name,

        [Parameter(Mandatory=$false,ParameterSetName="Name")]
        [Parameter(Mandatory=$false,ParameterSetName="Type")]
        $Prefix = $null,

        [Parameter(Mandatory=$false,ParameterSetName="Name")]
        [Parameter(Mandatory=$false,ParameterSetName="Type")]
        [Nullable[System.ConsoleColor]]$Color = $null,

        [Parameter(Mandatory=$false,ParameterSetName="Name")]
        [Parameter(Mandatory=$false,ParameterSetName="Type")]
        $LogPath = $null,

        [Parameter(Mandatory=$false,ParameterSetName="Name")]
        [Parameter(Mandatory=$false,ParameterSetName="Type")]
        [switch]$WriteHost,

        [Parameter(Mandatory=$false,ParameterSetName="Name")]
        [Parameter(Mandatory=$false,ParameterSetName="Type")]
        [switch]$WriteOutput,

        [Parameter(Mandatory=$false,ParameterSetName="Name")]
        [Parameter(Mandatory=$false,ParameterSetName="Type")]
        [AllowNull()]
        [ScriptBlock]$FormatBlock = $null,

        [Parameter(Mandatory=$false,ParameterSetName="Name")]
        [Parameter(Mandatory=$false,ParameterSetName="Type")]
        [AllowNull()]
        [ScriptBlock]$OutputBlock = $null
    )

    process
    {
        $opType = $null

        if ($PSBoundParameters.Keys.Contains("Name"))
        {
            if ([String]::IsNullOrEmpty($Name))
            {
                throw New-Object ArgumentException -ArgumentList "Null or empty Name supplied to Update-LoggerType"
            }

            $opType = Get-GlobalLoggerType -Name $Name
        }
        elseif ($PSBoundParameters.Keys.Contains("Type"))
        {
            if ($Type -eq $null)
            {
                throw New-Object ArgumentException -ArgumentList "Null type supplied to Update-LoggerType"
            }

            $opType = $Type
        }
        else
        {
            throw New-Object Exception -ArgumentList "Unknown operation type for Update-LoggerType"
        }
        
        if ($opType -eq $null)
        {
            throw New-Object Exception -ArgumentList "Internal error in Update-LoggerType: opType is null"
        }

        Write-Verbose "Updating logger type"
        foreach ($param in $PSBoundParameters.Keys)
        {
            switch ($param)
            {
                "Prefix" {
                    $opType.Prefix = $Prefix
                    break
                }
                "Color" {
                    $opType.Color = $Color
                    break
                }
                "LogPath" {
                    $opType.LogPath = $LogPath
                    break
                }
                "WriteHost" {
                    $opType.WriteHost = $WriteHost
                    break
                }
                "WriteOutput" {
                    $opType.WriteOutput = $WriteOutput
                    break
                }
                "FormatBlock" {
                    $opType.FormatBlock = $FormatBlock
                    break
                }
                "OutputBlock" {
                    $opType.OutputBlock = $OutputBlock
                    break
                }
            }
        }
    }
}

<#
    .SYNOPSIS
    Returns all Logger Types or a single Logger Type, if a name is referenced. Names may be passed by pipeline input.
 
    .PARAMETER Name
    The Name of the specific Logger Type to display
#>
Function Get-GlobalLoggerType
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false,Position=0)]
        [string]$Name = [string]::Empty
    )

    process
    {
        $types = $script:GlobalLoggerTypes.Keys
        if ($PSBoundParameters.Keys -contains "Name")
        {
            if ([string]::IsNullOrEmpty($Name))
            {
                throw New-Object ArgumentException -ArgumentList "Null or empty Name supplied to Get-GlobalLoggerType"
            }

            if (!$script:GlobalLoggerTypes.ContainsKey($Name))
            {
                throw New-Object ArgumentException -ArgumentList "Name supplied to Get-GlobalLoggerType does not exist"
            }
    
            $types = $($Name)
        }

        # Forces generation of a new collection, separate from the original
        # necessary to allow piping to remove-globalloggertype without failure
        # due to 'underlying collection has changed' error.
        $types = $types | ForEach-Object { $_ }
        $types | ForEach-Object { $script:GlobalLoggerTypes[$_] }
    }
}

<#
#>
Function Remove-GlobalLoggerType
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Name = [string]::Empty
    )

    process
    {
        if ([string]::IsNullOrEmpty($Name))
        {
            throw New-Object ArgumentException -ArgumentList "Null or empty Name passed to Remove-GlobalLoggerType"
        }
    
        if (!$script:GlobalLoggerTypes.ContainsKey($Name))
        {
            Write-Verbose "Logger type does not exist: ${Name}"
            return
        }

        Write-Verbose "Removing logger type: ${Name}"
        $null = $script:GlobalLoggerTypes.Remove($Name)
    }
}

<#
#>
Function Save-GlobalLoggerType
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Name = [string]::Empty,

        [Parameter(Mandatory=$true,ValueFromPipeline)]
        [LoggerType]$Type
    )

    process
    {
        if ([string]::IsNullOrEmpty($Name))
        {
            throw New-Object ArgumentException -ArgumentList "Null or empty Name supplied to Save-GlobalLoggerType"
        }

        if ($Type -eq $null)
        {
            throw New-Object ArgumentException -ArgumentList "Null Type supplied to Save-GlobalLoggerType"
        }

        $script:GlobalLoggerTypes[$Name] = (New-Object GlobalLoggerType -ArgumentList $Name, $Type)
    }
}

<#
#>
Function Get-DefaultLoggerType
{
    [CmdletBinding()]
    param()

    if ($script:DefaultLoggerType -eq $null)
    {
        Write-Verbose "No Logger default defined. Creating new default logger"
        $script:DefaultLoggerType = New-LoggerType -WriteHost
    }

    $script:DefaultLoggerType
}

<#
#>
Function Reset-DefaultLoggerType
{
    [CmdletBinding()]
    param()

    Write-Verbose "Resetting default logger type"
    $script:DefaultLoggerType = (New-LoggerType -WriteHost)
}

<#
#>
Function Set-DefaultLoggerType
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline)]
        [LoggerType]$Type
    )

    process
    {
        if ($Type -eq $null)
        {
            throw New-Object ArgumentException -ArgumentList "Null Type supplied to Set-DefaultLoggerType"
        }

        $script:DefaultLoggerType = New-Object LoggerType -ArgumentList $Type
    }
}

<#
#>
Function Write-Logger
{
    [CmdletBinding(DefaultParameterSetName="default")]
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline,ParameterSetName="Name")]
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline,ParameterSetName="Type")]
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline,ParameterSetName="default")]
        [AllowEmptyString()]
        [string]$Message,
        
        [Parameter(Mandatory=$true,ParameterSetName="Name")]
        [string]$Name = [string]::Empty,

        [Parameter(Mandatory=$true,ParameterSetName="Type")]
        [LoggerType]$Type
    )

    process
    {
        $opType = $null
        foreach ($param in $PSBoundParameters.Keys)
        {
            switch ($param)
            {
                "Name" {
                    if ([string]::IsNullOrEmpty($Name))
                    {
                        throw New-Object ArgumentException -ArgumentList "Null or empty Name supplied to Write-Logger"
                    }
    
                    if (!$script:GlobalLoggerTypes.Contains($Name))
                    {
                        throw New-Object ArgumentException -ArgumentList "Name supplied does not exist"
                    }
    
                    $opType = $script:GlobalLoggerTypes[$Name]
                    break
                }
                "Type" {
                    if ($Type -eq $null)
                    {
                        throw New-Object ArgumentException -ArgumentList "Null Type supplied to Write-Logger"
                    }
    
                    $opType = $Type
                    break
                }
            }
        }
    
        if ($opType -eq $null)
        {
            # Need to use the default logger
            $opType = $script:DefaultLoggerType
    
            if ($opType -eq $null)
            {
                # Somehow the default logger type is $null. Generate temporary default logger
                $opType = New-LoggerType -WriteHost
            }
        }
    
        $prefix = $opType.Prefix
        $color = $opType.Color
        $formatBlock = $opType.FormatBlock
        $outputBlock = $opType.OutputBlock
        $writeHost = $opType.WriteHost
        $writeOutput = $opType.WriteOutput
        $logPath = $opType.LogPath
    
        # Default to Grey for colour
        if ($color -eq $null)
        {
            $color = [System.ConsoleColor]::Gray
        }
    
        $msg = $Message
    
        # Use format block to pre-process message, if defined
        if ($formatBlock -ne $null)
        {
            $msg = ($msg | ForEach-Object $formatBlock).ToString()
        }
    
        # Add prefix to message
        if (![string]::IsNullOrEmpty($prefix))
        {
            $msg = [string]::Format("{0}{1}", $prefix, $msg)
        }
    
        # Write host output, if required
        if ($writeHost)
        {
            Write-Host -ForegroundColor $color $msg
        }
    
        # Write object output, if required
        if ($writeOutput)
        {
            Write-Output $msg
        }
    
        # Write to file, if defined
        if (![string]::IsNullOrEmpty($logPath))
        {
            $msg | Out-File -Append -FilePath $logPath -Encoding UTF8
        }
    
        # Send message to script block, if defined
        if ($outputBlock -ne $null)
        {
            $null = $msg | ForEach-Object $outputBlock
        }
    }
}


################
# Script variables
$script:GlobalLoggerTypes = @{}
$script:DefaultLoggerType = (New-LoggerType -WriteHost)
