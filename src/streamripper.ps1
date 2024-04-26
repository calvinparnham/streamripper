# Command Line parameters
param
(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$StreamUrl,
	
	[Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$FileExtension,
	
	[Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputDirectory
)


# Define function to extract stream title from metadata
function Get-StreamTitle
{
    param
	(
        [string]$url
    )
    try
	{
        $ffmpegMetadata = ffmpeg -i $url 2>&1
        $streamTitle = $ffmpegMetadata | Select-String "StreamTitle"
        $extractedName = $streamTitle -replace '.*: (.*)', '$1'
        return $extractedName -replace '\s', ''
    }
    catch
	{
        Write-Host "Error occurred while extracting stream title: $_"
        return $null
    }
}

# Initialize variables
$previousStreamTitle = ""

# Main loop
while ($true)
{
    try
	{
        # Get current stream title
        $currentStreamTitle = Get-StreamTitle $StreamUrl
        
        # Check if stream title has changed
        if ($currentStreamTitle -ne $previousStreamTitle)
		{
			$openFfmpegProcesses = Get-Process -Name "ffmpeg" -ErrorAction SilentlyContinue
			
			if ($openFfmpegProcesses -ne $null)
			{
				try
				{
					Stop-Process -Name "ffmpeg" -Force
					Write-Host "Successfully stopped leftover ffmpeg processes"
				}
				catch
				{
					Write-Host "Error occurred while trying to stop leftover ffmpeg processes with process Id" $process.Id
				}
					
				Write-Host "Previous recording stopped."
			}
            
            # Set output filename based on current stream title
            $outputFilename = "$OutputDirectory\$currentStreamTitle.$FileExtension"
			
            # Start recording
            Start-Process ffmpeg -ArgumentList "-i $StreamUrl -c copy $outputFilename -y -nostdin -loglevel quiet" -NoNewWindow
            Write-Host "Recording started: $outputFilename"
			
            # Update previous stream title
            $previousStreamTitle = $currentStreamTitle
        }
    }
    catch
	{
        Write-Host "Error occurred in main loop: $_"
    }
    
    # Sleep for a short duration before checking again
    Start-Sleep -Seconds 1
}