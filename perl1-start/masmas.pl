use strict;
use warnings;
use DDP;
use Data::Dumper;
my @array;
my $res;
while ( <STDIN> ){
    chomp();
    push(@array,[split /;\s*/, $_]);
}
$res = \@array;
p $res;
#print Dumper (\@array);
