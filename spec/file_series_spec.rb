require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
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

		Timecop.freeze(Time.at(100))
		fs = FileSeries.new(:dir=>test_dir, :rotate_every => 10)
		fs.write('foo')

		name = File.join(test_dir,'log-100-10.log')
		File.exist?(name).should == true
		fs.file.flush
		IO.read(name).should == "foo\n"

		Timecop.freeze(Time.at(115))
		fs.write('foo again')

		name = File.join(test_dir,'log-110-10.log')
		File.exist?(name).should == true
		fs.file.flush
		IO.read(name).should == "foo again\n"

	end

	describe "#write" do
		it "should call log_file.write with message and separator" do
			fs = FileSeries.new(:separator=>'...')

			fs.should_receive(:log_file) {
				d = double('log_file')
				d.should_receive(:write).with("foo...")
				d
			}

			fs.write('foo')
		end
	end

	describe "#log_file" do
		it "should call rotate if no file is open" do
			fs = FileSeries.new
			fs.should_receive(:rotate)
			fs.log_file
		end
	end

	describe "#this_period" do
		it "should floor timestamp to the beginning of the current period" do
			fs = FileSeries.new( :rotate_every=>20 )
			now = Time.now.to_i

			fs.this_period.should == (now - (now%20))
		end
	end

	describe "#filename" do
		it "should accept a timestamp argument" do
			fs = FileSeries.new( :dir=>'/tmp', :prefix=>'test', :rotate_every=>60)
			fs.filename(1234).should == "/tmp/test-1234-60.log"
		end

		it "should use this_period when no timestamp is supplied" do
			fs = FileSeries.new( :dir=>'/tmp', :prefix=>'test', :rotate_every=>3600)
			fs.should_receive(:this_period) {4321}
			fs.filename.should == "/tmp/test-4321-3600.log"
		end
	end

	describe "#complete_files" do
		it "should find files in our series which are not in use" do
			list = [
				'/tmp/prefix-100-10.log',
				'/tmp/prefix-110-10.log',
				'/tmp/prefix-120-10.log',
				'/tmp/prefix-130-10.log',
			]

			Dir.should_receive(:glob).with('/tmp/prefix-*-10.log') {list}

			Timecop.freeze(Time.at(136)) do
				fs = FileSeries.new(:dir=>'/tmp', :prefix=>'prefix', :rotate_every=>10)
				fs.complete_files.should == (list - ['/tmp/prefix-130-10.log'])
			end
		end
	end

end
