#--------------------------------------------
# Declare Global Variables and Functions here
#--------------------------------------------


#Sample function that provides the location of the script
function Get-ScriptDirectory
{
<#
	.SYNOPSIS
		Get-ScriptDirectory returns the proper location of the script.

	.OUTPUTS
		System.String
	
	.NOTES
		Returns the correct path within a packaged executable.
#>
	[OutputType([string])]
	param ()
	if ($null -ne $hostinvocation)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		Split-Path $script:MyInvocation.MyCommand.Path
	}
}

function Get-ChatGPTString
{
	param (
		[switch]$system,
		[switch]$user,
		[switch]$assistant,
		[string]$content
	)
	
	if ($system)
	{
		$role = 'system'
	}
	
	if ($user)
	{
		$role = 'user'
	}
	
	if ($assistant)
	{
		$role = 'assistant'
	}
	
	$data = @{ "role" = "$role"; "content" = "$content"; }
	return $data
}

function Get-ChatGPTAnswer
{
	[CmdLetBinding()]
	param (
		[String]$question,
		[switch]$conversation,
		$convoList,
		[switch]$system,
		[string]$systemString,
		[String]$model = 'gpt-4-0314',
		[int]$maxtokens = 4096,
		$temperature = 0.3
	)
	
	#define api endpoint and key
	$apiKey = ''
	$apiEndpoint = "https://api.openai.com/v1/chat/completions"
	
	#build http request headers
	$headers = @{
		"Content-Type"  = "application/json"
		"Authorization" = "Bearer $apiKey"
	}
	
	#build list with hashable inside for messages section of json
	$list = New-Object System.Collections.ArrayList
	
	#$data = @{ "role" = "user"; "content" = "$question"; }
	
	#add last reply if conversation ticked
	if (($conversation) -and ($null -ne $convoList))
	{
		$data = Get-ChatGPTString -user -content $question
		$list += $convoList
		$list += $data
		
	}
	else
	{
		$data = Get-ChatGPTString -user -content $question
		$list += $data
	}
	
	if ($system)
	{
		$data = Get-ChatGPTString -system -content $systemString
		$list += $data
	}
	
	#create hashtable for whole body section of json
	$requestBody = @{
		"model"	      = $model
		"messages"    = $list
		"temperature" = $temperature
	}
	
	#turn hashtable into json
	$json = ConvertTo-Json $requestBody
	
	#send http request
	$response = Invoke-RestMethod -Method POST -Uri $apiEndpoint -Headers $headers -Body $json
	
	#output answer into console
	return $response.choices.message.content
}

function Update-SettingsFile
{
	param (
		$path = 'C:\ProgramData\Clippy',
		$name = 'Settings.json',
		$teamsEmail,
		$teamsSystemPrompt
	)
	
	#create settings folder
	if (-not (test-path $path))
	{
		New-Item -Path 'C:\ProgramData' -Name 'Clippy' -ItemType 'Directory'
	}
	
	#remove existing settings file
	if (test-path "$path\$name")
	{
		Remove-Item -Path "$path\$name" -Confirm:$false
	}
	
	#if teamsSystemPrompt is not in settings and a new one hasnt been provided
	if (($null -eq $settings.teamsSystemPrompt) -and ($null -eq $teamsSystemPrompt))
	{
		$teamsSysPrompt = "You are an IT helper who deals with complex issues"
		
		#if teamsSystemPrompt is in settings and a new one has not been provided
	}
	elseif (($null -eq $teamsSystemPrompt) -and ($null -ne $settings.teamsSystemPrompt))
	{
		$teamsSysPrompt = $settings.teamsSystemPrompt
		
		#anything else
	}
	else
	{
		$teamsSysPrompt = $teamsSystemPrompt
	}
	
	#if teamsEmail in settings and not being updated
	if (($null -ne $settings.teamsEmail) -and ($null -eq $teamsEmail))
	{
		$teamsEmail = $settings.teamsEmail
		
	}
	
	#build settings json and output to file
	$settings = @{
		teamsEmail = "$teamsEmail"
		teamsSystemPrompt = "$teamsSysPrompt"
	} | ConvertTo-Json
	
	$settings | Out-File "$path\$name"
	
	#get contents of settings file
	Get-Settings
}

function Get-Settings
{
	param (
		$path = 'C:\ProgramData\Clippy',
		$name = 'Settings.json'
	)
	
	if (Test-Path "$path\$name")
	{
		$global:settings = Get-Content -raw -path "$path\$name" | ConvertFrom-Json
	}
	else
	{
		Update-SettingsFile
	}
}

#Sample variable that provides the location of the script
[string]$ScriptDirectory = Get-ScriptDirectory



