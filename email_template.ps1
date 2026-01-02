# Filename: email_template.ps1
# Author: LaMont Session
# Description: PowerShell script with GUI to collect user input and create an Outlook email draft.
# Created Date: 2026-01-02
# Last Modified: 2026-01-02


# Requires PowerShell 5.1 or higher
# Requires -Version 5.1

# Script-level constants
$CC_EMAIL_ADDRESS = 'example.com' # Good to change this to your desired CC email address

# Load required assemblies for Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Data Entry Form'
$form.Size = New-Object System.Drawing.Size(350,220)
$form.StartPosition = 'CenterScreen'

# Label for user input
$recipientLabel = New-Object System.Windows.Forms.Label
$recipientLabel.Location = New-Object System.Drawing.Point(10,20)
$recipientLabel.Size = New-Object System.Drawing.Size(320,20)
$recipientLabel.Text = 'Enter recipient email address info (To/CC):'
$form.Controls.Add($recipientLabel)

# TextBox for user input
$recipientTextBox = New-Object System.Windows.Forms.TextBox
$recipientTextBox.Location = New-Object System.Drawing.Point(10,50)
$recipientTextBox.Size = New-Object System.Drawing.Size(320,20)
$form.Controls.Add($recipientTextBox)

# Label for additional input (optional)
$subjectLabel = New-Object System.Windows.Forms.Label
$subjectLabel.Location = New-Object System.Drawing.Point(10,80)
$subjectLabel.Size = New-Object System.Drawing.Size(320,20)
$subjectLabel.Text = 'Enter email subject:'
$form.Controls.Add($subjectLabel)

$subjectTextBox = New-Object System.Windows.Forms.TextBox
$subjectTextBox.Location = New-Object System.Drawing.Point(10,110)
$subjectTextBox.Size = New-Object System.Drawing.Size(320,20)
$subjectTextBox.Text = '[insert prefilled subject prefix]:' # Good to change this to your desired subject prefix
$form.Controls.Add($subjectTextBox)

# OK button
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(70,150)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

# Cancel button
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(200,150)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

# Set focus to first textbox
$form.Topmost = $true
$form.Add_Shown({$recipientTextBox.Select()})


# Show the form and process input
$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    $userInput = $recipientTextBox.Text.Trim()
    $emailSubjectInput = $subjectTextBox.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($userInput)) {
        [System.Windows.Forms.MessageBox]::Show(
            'Please provide recipient email address information.',
            'Missing Data',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    $subjectPrefix = '[insert subject prefix]:' # Good to change this to your desired subject prefix
    if ($emailSubjectInput -and $emailSubjectInput.StartsWith($subjectPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        $emailSubject = $emailSubjectInput
    }
    elseif ([string]::IsNullOrWhiteSpace($emailSubjectInput)) {
        $emailSubject = $subjectPrefix
    }
    else {
        $emailSubject = "$subjectPrefix $emailSubjectInput"
    }

    try {
        $Outlook = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Outlook.Application')
    }
    catch {
        $Outlook = $null
    }

    if (-not $Outlook) {
        try {
            $Outlook = New-Object -ComObject Outlook.Application -ErrorAction Stop
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Unable to create an Outlook email. Please ensure Microsoft Outlook is installed and properly configured.`r`n`r`nError details: $($_.Exception.Message)",
                'Outlook Error',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
            return
        }
    }

    try {
        $olMailItem = 0  # Outlook Mail item type (equivalent to [Microsoft.Office.Interop.Outlook.OlItemType]::olMailItem)
        $Mail = $Outlook.CreateItem($olMailItem)
        $Mail.Subject = $emailSubject
        $Mail.To = $userInput
        $Mail.CC = $CC_EMAIL_ADDRESS

        # Display first so Outlook loads the default signature
        $Mail.Display()

        $signatureHtml = $Mail.HTMLBody

        $prefilledHtml = @"
<p>[insert HTML email content]</p>
"@

        $contentHtml = $prefilledHtml

        if ([string]::IsNullOrWhiteSpace($signatureHtml)) {
            $Mail.HTMLBody = $contentHtml
        }
        else {
            $Mail.HTMLBody = "$contentHtml$signatureHtml"
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Unable to create an Outlook email. Please ensure Microsoft Outlook is installed and properly configured.`r`n`r`nError details: $($_.Exception.Message)",
            'Outlook Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
    finally {
        if ($null -ne $Mail) {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($Mail)
            $Mail = $null
        }
        if ($null -ne $Outlook) {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($Outlook)
            $Outlook = $null
        }
    }
}

