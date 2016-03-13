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

module Lackey_MSE2
  class Card

    attr_reader :name, :supertype, :type, :subtype, :value, :rules, :flavor, :creator

    def initialize(raw, colors=nil)
      # Lackey columns:
      # 0:Name  1:Set  2:ImageFile  3:Type  4:CornerValue  5:Text  6:FlavorText  7:Creator
      raw = raw.split "\t"  # Split by tab char
      type = raw[3].split(/\s\-|\+\s/)

      @name = raw[0].strip
      @supertype = type[0].strip
      @subtype = type.length > 1 ? type[1..-1].map{|x| x.strip} : []
      @type = @supertype + (@subtype.empty? ? '' : ' - '+@subtype.join(' '))
      @value = raw[4].strip
      @rules = raw[5].strip
      @flavor = raw[6].nil? ? '' : raw[6].strip
      @creator = raw[7].nil? ? '' : raw[7].rstrip
      @color = nil
      unless colors.nil?
        if colors[@subtype[0]]
           @color = colors[@subtype[0]]
        elsif colors[@supertype]
           @color = colors[@supertype]
        end
      end
    end

    def thing?
      /thing|objeto/i.match(@supertype) != nil
    end

    def action?
      /action|acción/i.match(@supertype) != nil
    end

    def reaction?
      /reaction|reacción/i.match(@supertype) != nil
    end

    def color
      return @color unless @color.nil?
      if thing?
        "34,103,206"
      elsif action?
        "140,0,0"
      else
        "29,129,86"
      end
    end

  end  # class Card
end  # module Lackey_MSE2