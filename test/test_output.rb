require "test/unit"
require_relative "../lib/lackey2mse"
require 'rubygems'
require 'zip'

class TestOutput < Test::Unit::TestCase
  
  def setup
    @output_folder = 'test/files'
    @deck_file = 'test/decks/programmingdeck.txt'
    @extension = 'mse-set'
  end
 
  def teardown
    
  end
 
  def test_noparams
    expected_file = "test/decks/programming.#{@extension}"
    Lackey_MSE2.init([@deck_file, "-s"])
    assert File.exists?(expected_file), "Expected output file '#{expected_file}'"
  end
 
  def test_output
    expected_file = "#{@output_folder}/programming.#{@extension}"
    Lackey_MSE2.init([@deck_file, "-s", "-o", "#{@output_folder}"])
    assert File.exists?(expected_file), "Expected output file '#{expected_file}'"
  end
 
  def test_output_file
    expected_file = "#{@output_folder}/prgd.#{@extension}"
    Lackey_MSE2.init([@deck_file, "-s", "-o", "#{@output_folder}/prgd"])
    assert File.exists?(expected_file), "Expected output file '#{expected_file}'"
  end
 
  def test_name
    expected_file = "#{@output_folder}/dvorakpgrd.#{@extension}"
    Lackey_MSE2.init([@deck_file, "-s", "-n", "dvorakpgrd", "-o", "#{@output_folder}"])
    assert File.exists?(expected_file), "Expected output file '#{expected_file}'"
  end
 
  def test_output_invalid_name
    expected_file = "#{@output_folder}/dan_ger_ous.#{@extension}"
    Lackey_MSE2.init([@deck_file, "-s", "-o", "#{@output_folder}/dan!ger ous::a"])
    assert File.exists?(expected_file), "Expected output file '#{expected_file}'"
  end
 
  def test_dryrun
    expected_file = "#{@output_folder}/noop.#{@extension}"
    Lackey_MSE2.init([@deck_file, "-s", "-d", "-o", "#{@output_folder}/noop"])
    assert_equal false, File.exists?(expected_file), "Not expected output file '#{expected_file}'"
  end
 
  def test_contents
    expected_file = "#{@output_folder}/prgdz.#{@extension}"
    Lackey_MSE2.init([@deck_file, "-s", "-o", "#{@output_folder}/prgdz"])
    
    set_file = nil
    Zip::File.open(expected_file) do |zip_file|
      set_file = zip_file.glob('set').first
    end
    
    assert_not_nil set_file, "Expected file 'set' in '#{expected_file}'"
  end
 
end