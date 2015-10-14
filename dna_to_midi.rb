#!/usr/bin/env ruby
require 'rubygems'
require 'bio'
require './midifile.rb'

# -- This part was shamelessly taken from the chords example from Pete Goodeve's Midifile scripts and modified a bit --
## First create a midifile object to be filled with data:
out = Midifile.new
## These two setup commands are required for a new midifile:
out.format = 1	# use multitrack format (for fun...)
out.division = 240	# this value (tichs/beat) is arbitrary but convenient
out.add ev = genTempo(0)	# set default tempo of 500000 micros/beat (120 BPM)

## These settings are optional, included for illustration:
MidiEvent.deltaTicks=true	# we will use absolute tick counts rather than deltas -- NOT, changing to deltas
MidiEvent.track=nil	# the track of a a channel event is got from its channel

## more not-strictly-necessary events:
out.add genTimeSignature(0, 3, 8)	# "3/8" time at 0 ticks (not meaningful here)
out.add genKeySignature(0, 2, 1)	# "2 sharps, minor" (again, nonsense here)
out.add genText(10, LYRIC, "## Genova DNA MIDI player... ##")	# Yeah, well...
out.add genProgramChange(0, 10)	# Set default channel to instrument 1 piano, 10 glockenspiel, 14 xylophone, 20 organ
# End of rip

file = Bio::FastaFormat.open(ARGV.shift)

## Function for assigning notes to different nucleotides
def gen_note(nucleotide)
  if nucleotide == "a"
    note = 42
  elsif nucleotide == "c"
    note = 48
  elsif nucleotide == "t"
    note = 52
  elsif nucleotide == "g"
    note = 68
  else
    note = 127
  end

# Make it less mechanic
  x = rand 3
  note = note + x

# Send note
  return note
end


## For each sequence in fasta do
file.each do |sequence|
  t = sequence.seq

# Transform to lowercase to compare strings
  s = t.downcase!

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
end

## ...and write out the file:
open("out.mid","w") {|fw|  out.to_stream(fw) if out.vet()}
