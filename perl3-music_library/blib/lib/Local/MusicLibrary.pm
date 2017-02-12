package Local::MusicLibrary;
use Local::MusicPath;
use strict;
use warnings;
use List::Util qw(max);
use Exporter 'import';
our @EXPORT = qw/draw maxspace sortparam/;
use feature 'say';
sub maxspace {
    my @music = @{shift()};
    my %commline = %{shift()};
    my $i;
    my @len_music;
    my $colum;
    my @max;
    my @post = $commline{'columns'} ? @{$commline{'columns'}} : @path_file ;
    if (@music){
        for $i (@post) {
            @len_music = ();
            for ( 0..$#music ) {
                push( @len_music, length $music[ $_ ][key_path $i]);
            }
            push @max, max(@len_music);
        }
    }
    return @max;
}
sub sortparam {
    my $fiedl= shift;
    my @music = @{shift()};
    my @mas_sort;
    if ($fiedl eq 'year') {
        @mas_sort = sort { $a -> [key_path $fiedl] <=> 
        $b -> [key_path $fiedl]} @music;
    }
    else {
        @mas_sort = sort { $a -> [key_path $fiedl] cmp 
        $b -> [key_path $fiedl]} @music; 
    }
    return @mas_sort;
}
sub draw {
    my @music = @{shift()};
    my %commline = %{shift()}; 
    my @max = maxspace (\@music, \%commline);
    my @post = $commline{ 'columns' } ? 
    @{ $commline{ 'columns' } } : @path_file;
    my $len = $#post * 3 + 2;
    $len += $_ for @max;
    my $last = pop @post;
    my $key;
    my @mas_sort = $commline{ 'sort' } ? 
    sortparam($commline{ 'sort' }, \@music) : @music;
    my $i = 0;
    if (@max) {
        say "/", "-"x ${len}, '\\'; 
        for $key (0..$#mas_sort) {
            $i = 0;
            printf("| %${max[ $i ++ ]}s ", 
            $mas_sort[ $key ][ key_path $_ ]) for @post;
            printf( "| %${max[$i]}s |\n",
            $mas_sort[ $key ][ key_path $last ]);
            $i = 0;
            if ( $key ne $#mas_sort ) {
                print ("|");
                print ('-'x ${max[$i++]}, '--+') for @post;
                print ("-"x ${max[$i]}, '--|', "\n");
            }
            else { say '\\', "-"x ${len}, '/'; }
        }
    }
    return 0;
}
our $VERSION = '1.00';

1;