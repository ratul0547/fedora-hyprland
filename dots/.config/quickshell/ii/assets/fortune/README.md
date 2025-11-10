# Custom Fortune Files

Place your custom fortune files in this directory to use them on the lockscreen.

## Fortune File Format

Fortune files are plain text files with quotes separated by a `%` character on a line by itself.

Example:
```
Your first quote here.
%
Your second quote here.
It can span multiple lines.
%
Your third quote here.
%
```

## Usage

1. Create a fortune file (e.g., `myquotes`) in this directory
2. Add your quotes, separated by `%` on its own line
3. The lockscreen will automatically use quotes from all files in this directory

## Notes

- Files in this directory take precedence over system fortune files
- If no files are found here, the system fortune command will be used as fallback
- You can have multiple fortune files in this directory
- The `custom` file is provided as an example and can be edited or removed
