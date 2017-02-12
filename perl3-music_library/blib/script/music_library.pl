#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use Local::MusicLibrary;
use Local::MusicRead;
BEGIN{
    if ($] < 5.018) {
        package experimental;
        use warnings::register;
    }
}
my @music;
my @std;
my %commline = func_commline();
while (<STDIN>) {
    chomp();
    @std = parsing_stdin $_;
    push (@music, [@std]) if (readtext \%commline, \@std);
}
draw (\@music, \%commline);