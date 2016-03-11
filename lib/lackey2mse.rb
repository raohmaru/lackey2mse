# encoding: UTF-8

#--
# Lackey set to MSE2 set file converter
# Copyright (c) 2016 Raohmaru

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

# Avoids errors when requiring relative files and working dir is different 
$LOAD_PATH.unshift(File.dirname(__FILE__)) unless defined? Exerb
$LOAD_PATH << '.' if $Exerb  # In execution add current path to load relative files

require 'card'
require 'set'
require 'rubygems'
require 'zip'

module Lackey_MSE2

  VERSION = "1.0.0"

  class << self

    def init(argv)
      @set_info = Set.new
      @duplicated = 0

      parse_args(argv)
      check_args
      create_set
      write_files

      puts "Found #{@set_info.num_cards} cards" + (@duplicated > 0 ? " (#{@duplicated} duplicated)" : "")
      puts "Set '#{@zipname}' created\n" unless @set_info.dryrun
    end

    def parse_args(argv)
      usage = <<EOF

= Lackey to MSE2 set file =

A tool to convert Dvorak decks in Lackey format to a Magic Set Editor 2 set file.

Find Dvorak decks at <http://www.dvorakgame.co.uk/index.php/Main_Page>
Magic Set Editor 2 template <https://github.com/raohmaru/generic-mse2-template>

Usage:
    lackey2mse2 FILE [options] [set options]

Examples:
    lackey2mse2 lackey.txt
    lackey2mse2 lackey.txt -n "Programming deck" -c PRG
    lackey2mse2 lackey.txt -l "Event:#666666;Human:125,5,1"
    lackey2mse2 lackey.txt -f -o ../decks/mydeck

Arguments:

    FILE                Input file representing a set definition of an Dvorak deck in Lackey format

Options:

    -h, --help          Display this information.
    -v, --version       Display version number and exit.
    -f, --force         Overwrites output file without asking for permission
    -d, --dry-run       Run without generating the output file

Set options:

    -n, --name WORDS    Name of the set
    -c, --code WORD     Code of the set
    -o, --output PATH   Output file name or directory
    -l, --colors LIST   A list of colors for each type or subtype
                        "Type1:hex or rgb;Subtype2:hex or rgb"
EOF
      unless argv.empty?
        while arg = argv.shift
          case arg
            when /\A--code\z/, /\A-c\z/
              @set_info.code = argv.shift
            when /\A--name\z/, /\A-n\z/
              @set_info.name = argv.shift
            when /\A--colors\z/, /\A-l\z/
              @set_info.colors = argv.shift
            when /\A--output\z/, /\A-o\z/
              @set_info.output = argv.shift
            when /\A--force\z/, /\A-f\z/
              @set_info.force = true
            when /\A--dry-run\z/, /\A-d\z/
              @set_info.dryrun = true
            when /\A--version\z/, /\A-v/
              print_version
            when /\A--help\z/, /\A-h/, /\A--./
              print_and_exit usage
            else
              @filename = arg if @filename.nil?
          end
        end
      else
        print_and_exit usage
      end
    end

    def check_args
      if @filename.nil?
        print_and_exit "Input file required"
      elsif !File.exist?(@filename)
        print_and_exit "File #@filename was not found"
      end

      @file = File.new(@filename)
      # Gets first card on the set (cards starts at the 2nd line)
      2.times{@file.gets}
      row = $_.split "\t"
      @set_info.num_cards = @file.readlines.length+1
      @file.rewind

      if row.length < 8
        print_and_exit "Input file is not a valid Lackey deck set"
      end

      # Gets the real set name from the input set definition
      @set_info.real_name = row[1]

      if @set_info.name.nil? || @set_info.name.empty?
        @set_info.name = @set_info.real_name
      end

      # Gets the set code from the set name, as an acronym
      if @set_info.code.nil?
        @set_info.code = ''
        words = @set_info.real_name.upcase.split(/_| /)
        skip_words = %w(THE AND AN A OF TO IS DECK EL LA LOS LAS DE Y)
        words.map { |w|
          next if skip_words.include? w
          @set_info.code += w[0,1]
          break if @set_info.code.length >= 3
        }

        # Code too short
        if words[-1].length > 1
          i = 1
          while @set_info.code.length < 3
            letter = words[-1][i,1]
            break if letter.nil?
            @set_info.code += letter
            i += 1
          end
        end
      end

      # Custom card colors
      unless @set_info.colors.nil?
        # "Event:#666666|Human:125,5,1"
        colors = {}
        @set_info.colors.split(';').each{ |x|
          arr = x.split(':')
          c = arr[1]
          m = /#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/i.match(c)
          unless m.nil?
            c = m[1..-1].map{|hex| hex.to_i(16) }.join(',')
          end
          colors[arr[0]] = c
        }
        @set_info.colors = colors
      end
    end

    def create_set
      # key => card name, val => UUID object
      cards = {}
      @cards_raw = ''
      now = Time.new.strftime("%Y-%m-%d %H:%M:%S")

      # Builds up the MSE2 set definition
      @file.each_with_index do |line, index|
        next if index == 0  # Skip 1st line since it contains column names
        card = Card.new(line, @set_info.colors)
        unless cards[card.name].nil?  # Skip duplicated cards
          @duplicated += 1
          next
        end
        cards[card.name] = true
        subtypes = card.subtype.map { |st|
          '<word-list-subtype>'+st+'</word-list-subtype> '
        }
        @cards_raw += <<"EOF"
card:
	has styling: false
	notes:
	time created: #{now}
	time modified: #{now}
	color: rgb(#{card.color})
	name: #{card.name}
	value: #{card.value}
	super type: <word-list-type>#{card.supertype}</word-list-type>
	sub type: #{subtypes.join('')}<word-list-subtype></word-list-subtype>
	image:
	rule text: #{card.rules}
	flavor text: <i-flavor>#{card.flavor}</i-flavor>
EOF
      end  # file.each()
    end

    def write_files
      # Write the set definition
      buffer = <<"EOF"
mse version: 2.0.0
game: generic
stylesheet: normal
set info:
	title: #{@set_info.name}
	code: #{@set_info.code}
	symbol:
#{@cards_raw}
version control:
	type: none
apprentice code:

EOF
      output_folder = ''
      output_file = ''
      if @set_info.output.nil?
        output_folder = File.dirname(@filename)
        output_file = @set_info.name
      else
        if File.directory?(@set_info.output)
          output_folder = @set_info.output
          output_file = @set_info.name
        else
          output_folder = File.dirname(@set_info.output)
          output_file = File.basename(@set_info.output)
        end
      end
      output_file.gsub!(/[^0-9A-Za-z.\-]/, '_')  # Strip Invalid Characters from filenames
      @zipname = File.join(output_folder, output_file)
      @zipname += '.mse-set' unless @zipname =~ /\.mse\-set$/
      # Overwrite file permissions
      if File.exists?(@zipname) && File.file?(@zipname)
        unless File.writable?(@zipname)
          print_and_exit "ERROR: File #{@zipname} is not writeable. Operation cancelled"
        end
        if @set_info.force.nil?
          puts "\nFile '#{@zipname}' already exists."
          puts "Do you want to overwrite it? (Y/N)"
          overwrite = $stdin.gets.chomp.downcase
          unless ["y", "yes"].include? overwrite
            print_and_exit "Operation cancelled by user"
          end
        end
      end
      # Create or overwrite set file as a ZIP file
      unless @set_info.dryrun
        begin
          Zip::File.open(@zipname, Zip::File::CREATE) do |zipfile|
            zipfile.get_output_stream('set') do |output_entry_stream|
              output_entry_stream.write buffer
            end
          end
        rescue
          print_and_exit "ERROR: Cannot create file #{@zipname}"
        end
      end
    end

    def print_version
      msg = <<EOF
Lackey_MSE2 #{VERSION}
Written by Raul Parralejo

Copyright (c) 2016 Raul Parralejo.
Released under The MIT License (MIT).
EOF
      print_and_exit msg
    end

    def print_and_exit(msg)
      puts msg
      exit 0
    end

  end  # class << self
end  # module Lackey_MSE2

if File.basename(__FILE__) == File.basename($0)
  Lackey_MSE2.init(ARGV)
end