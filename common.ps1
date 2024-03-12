function Generate-Password {
    [CmdletBinding()]
    param (
    )
    

    $password = 'a'..'z' | Get-Random -Count 5
    $password += 'A'..'Z' | Get-Random -Count 5
    $password += 0..9 | Get-Random -Count 5
    $password += '!@#$%^&*()_+-=[]{}|;:,.<>?~'.ToCharArray() | Get-Random -Count 5

    return -join ($password | Get-Random -Count 20)
}