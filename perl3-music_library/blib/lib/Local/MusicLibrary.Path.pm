package Local::MusicLibrary::Path;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw/key_path @path_file/;
our @path_file = ('band', 'year', 'album', 'track', 'format');

sub key_path {
    my $name = shift;
    for (0..$#path_file) {
       return $_ if ($name eq $path_file[$_]);
    }
    return -1;
}