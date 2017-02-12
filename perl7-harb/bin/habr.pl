#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

use FindBin '$Bin';
use lib "$Bin/../lib";
use Local::Habr;

use feature 'say';
my $inquiry = $ARGV[0];
my $format;
my $refresh;
my $site;
my %params;

GetOptions(
	'name=s' => \$params{'name'},
	'post=i' => \$params{'post'},
	'id=s' => \$params{'id'},
	'n=i' => \$params{'n'},
	'refresh' => \$refresh,
	'format=s' => \$format,
	'site=s' => \$site,
);

my $habr = Local::Habr->new(
	'inquiry' => $inquiry,
	'params' => \%params,
	'refresh' => $refresh,
	'format' => $format,
	'site' => $site,
);

say $habr->get;