# URL Processor with GUI
# Author: LaMont Session
# Description: PowerShell script with GUI to process and refang URLs
# Created Date: 2025-12-05
# Last Modified: 2025-12-06

# Requires PowerShell 5.1 or higher
#Requires -Version 5.1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "URL Processor - Refang & Parse"
$form.Size = New-Object System.Drawing.Size(900, 700)
$form.StartPosition = "CenterScreen"
$form.TopMost = $false
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$form.MaximizeBox = $false

# Create a panel for input section
$inputPanel = New-Object System.Windows.Forms.Panel
$inputPanel.Location = New-Object System.Drawing.Point(10, 10)
$inputPanel.Size = New-Object System.Drawing.Size(860, 250)
$inputPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($inputPanel)

# Input label
$inputLabel = New-Object System.Windows.Forms.Label
$inputLabel.Text = "Paste URL List (one per line or space/brace separated):"
$inputLabel.Location = New-Object System.Drawing.Point(10, 10)
$inputLabel.Size = New-Object System.Drawing.Size(840, 20)
$inputLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$inputPanel.Controls.Add($inputLabel)

# Input text box
$inputTextBox = New-Object System.Windows.Forms.TextBox
$inputTextBox.Location = New-Object System.Drawing.Point(10, 35)
$inputTextBox.Size = New-Object System.Drawing.Size(840, 200)
$inputTextBox.Multiline = $true
$inputTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$inputTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$inputTextBox.WordWrap = $true
$inputPanel.Controls.Add($inputTextBox)

# Create a panel for buttons
$buttonPanel = New-Object System.Windows.Forms.Panel
$buttonPanel.Location = New-Object System.Drawing.Point(10, 270)
$buttonPanel.Size = New-Object System.Drawing.Size(860, 50)
$form.Controls.Add($buttonPanel)

# Process button
$processButton = New-Object System.Windows.Forms.Button
$processButton.Text = "Process URLs"
$processButton.Location = New-Object System.Drawing.Point(10, 10)
$processButton.Size = New-Object System.Drawing.Size(120, 30)
$processButton.Font = New-Object System.Drawing.Font("Arial", 10)
$buttonPanel.Controls.Add($processButton)

# Clear button
$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Text = "Clear All"
$clearButton.Location = New-Object System.Drawing.Point(140, 10)
$clearButton.Size = New-Object System.Drawing.Size(100, 30)
$clearButton.Font = New-Object System.Drawing.Font("Arial", 10)
$buttonPanel.Controls.Add($clearButton)

# Copy button
$copyButton = New-Object System.Windows.Forms.Button
$copyButton.Text = "Copy Output"
$copyButton.Location = New-Object System.Drawing.Point(250, 10)
$copyButton.Size = New-Object System.Drawing.Size(110, 30)
$copyButton.Font = New-Object System.Drawing.Font("Arial", 10)
$copyButton.Enabled = $false
$buttonPanel.Controls.Add($copyButton)

# Export button
$exportButton = New-Object System.Windows.Forms.Button
$exportButton.Text = "Export to File"
$exportButton.Location = New-Object System.Drawing.Point(370, 10)
$exportButton.Size = New-Object System.Drawing.Size(120, 30)
$exportButton.Font = New-Object System.Drawing.Font("Arial", 10)
$exportButton.Enabled = $false
$buttonPanel.Controls.Add($exportButton)

# URL count label
$countLabel = New-Object System.Windows.Forms.Label
$countLabel.Text = "URLs: 0"
$countLabel.Location = New-Object System.Drawing.Point(750, 15)
$countLabel.Size = New-Object System.Drawing.Size(100, 20)
$countLabel.Font = New-Object System.Drawing.Font("Arial", 9)
$countLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$buttonPanel.Controls.Add($countLabel)

# Create a panel for output section
$outputPanel = New-Object System.Windows.Forms.Panel
$outputPanel.Location = New-Object System.Drawing.Point(10, 330)
$outputPanel.Size = New-Object System.Drawing.Size(860, 330)
$outputPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($outputPanel)

# Output label
$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Text = "Processed URLs (Refanged):"
$outputLabel.Location = New-Object System.Drawing.Point(10, 10)
$outputLabel.Size = New-Object System.Drawing.Size(840, 20)
$outputLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$outputPanel.Controls.Add($outputLabel)

# Output text box
$outputTextBox = New-Object System.Windows.Forms.TextBox
$outputTextBox.Location = New-Object System.Drawing.Point(10, 35)
$outputTextBox.Size = New-Object System.Drawing.Size(840, 285)
$outputTextBox.Multiline = $true
$outputTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$outputTextBox.ReadOnly = $true
$outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$outputTextBox.WordWrap = $true
$outputTextBox.BackColor = [System.Drawing.Color]::WhiteSmoke
$outputPanel.Controls.Add($outputTextBox)

# Function to detect if a URL appears to be defanged
function Test-DefangedURL {
    param([string]$url)
    
    $url = $url.Trim()
    if ([string]::IsNullOrEmpty($url)) {
        return $false
    }
    
    # Check for common defanging patterns
    $defangPatterns = @(
        '\[.*\]',          # Square brackets: [.], [at], [dot], etc.
        'hxxp',            # hxxp:// or hxxps://
        '\{.*\}'           # Braces: {.}, {at}, etc.
    )
    
    foreach ($pattern in $defangPatterns) {
        if ($url -match $pattern) {
            return $true
        }
    }
    
    return $false
}

# Function to convert defanged URLs to standard format
function ConvertFrom-DefangedURL {
    param([string]$inputText)
    
    if ([string]::IsNullOrWhiteSpace($inputText)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter at least one URL.", "Empty Input", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return $null
    }
    
    try {
        # Detect input format and parse accordingly
        $urls = @()
        
        # Check if input looks like the original format with braces
        if ($inputText -match '\{.*\}') {
            # Original format: {None | url} {None | url}
            $urls = $inputText -split '\}\s*\{' | ForEach-Object { $_ -replace '^\{|\}$', '' -replace 'None \| ', '' }
        }
        else {
            # Simple format: one URL per line or space-separated
            # Splitting by newline first
            if ($inputText -match "`n") {
                $urls = $inputText -split "`n"
            }
            else {
                # Splitting by spaces
                $urls = $inputText -split '\s+' | Where-Object { $_ }
            }
        }
        
        # Filter out empty entries
        $urls = $urls | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_.Length -gt 0 }
        
        # Validate that at least some URLs appear to be defanged
        $defangedCount = 0
        foreach ($url in $urls) {
            if (Test-DefangedURL $url) {
                $defangedCount++
            }
        }
        
        # If no defanged URLs detected, show error and return null
        if ($defangedCount -eq 0) {
            $message = "No valid defanged URLs detected.`n`n"
            $message += "Please enter defanged URLs with obfuscation patterns such as:`n"
            $message += "  • hxxp:// or hxxps:// (instead of http:// or https://)`n"
            $message += "  • [.] or [dot] (instead of .)`n"
            $message += "  • [%%] (instead of .)`n"
            $message += "  • [at] or [@] (instead of @)`n"
            $message += "  • {.} or similar bracket notation`n`n"
            $message += "Examples of valid defanged URLs:`n"
            $message += "  hxxps://example[.]com`n"
            $message += "  http[:]//domain[.]co[.]uk`n"
            $message += "  user[@]example[.]com"
            
            [System.Windows.Forms.MessageBox]::Show($message, "Invalid Input - No Defanged URLs", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return $null
        }
        
        # Process each URL: refang and clean
        $processedUrls = $urls | ForEach-Object {
            $_.Trim() `
                -replace '\[%%\]', '.' `
                -replace '\[\.\]', '.' `
                -replace '\[dot\]', '.' `
                -replace '\[DOT\]', '.' `
                -replace '\[hxxp', 'http' `
                -replace 'hxxp://', 'http://' `
                -replace 'hxxps://', 'https://' `
                -replace '\[@\]', '@' `
                -replace '\[at\]', '@'
        } | Where-Object { $_ -and $_.Length -gt 0 } | Select-Object -Unique
        
        # Return results
        return ($processedUrls -join "`r`n")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error processing URLs: $($_.Exception.Message)", "Processing Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return $null
    }
}

# Button click events
$processButton.Add_Click({
    try {
        $inputText = $inputTextBox.Text
        $result = ConvertFrom-DefangedURL $inputText
        
        # Only show success message and update UI if result is not null (processing succeeded)
        if ($null -ne $result) {
            $outputTextBox.Text = $result
            $urlCount = ($result -split "`r`n" | Where-Object { $_ }).Count
            $copyButton.Enabled = $true
            $exportButton.Enabled = $true
            $countLabel.Text = "URLs: $urlCount"
            [System.Windows.Forms.MessageBox]::Show("Processed $urlCount URL(s) successfully.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
        # If result is null, the error message was already shown by ConvertFrom-DefangedURL function
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

$clearButton.Add_Click({
    $inputTextBox.Text = ""
    $outputTextBox.Text = ""
    $copyButton.Enabled = $false
    $exportButton.Enabled = $false
    $countLabel.Text = "URLs: 0"
})

$copyButton.Add_Click({
    try {
        $outputText = $outputTextBox.Text
        if ($outputText) {
            [System.Windows.Forms.Clipboard]::SetText($outputText)
            [System.Windows.Forms.MessageBox]::Show("Output copied to clipboard.", "Copied", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to copy to clipboard: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

$exportButton.Add_Click({
    try {
        $outputText = $outputTextBox.Text
        if ($outputText) {
            $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveFileDialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
            $saveFileDialog.DefaultExt = "txt"
            $saveFileDialog.FileName = "processed_urls_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
            $saveFileDialog.Title = "Export URLs to File"
            
            if ($saveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $outputText | Out-File -FilePath $saveFileDialog.FileName -Encoding UTF8
                [System.Windows.Forms.MessageBox]::Show("URLs exported successfully to:`n$($saveFileDialog.FileName)", "Export Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to export file: $($_.Exception.Message)", "Export Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Show the form
$form.ShowDialog() | Out-Null
