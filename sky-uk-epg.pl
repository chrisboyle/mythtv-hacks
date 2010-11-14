#!/usr/bin/perl
use strict;

###
### Chris Boyle's dodgy wikipedia-to-xmltv hack
###

# You must first run tv_grab_uk_rt --configure (once, just as far as the
# channel questions then you can ctrl-C).

# Then fetch wikipedia's "List of channels on Sky" and all subarticles, with
# ?action=raw into the current dir, with filenames matching their article
# names (TODO: script that, with cache).

# Then edit this script as necessary.

# Then run this script, into a file. You might get something you can append
# to ~/.xmltv/tv_grab_uk_rt.conf (or it might fail horribly).

# Name of the article on Wikipedia, and filename prefix
my $article = 'List_of_channels_on_Sky';
# e.g. Wales
my @variations = qw(  );
# Encryption/Package column must contain one of these
my @packages = qw( free knowledge variety );
# Sub-articles (headings) to exclude e.g. International (the subset I have
# seems to be all in non-EU languages, none of which I speak; if you add the
# Style & Culture Pack then TV5MONDE Europe becomes the exception).
my @excludesections = qw( adult box gaming international religious shopping );
# Exclude channels whose notes mention this
my @excludenotes = qw( premises );
# Include HDTV channels?
my $includehd = 0;
# Include Radio (audio-only) channels?
my $includeradio = 0;

# Wikipedia name => XMLTV name
# TODO import tv_grab_uk_rt's postcode selection
my %hackyfixups = (
	"BBC One" => "BBC One East (W)",
	"BBC One East (W)" => undef, # skip: unavailable on 982 because it's on 101
	"BBC Two" => "BBC Two England",
	"ITV" => "ITV1 Anglia",
	"Channel One" => "Channel One (Satellite/Cable)",
	"Channel One +1" => "Channel One +1 (Satellite/Cable)",
	"True Movies 1" => "True Movies",
	"Community Channel" => "Community Channel (Satellite/Cable)",
	"CBBC Channel" => "CBBC",
);

my %cids;
open(CIDS,"<$ENV{HOME}/.xmltv/supplement/tv_grab_uk_rt/channel_ids") or die $!;
while(<CIDS>) {
	my @c = split /\|/;
	my( $id, $name ) = @c[0,2];
	$cids{$name} = $id;
}
close(CIDS);

my %subs;

for my $fragment (glob("$article*")) {
	(my $section) = $fragment;
	$section =~ s/^\Q$article\E[\W_]*//;
	next if grep { $section =~ /\Q$_\E/i } @excludesections;
	open(FRAG,"<$fragment") or die $!;
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
		my( $epg, $name, $notes, $package, $format ) = @c[1,2,3,6,7];
		next if( $format =~ /HD/ && ! $includehd );
		next unless (grep { $package =~ /\Q$_\E/i } @packages) || $isradio;
		next if grep { $notes =~ /\Q$_\E/i } @excludenotes;
		$name =~ s/^\[\[(?:[^|]+\|)?\s*([^\]]+?)\s*\]\].*/\1/;
		if( $subs{$epg} ) {
			warn "$epg: Overwriting '$subs{$epg}' with '$name'\n";
		}
		$subs{$epg} = $name;
	}
}

for my $epg ( sort keys %subs ) {
	#print "$epg\t$subs{$epg}\n";
	my $name = $subs{$epg};
	for my $h ( keys %hackyfixups ) {
		if( $name eq $h ) { $name = $hackyfixups{$h}; last; }
	}
	next unless $name;
	my $id = $cids{$name};
	if( $id ) {
		print "# $epg $name\n";
		print "channel=$id\n";
	} else {
		print "# $epg $name - not found!\n";
	}
}
