# file_series

FileSeries is a Ruby library for writing to a group of files.

Writes will be directed to new files at a configurable frequency.

```ruby
  logger = FileSeries.new('.', prefix: 'test', rotate_every: 60)
  logger.write("some message\n")
```

This will create a file like `test-1342477810-60.log`. A new file will be
created every 60 seconds. You don't need to do anything except keep calling
`logger.write()`.

Files are created as needed, so you won't end up with lots of 0-length files.
If you do see a recent 0-length file, it's probably due to your OS buffering
writes to the file.

## Other configuration options

  - `:binary` - boolean. If true, log files are opened in binary mode. (Useful for `Marshal.dump`)
  - `:separator` - string. Appended to each write. Defaults to `\n`. Use something else in `:binary` mode.
