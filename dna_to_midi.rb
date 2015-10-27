#!/usr/bin/env ruby
require 'rubygems'
require 'bio'
require './midifile.rb'

if ARGV[0].end_with?(".fa",".fasta")
  file = Bio::FastaFormat.open(ARGV.shift)
  type = "fasta"
elsif ARGV[0].end_with?(".ape",".gbk")
  file = Bio::GenBank.open(ARGV.shift)
  type = "genbank"
end

# -- This part was shamelessly taken from the chords example from Pete Goodeve's Midifile scripts and modified a bit --
## First create a midifile object to be filled with data:
out = Midifile.new
## These two setup commands are required for a new midifile:
out.format = 1	# use multitrack format (for fun...)
out.division = 480	# this value (tichs/beat) is arbitrary but convenient
out.add ev = genTempo(0)	# set default tempo of 500000 micros/beat (120 BPM)

## These settings are optional, included for illustration:
MidiEvent.deltaTicks=false	# we will use absolute tick counts rather than deltas
MidiEvent.track=nil	# the track of a a channel event is got from its channel

## more not-strictly-necessary events:
out.add genTimeSignature(0, 3, 8)	# "3/8" time at 0 ticks (not meaningful here)
out.add genKeySignature(0, 2, 1)	# "2 sharps, minor" (again, nonsense here)
out.add genText(10, LYRIC, '## Jenova DNA MIDI player... ## ')	# Yeah, well...

# Set instruments
out.add genProgramChange(0, 36)	# Set default channel 1 to bass
out.add genProgramChange(0, 116, 2)	# Set channel 2 to wood block
out.add genProgramChange(0, 10, 3)	# Set channel 3 glockenspiel
#out.add genProgramChange(0, 1, 3)# End of rip


## Function for assigning notes to different nucleotides
def gen_note(nucleotide)
  if nucleotide == "a"
    note = 23
  elsif nucleotide == "c"
    note = 28
  elsif nucleotide == "t"
    note = 35
  elsif nucleotide == "g"
    note = 40
  else
    note = 127
  end

# Make it less mechanic
  x = rand (0..1)
  note = note + x

# Send note
  return note
# End get_note()
end

def gen_note_aa(aa)
  if aa == "E"
    note = 18
  elsif aa == "D"
    note = 20
  elsif aa == "C"
    note = 22
  elsif aa == "N"
    note = 23
  elsif aa == "F"
    note = 25
  elsif aa == "T"
    note = 27
  elsif aa == "Q"
    note = 29
  elsif aa == "Y"
    note = 30
  elsif aa == "S"
    note = 32
  elsif aa == "M"
    note = 34
  elsif aa == "W"
    note = 35
  elsif aa == "I"
    note = 37
  elsif aa == "V"
    note = 39
  elsif aa == "G"
    note = 41
  elsif aa == "L"
    note = 42
  elsif aa == "A"
    note = 44
  elsif aa == "P"
    note = 46
  elsif aa == "H"
    note = 47
  elsif aa == "K"
    note = 49
  elsif aa == "R"
    note = 51
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
  # initialize pos
  pos = 0
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
    strength = 60 + counter * 15

# Limit strength to catch error
    if strength > 100
      strength = 100
    end

# Set length of note respect to score and "silence gap"
    length = counter * 100
    silence = 5

## Write note - Also modified from Pete Goodeve's chords script.
    out.add genNoteOn(pos+silence, note, strength)	# Middle-C on default chan 1 (and hence track 1)
    out.add genNoteOff(pos+length, note)	# off again 350 ticks later (no vel -- default chan)
    # update pos
    pos = pos + length
  end

# Only features for genebank format
  unless type == "fasta"

# Transform to lowercase to compare strings
    a = sequence.seq.downcase

# Lets do CDS track
    sequence.each_cds do |cds|
      data = cds.position.delete(">").split('(')
      if data[0] == "complement"
        data[1] = data[1].delete(")")
        range = data[1].split('..').map{|d| Integer(d)}
      else
        range = data[0].split('..').map{|d| Integer(d)}
      end

      # Find position in sequence, assign cds and translate into protein
      cds = a[range[0]-1..range[1]-1].translate
      pos = (range[0]-1) * 100 * 3

      # Until the end of sequence
      until cds.length == 0 do
          # See if bases are repeated and score them
          i = 0
          counter = 1
          while cds[i] == cds[i+1] do
            counter += 1
            i += 1
          end

      # Throw away scored 5' aa
          aa = cds.slice!(0..counter-1)

      # Get note for current aa(s)
          note = gen_note_aa(aa[0])

      # Set strength for aa(s)
          strength = 40 + counter * 15

      # Limit strength to catch error
          if strength > 100
            strength = 100
          end

      # Set length of note respect to score and "silence gap" * 3 due to translation
          length = counter * 100 * 3
          silence = 5

      ## Write note - Also modified from Pete Goodeve's chords script.
          out.add genNoteOn(pos, note, strength, 2)	# Channel 2 specified
          out.add genNoteOff(pos+length, note, 0 , 2)	# Off for note in channel 2
          # update pos
          pos = pos + length
        end
    end

    # Same for gene
    sequence.each_gene do |gene|
      data = gene.position.delete(">").split('(')
      if data[0] == "complement"
        data[1] = data[1].delete(')')
        range = data[1].split('..').map{|d| Integer(d)}
      else
        range = data[0].split('..').map{|d| Integer(d)}
      end
      # Find position in sequence, assign gene
      gene = a[range[0]-1..range[1]-1]
      pos = (range[0]-1) * 100

      # Until the end of sequence
      until gene.length == 0 do
          # See if bases are repeated and score them
          i = 0
          counter = 1
          while gene[i] == gene[i+1] do
            counter += 1
            i += 1
          end

      # Throw away scored 5' nucleotide
          nucl = gene.slice!(0..counter-1)

      # Get note for current aa(s)
          note = gen_note(nucl[0])

      # Set strength for aa(s)
          strength = 60 + counter * 15

      # Limit strength to catch error
          if strength > 100
            strength = 100
          end

      # Set length of note respect to score and "silence gap"
          length = counter * 100

      ## Write note - Also modified from Pete Goodeve's chords script.
          out.add genNoteOn(pos+silence, note, strength, 3)	# Channel 3 specified
          out.add genNoteOff(pos+length, note, 0 , 3)	# Off for note in channel 3
        # update pos
          pos = pos + length
        # end until 0
        end
    # end each_gene
    end
  # end unless
  end
# end file
end

## ...and write out the file:
open("out.mid","w") {|fw|  out.to_stream(fw) if out.vet()}
