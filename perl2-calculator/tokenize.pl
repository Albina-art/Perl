use 5.010;
use strict;
use warnings;
use diagnostics;
BEGIN{
	if ($] < 5.018) {
		package experimental;
		use warnings::register;
	}
}
no warnings 'experimental';
sub tokenize {
	chomp ( my $expr = shift );
	my @res;
	die "Bad: 'number space number $expr'" if ( $expr =~ /\d\s\d/ );
	$expr =~ s/\s//g;
	die "Bad: '. number. $expr'" if ( $expr =~ /\d\.\d\./ );
	die "Bad: 'ee $expr'" if ( $expr =~ /ee/ );	
	die "Bad: 'nothing (|) nothing $expr'" if ( $expr =~ /^[\(\)]$/ );
	die "Bad: 'nothing +|-|*|/| nothing $expr'" if ( $expr =~ /[-+*^.\/]$/ );
	die "Bad: '\+|\-|\*|\^|\/  ) $expr'" if ( $expr =~ /[-+*^\/]\)/ );
	die "Bad: 'number space number $expr'" if ( $expr =~ /[-+*^\/][\/*^]/ );
	my @o = split /(\+|\-|\*|\(|\)|\/|\^)/, $expr;
	@o = grep /^.+$/, @o;
	$expr = $o[0];
    	my $i = 0;
	while ( $i < $#o + 1 ) {
		given ( $expr ) {
			when ( /\d(e)/ ) {
				$i++;
				if ($i < $#o + 1 and $o[$i] =~ /[+-]/) {
					$expr = join ( '', $expr, $o[$i], $o[$i + 1] );
					$i++;
				}
				$expr = 0 + $expr;
			} 
			when ( /\./ ) {
				$expr = 0 + $expr;		
			}
			when ( /[+-]/ ) {
				if ($i == 0) {
					$expr = "U$expr";
				}
				elsif ( $o[$i - 1] =~ /[\(^*]/ or $o[$i - 1] =~ /[U+U-]/ ) {
					$expr = "U$expr";
				}
				else {
					if ( $o[$i + 1] =~ /[+-]/ and $i < $#o + 2 ) {
						push (@res, $expr);
						$expr = "U$o[$i + 1]";
						$i++;
					}
				}
			}
		}
		$i++;
		push (@res, $expr);
		$expr = $o[$i];
    }
   	return \@res;
}
1;
