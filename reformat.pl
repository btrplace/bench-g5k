#!/usr/bin/env perl
use strict;
print "label;id;managed;core;spe;solving;solutions;proved;kind;ratio;pct\n";
while (<>) {
	my $l = $_;
	chomp $l;
	print $l;
	my @tokens = split ';',$l;
	my $duration = $tokens[3] + $tokens[4] + $tokens[5];
	my ($kind,$ratio,$pct) = $tokens[1] =~ /\/(\w+)\/r(\d+)\/p\d+\/c(\d+)/;	
	print ";".$kind.";".$ratio.";".$pct."\n";
}
