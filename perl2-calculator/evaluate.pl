=head1 DESCRIPTION

Эта функция должна принять на вход ссылку на массив, который представляет из себя обратную польскую нотацию,
а на выходе вернуть вычисленное выражение

=cut

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
sub evaluate {
	my $rpn = shift;
	my $result;
	my @out = @$rpn; 
	my @res;
	my $i;
	my $b;
	my $c;
	if ( $#out < 2 ) {
		$result = $out[0] if ( $out[0] =~ /\d/ );
		if ( $#out == 1 ) {
			$result = -1 * $result if ( $out[1] =~ /U\-/ );
		}
	}
	else {
		for ($i = 0; $i < $#out + 1; $i++) {
			given ( $out[$i] ) {
			when ( /U\+/ ) { }
				when( /U\-/ ) {
					if ( $i < $#out ) {
						$i++ if ( $out[$i + 1] =~ /U\+/ );
					}
					push (@res,  -1 * pop (@res));
				}
				when ( /\d/ ) {
					push (@res, $out[$i]);
				}
				when( /[-+*^\/]/ ) {
					$c = pop (@res); 
					$b = pop (@res);
					given ( $out[$i] ) { 
						when ('+') { $result = $b + $c; }
						when ('-') { $result = $b - $c; }
						when ('*') { $result = $b * $c; }
						when ('/') { $result = $b / $c; }
						when ('^') { $result = $b ** $c; }
 					}
					push (@res, $result);
				}
			}
		}
	}
	return $result;
}

1;
