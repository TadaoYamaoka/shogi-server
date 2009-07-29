#--
# Copyright (c) 2006-2009 by Craig P Jolicoeur <cpjolicoeur at gmail dot com>
# Copyright (C) 2009 Daigo Moriwaki <daigo at debian dot org>
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

#
# This code was copied from cerberus[1] and modified.
# [1] http://rubyforge.org/projects/cerberus
#

require 'erb'

class Hash
  def deep_merge!(second)
    second.each_pair do |k,v|
      if self[k].is_a?(Hash) && second[k].is_a?(Hash)
        self[k].deep_merge!(second[k])
      else
        self[k] = second[k]
      end
    end
  end
end

class HashWithIndifferentAccess < Hash
  def initialize(constructor = {})
    if constructor.is_a?(Hash)
      super()
      update(constructor)
    else
      super(constructor)
    end
  end
 
  def default(key)
    self[key.to_s] if key.is_a?(Symbol)
  end  

  alias_method :regular_writer, :[]= unless method_defined?(:regular_writer)
  alias_method :regular_update, :update unless method_defined?(:regular_update)
  
  def []=(key, value)
    regular_writer(convert_key(key), convert_value(value))
  end

  def update(other_hash)
    other_hash.each_pair { |key, value| regular_writer(convert_key(key), convert_value(value)) }
    self
  end
  
  alias_method :merge!, :update

  def key?(key)
    super(convert_key(key))
  end

  alias_method :include?, :key?
  alias_method :has_key?, :key?
  alias_method :member?, :key?

  def fetch(key, *extras)
    super(convert_key(key), *extras)
  end

  def values_at(*indices)
    indices.collect {|key| self[convert_key(key)]}
  end

  def dup
    HashWithIndifferentAccess.new(self)
  end
  
  def merge(hash)
    self.dup.update(hash)
  end

  def delete(key)
    super(convert_key(key))
  end
    
  protected
    def convert_key(key)
      key.kind_of?(Symbol) ? key.to_s : key
    end
    def convert_value(value)
      value.is_a?(Hash) ? HashWithIndifferentAccess.new(value) : value
    end
end


module ShogiServer
  class Config
    FILENAME = 'shogi-server.yaml'

    def initialize(options = {})
      @config = HashWithIndifferentAccess.new
      
      if options.is_a?(Hash)
        options[:topdir] ||= $topdir if $topdir
        options[:topdir] ||= options["topdir"] if options["topdir"]
      end

      if options[:topdir] && File.exist?(File.join(options[:topdir], FILENAME))
        merge!(YAML.load(ERB.new(IO.read(File.join(options[:topdir], FILENAME)).result)))
      end

      merge!(options)
    end

    def [](*path)
      c = @config
      path.each{|p|
        c = c[p]
        return if c.nil?
      }
      c
    end

    def merge!(hash, overwrite = true)
      return unless hash && !hash.empty?
      if overwrite
        @config.deep_merge!(hash)
      else
        d = HashWithIndifferentAccess.new(hash)
        d.deep_merge!(@config)
        @config = d
      end
    end

    def inspect
      @config.inspect
    end

    private
    def symbolize_hash(hash)
      hash.each_pair{|k,v|
        if v === Hash
          hash[k] = HashWithIndifferentAccess.new(symbolize_hash(v))
        end
      }
    end
  end
end # module ShogiServer
