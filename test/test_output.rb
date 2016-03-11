require "test/unit"
require 'rubygems'
require 'zip'
 
class TestOutput < Test::Unit::TestCase
  
  def setup
    @output_folder = 'test/files/'
    @expected_file = 'prgd.mse-set'
    @expected_file_entry = 'set'
  end
 
  def teardown
    
  end
 
  def test_file
    assert File.exists?("#{@output_folder}#{@expected_file}"), "Expected output file '#{@output_folder}#{@expected_file}'"
  end
 
  def test_file_contents
    set_file = nil
    Zip::File.open("#{@output_folder}#{@expected_file}") do |zip_file|
      set_file = zip_file.glob(@expected_file_entry).first
    end
    
    assert_not_nil set_file, "Expected file '#{@expected_file_entry}' in '#{@expected_file}'"
  end
 
end