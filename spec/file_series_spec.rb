require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'time'
require 'timecop'

def test_dir
  '/tmp/file_series_tests'
end

describe "FileSeries" do

  before(:all) do
    `mkdir -p #{test_dir}`
  end
  after(:all) do
    `rm -Rf #{test_dir}`
  end
  before(:each) do
    `rm -f #{test_dir}/*`
  end

  it "should write to a new file if we are in a new time period" do

    Timecop.freeze(Time.parse('1970-01-01 00:01:00Z'))
    fs = FileSeries.new(dir: test_dir, rotate_every: 10)
    fs.write('foo')

    name = File.join(test_dir, 'log-19700101-000100Z-10.log')
    expect(File.exist?(name)).to eq true
    fs.file.flush
    expect(IO.read(name)).to eq "foo\n"

    Timecop.freeze(Time.parse('1970-01-01 00:01:15Z'))
    fs.write('foo again')

    name = File.join(test_dir, 'log-19700101-000110Z-10.log')
    expect(File.exist?(name)).to eq true
    fs.file.flush
    expect(IO.read(name)).to eq("foo again\n")

  end

  it "should support binary file writing" do
    # TODO: need to come up with some sequence which can't be written in non-binary mode.
    # Trying to write a Marshal'd version of
    # https://github.com/tedconf/videometrics/blob/83ad528b013ce591ac2500d7317e0904270356f9/spec/controllers/imports_controller_spec.rb#L92
    # in non-binary mode fails with
    #   Failure/Error: post :record_event, :event => @event
    #   Encoding::UndefinedConversionError:
    #   "\x87" from ASCII-8BIT to UTF-8
    # Writing in binary mode works fine. How to reproduce that more simply for a test?
  end

  describe "#new" do
    it "should set sync to false by default" do
      fs = FileSeries.new(dir: test_dir)
      fs.write 'blah'
      expect(fs.file.sync).to eq false
    end

    it "should allow control of sync behavior" do
      fs = FileSeries.new(sync: true, dir: test_dir)
      fs.write 'blah'
      expect(fs.file.sync).to eq true

      fs = FileSeries.new(sync: false, dir: test_dir)
      fs.write 'blah'
      expect(fs.file.sync).to eq false
    end
  end

  describe "#write" do
    it "should call log_file.write with message and separator" do
      fs = FileSeries.new(separator: '...')

      expect(fs).to receive(:log_file) do
        d = double('log_file')
        expect(d).to receive(:write).with("foo...")
        d
      end

      fs.write('foo')
    end
  end

  describe "#log_file" do
    it "should call rotate if no file is open" do
      fs = FileSeries.new
      expect(fs).to receive(:rotate)
      fs.log_file
    end
  end

  describe "#this_period" do
    it "should floor timestamp to the beginning of the current period" do
      fs = FileSeries.new(rotate_every: 20)
      now = Time.now.to_i

      expect(fs.this_period).to eq(now - (now % 20))
    end
  end

  describe "#filename" do
    it "should accept a timestamp argument" do
      fs = FileSeries.new(dir: '/tmp', prefix: 'test', rotate_every: 60)
      expect(fs.filename(Time.parse('1970-01-01 00:20:34Z').to_i))
        .to eq "/tmp/test-19700101-002034Z-60.log"
    end

    it "should use this_period when no timestamp is supplied" do
      fs = FileSeries.new(dir: '/tmp', prefix: 'test', rotate_every: 3600)
      expect(fs).to receive(:this_period) { Time.parse('1970-01-01 00:20:00Z').to_i }
      expect(fs.filename).to eq("/tmp/test-19700101-002000Z-3600.log")
    end
  end

  describe "parse_filename" do
    it "should return a hash of information about a filename" do
      data = FileSeries.parse_filename("/tmp/test-19700101-002000Z-3600.log")

      expect(data[:prefix]).to eq 'test'
      expect(data[:start_time]).to eq Time.parse('1970-01-01T00:20:00Z')
      expect(data[:duration]).to eq 3600
    end

    it "should have an instance version also" do
      filename = "/tmp/test-19700101-002000Z-3600.log"
      data1 = FileSeries.parse_filename(filename)

      fs = FileSeries.new(dir: '/tmp', prefix: 'test', rotate_every: 3600)
      data2 = fs.parse_filename(filename)

      expect(data2).to eq data1
    end

  end

  describe "#path" do
    it "should act like #filename with no arguments" do
      fs = FileSeries.new(dir: '/tmp', prefix: 'test', rotate_every: 3600)
      expect(fs).to receive(:this_period) { Time.parse('1970-01-01 00:20:00Z').to_i }
      expect(fs.path).to eq("/tmp/test-19700101-002000Z-3600.log")
    end
  end

  describe "#complete_files" do
    it "should find files in our series which are not in use" do
      list = [
        '/tmp/prefix-19700101-000200Z-60.log',
        '/tmp/prefix-19700101-000300Z-60.log',
        '/tmp/prefix-19700101-000400Z-60.log',
        '/tmp/prefix-19700101-000500Z-60.log',
      ]

      expect(Dir).to receive(:glob).with('/tmp/prefix-*-60.log').and_return(list)

      Timecop.freeze(Time.parse('1970-01-01 00:05:05Z')) do
        fs = FileSeries.new(dir: '/tmp', prefix: 'prefix', rotate_every: 60)
        expect(fs.complete_files).to eq(list - ['/tmp/prefix-19700101-000500Z-60.log'])
      end
    end
  end

  describe "#each" do
    it "should enumerate all lines in all files in a series" do
      fs = FileSeries.new(dir: test_dir, rotate_every: 60, prefix: 'events')

      # write 3 files with consecutive integers.
      Timecop.freeze(Time.parse('1970-01-01 01:00:00')) do
        (0..9).each do |i|
          fs.write i
        end
      end
      Timecop.freeze(Time.parse('1970-01-01 01:01:00')) do
        (10..19).each do |i|
          fs.write i
        end
      end
      Timecop.freeze(Time.parse('1970-01-01 01:02:00')) do
        (20..29).each do |i|
          fs.write i
        end
      end
      fs.file.flush

      out = []
      fs.each do |line|
        out << line
      end

      expect(out).to eq((0..29).to_a.map { |i| i.to_s + "\n" })
    end

    it "should enumerate all entries in a binary file series" do
      fs = FileSeries.new(
        binary: true,
        separator: '!~!~!',
        dir: test_dir,
        prefix: 'bin',
        rotate_every: 60
      )

      Timecop.freeze(Time.parse('1970-01-01 01:00:00')) do
        (0..9).each do |i|
          fs.write Marshal.dump(i)
        end
      end
      Timecop.freeze(Time.parse('1970-01-01 01:01:00')) do
        (10..19).each do |i|
          fs.write Marshal.dump(i)
        end
      end
      Timecop.freeze(Time.parse('1970-01-01 01:02:00')) do
        (20..29).each do |i|
          fs.write Marshal.dump(i)
        end
      end
      fs.file.flush

      out = []
      fs.each do |line|
        out << Marshal.load(line)
      end

      # note that we don't get the separator, and they're Fixnum not String
      expect(out).to eq((0..29).to_a.map { |i| i })
    end
  end
end
