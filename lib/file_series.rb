require 'time'

# Writes to this logger will be directed to new files at a configurable frequency.
#
#  => logger = FileSeries.new('.', :prefix=>'test', :rotate_every=>60)
#  => logger.write("some message\n")
#
# This will create a file like 'test-1342477810-60.log'. A new file will be
# created every 60 seconds. You don't need to do anything except keep calling
# logger.write().
#
# Files are created as needed, so you won't end up with lots of 0-length files.
# If you do see a recent 0-length file, it's probably due to your OS buffering
# writes to the file.
#
# Other configuration options:
#   :binary - boolean. If true, log files are opened in binary mode. (Useful for Marshal.dump)
#   :separator - string. Appended to each write. Defaults to \n. Use something else in :binary mode.
#

class FileSeries
  # this is the "Gem" version for this... class/gem
  VERSION = '0.6.0'

  DEFAULT_DIR = '.'
  DEFAULT_PREFIX = 'log'
  DEFAULT_FREQ = 60
  DEFAULT_SEPARATOR = "\n"

  attr_accessor :separator
  attr_accessor :dir
  attr_accessor :file
  attr_accessor :current_ts

  def initialize(options={})
    @dir = options[:dir] || DEFAULT_DIR
    @file = nil
    @current_ts = nil
    @filename_prefix = options[:prefix] || DEFAULT_PREFIX
    @rotate_freq = options[:rotate_every] || DEFAULT_FREQ #seconds
    @binary_mode = options[:binary]
    @separator = options[:separator] || DEFAULT_SEPARATOR
    @sync = options[:sync] || false
  end

  # write something to the current log file.
  def write(message)
    log_file.write(message.to_s + @separator)
  end

  # return a File object for the current log file.
  def log_file
    ts = this_period

    # if we're in a new time period, start writing to new file.
    if (! file) || (ts != current_ts)
      rotate(ts)
    end

    file
  end

  # compute the current time period.
  def this_period
    t = Time.now.to_i
    t - (t % @rotate_freq)
  end

  # close current file handle and open a new one for a new logging period.
  # ts defaults to the current time period.
  def rotate(ts=nil)
    ts ||= this_period
    @file.close if @file
    @file = File.open(filename(ts), "a#{'b' if @binary_mode}")
    @file.sync = @sync
    @current_ts = ts
  end

  # return a string filename for the logfile for the supplied timestamp.
  # defaults to current time period.
  #
  # changes to filename structure must be matched by changes to parse_filename
  def filename(ts=nil)
    ts ||= this_period
    File.join(@dir, "#{@filename_prefix}-#{Time.at(ts).utc.strftime('%Y%m%d-%H%M%SZ')}-#{@rotate_freq}.log")
  end

  # extract the parts of a filename
  def self.parse_filename(filename)
    base = File.basename(filename, '.log')
    prefix, date, time, duration = base.split('-')
    {
      prefix: prefix,
      start_time: Time.parse("#{date} #{time}").utc,
      duration: duration.to_i
    }
  end

  def parse_filename(filename)
    self.class.parse_filename(filename)
  end

  def path
    filename
  end

  # get all files which match our pattern which are not current.
  # (safe for consumption. no longer being written to.)
  def complete_files
    current_file = filename

    Dir.glob(
      File.join(@dir, "#{@filename_prefix}-*-#{@rotate_freq}.log")
    ).select do |name|
      name != current_file
    end
  end

  # enumerate over all the writes in a series, across all files.
  def each
    complete_files.sort.each do |file|
      File.open(file,"r#{'b' if @binary_mode}").each_line(@separator) do |raw|
        yield raw
      end
    end
  end

end
