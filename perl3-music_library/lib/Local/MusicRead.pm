package Local::MusicRead;
use Local::MusicPath;
use strict;
use warnings;
use Getopt::Long;
use Exporter 'import';
use DDP;
our @EXPORT = qw/func_commline parsing_stdin readtext/;

sub func_commline {
    my %commline;
    my @post = @path_file;
    my $sort_elem;
    GetOptions (
        'band=s' => \$commline{'band'}, 'year=i' => \$commline{'year'},
        'album=s' => \$commline{'album'}, 'track=s' => \$commline{'track'},
        'format=s' => \$commline{'format'}, 'sort=s' => \$commline{'sort'},
        'columns=s' => \$commline{'columns'}
    );
    if( defined $commline{'columns'} ) {
        @post = split ',', $commline{'columns'};
        $commline{'columns'} = \@post;
    }
    return %commline;
}
sub parsing_stdin{
    my @pars = grep {$_} split /[.\/]/,$_;
    my @year_album = split /\s-\s/, $pars[1];
    @pars = ($pars[0], @year_album, @pars[2..$#pars]);
    return @pars; 
}
sub readtext{
    my %commline = %{shift()};
    my @a_stdin = @{shift()};
    for ( @path_file ) {
        if( defined $commline{$_} ) {
            if($_ eq 'year') {
                return 0 if ( $a_stdin[key_path $_] != $commline{$_} )
            }
            else {
                return 0 if ( $a_stdin[key_path $_] ne $commline{$_} )
            }
        }
    }
    return 1;
}
our $VERSION = '1.00';

1;
