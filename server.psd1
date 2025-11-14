@{
    Server = @{
        Logging = @{
            Masking = @{
                Patterns = @('password=\w+', 'key=\w+', 'secret=\w+')
                Mask = '--HIDDEN--'
            }
        }
    }
}