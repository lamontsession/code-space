## Email Template Script

### email_template.ps1 - Generic Email Template

#### Description
The email template script (`email_template.ps1`) is a Windows PowerShell GUI application that creates Outlook email drafts with customizable prefilled content, subject lines, and recipient information. It provides a template-based approach for creating consistent, professional emails with predefined body text and signature integration.

#### Features
- **Modern GUI Interface**: User-friendly Windows Forms interface for entering email details
- **Customizable Subject Prefix**: Prefilled subject line with customizable prefix (e.g., "[Email Released]:")
- **Predefined Email Body**: Support for custom HTML email templates with automatic signature integration
- **Recipient Management**: Simple input field for specifying recipient email addresses (To field)
- **CC Support**: Script-level constant for automatic CC'ing to designated recipients
- **Signature Integration**: Automatically loads and preserves user's Outlook default signature
- **Input Validation**: Validates that required recipient information is provided before creating draft
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Outlook Integration**: Seamless integration with Microsoft Outlook COM interface
- **Professional UI**: Clean, intuitive interface with clear labels and organized layout

#### Prerequisites
- Windows operating system
- PowerShell 5.1 or higher
- Microsoft Outlook installed and configured
- .NET Framework (typically pre-installed on Windows)

#### Installation
1. Clone the repository (if not already done):
```powershell
git clone https://github.com/lamontsession/code-space.git
cd code-space
```

2. The script is ready to use - no additional installation required

#### Configuration
To customize the script for your organization, edit the script-level constants:

```powershell
# Script-level constants at the top of the file
$CC_EMAIL_ADDRESS = 'your-email@example.com'  # Change this to your CC email
```

You can also customize the subject prefix and email body template within the script.

#### Usage
Run the script from PowerShell:
```powershell
.\email_template.ps1
```

Or right-click the file and select "Run with PowerShell"

#### How to Use
1. **Launch the application** by running the PowerShell script
2. **Enter recipient addresses** in the first field (To field) - can include multiple addresses separated by semicolons
3. **Modify the subject** if needed (prefix is automatically added if not present)
4. **Click OK** to create the Outlook draft
5. **Review the draft** in Outlook, add attachments if needed, and send when ready
6. **Click Cancel** to close without creating an email

#### Example Workflow

**User Input:**
- Recipients: `user1@example.com; user2@example.com`
- Subject: `Monthly Report`

**Result:**
- Outlook draft created with:
  - To: `user1@example.com; user2@example.com`
  - CC: `your-email@example.com`
  - Subject: `[Automated Email]: Monthly Report`
  - Body: Prefilled template text + user's signature

#### Use Cases
- **Administrative Communications**: Create consistent internal communications with standardized formatting
- **Security Notifications**: Send templated security alerts or notifications with consistent messaging
- **Policy Communications**: Distribute organizational policies with predefined legal disclaimers
- **Bulk Notifications**: Quickly send notifications to multiple recipients with the same template
- **Standardized Workflows**: Ensure all outbound communications maintain consistent branding and format

#### Technical Details
- Built using Windows Forms (.NET Framework)
- Uses Outlook COM interface for seamless integration
- HTML-based email body support with signature preservation
- Input validation using PowerShell string operations
- Proper COM object cleanup and resource management
- Subject prefix logic prevents duplicate prefixes

#### Important Notes
- Microsoft Outlook must be installed and configured with an email account
- The script creates a draft - emails are not automatically sent
- Subject prefix is automatically added if not already present
- User's Outlook signature is automatically included (if configured in Outlook)
- CC field is controlled by the script constant - modify as needed
- The script displays the email draft for review before sending
- Always review the draft in Outlook before sending to ensure all details are correct

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

LaMont Session

## Last Updated

2026-03-07