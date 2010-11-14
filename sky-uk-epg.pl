#!/usr/bin/perl
use strict;

# Name of the article on Wikipedia
my $article = 'List_of_channels_on_Sky';
# e.g. Wales
my @variations = qw(  );
# Encryption/Package column must contain one of these
my @allowchannels = qw( free knowledge variety );
# Sub-articles (headings) to exclude e.g. International (the subset I have
# seems to be all in non-EU languages, none of which I speak; if you add the
# Style & Culture Pack then TV5MONDE Europe becomes the exception).
my @excludesections = qw( adult box gaming international religious shopping );
# Exclude channels whose notes mention this
my @excludenotes = qw( premises );
# Include Radio (audio-only) channels
my $includeradio = 0;

my %channels;

for my $fragment (glob("$article*")) {
	(my $section) = $fragment;
	$section =~ s/^\Q$article\E[\W_]*//;
	next if grep { $section =~ /\Q$_\E/i } @excludesections;
	open(FRAG,$fragment) or die $!;
	$_ = join('',<FRAG>);
	close(FRAG);
	my $ignoring = 0;
	for (split /\|[-}]/) {
		if ( /variations/i ) {
			my $v = $_;
			$ignoring = ! scalar grep { $v =~ /\Q$_\E/i } @variations;
		}
		next if $ignoring;
		my @c = map { s/^\|(?:\s*bgcolor=[^|]+\|)?\s*(.*?)\s*/\1/; $_ } split /\n/;
		my $isradio = ( $c[1] =~ /^0\d{3}$/ );
		next unless $c[1] =~ /^\d{3}$/ || ($includeradio && $isradio);
		my( $epg, $name, $notes, $package ) = @c[1,2,3,6];
		next unless (grep { $package =~ /\Q$_\E/i } @allowchannels) || $isradio;
		next if grep { $notes =~ /\Q$_\E/i } @excludenotes;
		$name =~ s/^\[\[(?:[^|]+\|)?\s*([^\]]+?)\s*\]\].*/\1/;
		if( $channels{$epg} ) {
			warn "$epg: Overwriting '$channels{$epg}' with '$name'\n";
		}
		$channels{$epg} = $name;
	}
}

for my $epg ( sort keys %channels ) {
	print "$epg\t$channels{$epg}\n";
}
