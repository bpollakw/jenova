# genova
Experimental DNA to MIDI encoder writen in my very primitive ruby

# Warning
Hang in there, I'm just getting started with this git stuff so probably everything might be a bit of a mess.

# Dependencies
Ruby 1.9

Bioruby (gem install bio)

Midifile by Pete Goodeve (http://www.goodeveca.net/midifile_rb/). It only works if you have it in the directory

Timidity (http://timidity.sourceforge.net)

A DNA sequence in fasta format or genbank/ape format (with extensions so that the script can recognize it)

# Usage
ruby dna_to_midi.rb seq.fa or seq.ape

timidity out.mid

#License
The MIT License (MIT) - Copyright (c) 2015 bpollakw
