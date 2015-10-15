#!/usr/bin/env ruby
require 'rubygems'
require 'bio'
require './midifile.rb'

if ARGV[0].end_with?(".fa",".fasta")
  file = Bio::FastaFormat.open(ARGV.shift)
  type = "fasta"
  print "this is a fasta file"
elsif ARGV[0].end_with?(".ape",".gbk")
  file = Bio::GenBank.open(ARGV.shift)
  type = "genbank"
  print "this is a genbank file"
end

# -- This part was shamelessly taken from the chords example from Pete Goodeve's Midifile scripts and modified a bit --
## First create a midifile object to be filled with data:
out = Midifile.new
## These two setup commands are required for a new midifile:
out.format = 1	# use multitrack format (for fun...)
out.division = 480	# this value (tichs/beat) is arbitrary but convenient
out.add ev = genTempo(0)	# set default tempo of 500000 micros/beat (120 BPM)

## These settings are optional, included for illustration:
MidiEvent.deltaTicks=true	# we will use absolute tick counts rather than deltas -- NOT, changing to deltas
MidiEvent.track=nil	# the track of a a channel event is got from its channel

## more not-strictly-necessary events:
out.add genTimeSignature(0, 3, 8)	# "3/8" time at 0 ticks (not meaningful here)
out.add genKeySignature(0, 2, 1)	# "2 sharps, minor" (again, nonsense here)
out.add genText(10, LYRIC, '## Jenova DNA MIDI player... ## ')	# Yeah, well...
out.add genProgramChange(0, 36)	# Set default channel to instrument 1 piano, 10 glockenspiel, 14 xylophone, 20 organ
out.add genProgramChange(0, 5, 2)	# Set channels 2 & 3 the same

#out.add genProgramChange(0, 1, 3)# End of rip


## Function for assigning notes to different nucleotides
def gen_note(nucleotide)
  if nucleotide == "a"
    note = 22
  elsif nucleotide == "c"
    note = 27
  elsif nucleotide == "t"
    note = 34
  elsif nucleotide == "g"
    note = 39
  else
    note = 127
  end

# Make it less mechanic
  x = rand 3
  note = note + x

# Send note
  return note
# End get_note()
end

def gen_note_aa(aa)
  if aa == "G"
    note = 36
  elsif aa == "P"
    note = 38
  elsif aa == "A"
    note = 40
  elsif aa == "V"
    note = 41
  elsif aa == "L"
    note = 43
  elsif aa == "I"
    note = 45
  elsif aa == "M"
    note = 47
  elsif aa == "C"
    note = 48
  elsif aa == "F"
    note = 50
  elsif aa == "Y"
    note = 52
  elsif aa == "W"
    note = 53
  elsif aa == "H"
    note = 55
  elsif aa == "K"
    note = 57
  elsif aa == "R"
    note = 59
  elsif aa == "Q"
    note = 60
  elsif aa == "N"
    note = 62
  elsif aa == "E"
    note = 64
  elsif aa == "D"
    note = 65
  elsif aa == "S"
    note = 67
  elsif aa == "T"
    note = 69
  else
    note = 127
  end
return note
end

## For each sequence in fasta do
file.each do |sequence|
  out.add genText(10, LYRIC, sequence.entry_id)	# Yeah, well...

# Transform to lowercase to compare strings
  s = sequence.seq.downcase

# Until the end of sequence
  until s.length == 0 do
# Search for motifs

# See if bases are repeated and score them
    i = 0
    counter = 1
    while s[i] == s[i+1] do
      counter += 1
      i += 1
    end
# Throw away scored 5' nucleotides
    nucl = s.slice!(0..counter-1)

# Get note for current base(s)
    note = gen_note(nucl[0])

# Set strength for base(s)
    strength = 40 + counter * 15

# Limit strength to catch error
    if strength > 100
      strength = 100
    end

# Set length of note respect to score and "silence gap"
    length = counter * 100
    silence = 5

## Write note - Also modified from Pete Goodeve's chords script.
    out.add genNoteOn(silence, note, strength)	# Middle-C on default chan 1 (and hence track 1)
    out.add genNoteOff(length, note)	# off again 350 ticks later (no vel -- default chan)
  end

  unless type == "fasta"
# Lets do CDS track if available
# Transform to lowercase to compare strings
    a = sequence.seq.downcase

    sequence.each_cds do |cds|
      data = cds.position.split('(')
      if data[0] == "complement"
        data[1] = data[1].delete(')')
        range = data[1].split('..').map{|d| Integer(d)}
        puts "complement"
      else
        range = data[0].split('..').map{|d| Integer(d)}
      end
      cds = a[range[0]-1..range[1]-1].translate
      offset = 100 * (range[0]-1)
      # Offset for channel 2 for position in sequence
      out.add genNoteOn(0, 1, 0, 2)	# Delta, note, strength and channel
      out.add genNoteOff(offset, 1, 0 , 2)	#

      # Until the end of sequence
      until cds.length == 0 do
        # See if bases are repeated and score them
          i = 0
          counter = 1
          while cds[i] == cds[i+1] do
            counter += 1
            i += 1
          end

      # Throw away scored 5' nucleotides
          aa = cds.slice!(0..counter-1)

      # Get note for current base(s)
          note = gen_note_aa(aa[0])

      # Set strength for base(s)
          strength = 40 + counter * 15

      # Limit strength to catch error
          if strength > 100
            strength = 100
          end

      # Set length of note respect to score and "silence gap"
          length = counter * 100 * 3
          silence = 5

      ## Write note - Also modified from Pete Goodeve's chords script.
          out.add genNoteOn(silence, note, strength, 2)	# Middle-C on default chan 1 (and hence track 1)
          out.add genNoteOff(length, note, 0 , 2)	# off again 350 ticks later (no vel -- default chan)
        end
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
      puts cds.qualifiers[0].qualifier+':'+cds.qualifiers[0].value
      puts a[range[0]-1..range[1]-1].translate

    end
  end
end

## ...and write out the file:
open("out.mid","w") {|fw|  out.to_stream(fw) if out.vet()}
