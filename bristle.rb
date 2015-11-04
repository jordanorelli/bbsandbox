require 'sanitize'
require 'treetop'

base_path = File.expand_path(File.dirname(__FILE__))
require File.join(base_path, 'bristlecode_nodes.rb')

class Bristle
  Treetop.load(File.join(File.expand_path(File.dirname(__FILE__)), 'bristlecode_parser.treetop'))
  @@parser = BristlecodeParser.new

  def self.parse(doc)
    tree = @@parser.parse(doc)
    if tree.nil?
      raise Exception, "Bristlecode parse error at offset: #{@@parser.index}"
    end
    tree
  end
end
