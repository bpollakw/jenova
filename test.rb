#!/usr/bin/env ruby
require 'rubygems'
require 'bio'
require './midifile.rb'

file = Bio::GenBank.open(ARGV.shift)
type = "genbank"

file.each do |sequence|
  a = sequence.seq

  sequence.each_gene do |gene|
    data = gene.position.split('(')
    if data[0] == "complement"
      data[1] = data[1].delete(')')
      range = data[1].split('..').map{|d| Integer(d)}
      puts "complement"
    else
      range = data[0].split('..').map{|d| Integer(d)}
    end
    puts range[0]..range[1]
    puts gene.qualifiers[0].qualifier+':'+gene.qualifiers[0].value
    puts a[range[0]-1..range[1]-1].translate
  end


    sequence.each_cds do |cds|
      data = cds.position.split('(')
      if data[0] == "complement"
        data[1] = data[1].delete(')')
        range = data[1].split('..').map{|d| Integer(d)}
        puts "complement"
      else
        range = data[0].split('..').map{|d| Integer(d)}
      end
      puts range[0]..range[1]
      puts cds.qualifiers[0].qualifier+':'+cds.qualifiers[0].value
      puts a[range[0]-1..range[1]-1].translate
    #ends = cds.position.split('..').map{|d| Integer(d)}
    end

end
