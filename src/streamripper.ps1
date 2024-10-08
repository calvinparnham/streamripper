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
        $sanitizedName = $extractedName -replace ':|;|&|\\|/|\?|!|\||''|""|@|\+|=|<|>|\$|%|#|{|}|\s', ''
        return $sanitizedName
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
            # Check if any ffmpeg processes are running - silently continue on error as this will error if none are found
            $openFfmpegProcesses = Get-Process -Name "ffmpeg" -ErrorAction SilentlyContinue
            
            if ($openFfmpegProcesses -ne $null)
            {
                try
                {
                    # Stop all ffmpeg processes to facilitate file rollover
                    Stop-Process -Name "ffmpeg" -Force
                    Write-Host "Successfully stopped leftover ffmpeg processes"
                }
                catch
                {
                    Write-Host "Error occurred while trying to stop leftover ffmpeg processes"
                }
                    
                Write-Host "Previous recording stopped."
            }
            
            # Set output filename based on current stream title and provided output directory and file extension
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