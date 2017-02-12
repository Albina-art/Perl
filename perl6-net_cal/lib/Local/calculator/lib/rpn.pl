=head1 DESCRIPTION

Эта функция должна принять на вход арифметическое выражение,
а на выходе дать ссылку на массив, содержащий обратную польскую нотацию
Один элемент массива - это число или арифметическая операция
В случае ошибки функция должна вызывать die с сообщением об ошибке

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
use FindBin;
require "$FindBin::Bin/../lib/tokenize.pl";

sub rpn {
my $expr = shift;
	my $source = tokenize($expr);
	my @stack;
	my $prev_prior;
	my $next_prior;
	my $next_assoc;
	my $value;
	my $flag;
	my @rpn;
	my $lastop;
	my $bracket;
	my @o = @$source;
	my %prior = (
    	")"  => { prior => 0 },
    	"("  => { prior => 0 },
    	"U-" => { prior => 4, assoc => "right" },
    	"U+" => { prior => 4, assoc => "right" },
    	"^"  => { prior => 4, assoc => "right" },
    	"*"  => { prior => 2, assoc => "left" },
    	"/"  => { prior => 2, assoc => "left" },
    	"+"  => { prior => 1, assoc => "left" },
    	"-"  => { prior => 1, assoc => "left" },
	);
	for $value (@o) {
		if ( $value =~ /[-+*^\/]/ ) {
			$flag = 0; 
			while ( $flag == 0 ) {   
				if ( !($stack[0]) ) {
						$stack[0] = $value;
						$flag = 1;
					}
					else {
						$lastop = pop (@stack);
						$next_prior = $prior{ $value }{ prior };
						$next_assoc = $prior{ $value }{ assoc };
						$prev_prior = $prior{ $lastop }{ prior};
						if ( $next_assoc eq "left" ) {
							if ( $next_prior > $prev_prior ) {
								push (@stack, $lastop);
								push (@stack, $value);
								$flag = 1;
							}	
							push (@rpn, $lastop) if ( $next_prior <= $prev_prior );
						}
						else {
							if ( $next_prior >= $prev_prior ) {
								push (@stack, $lastop);
								push (@stack, $value);
								$flag = 1; 
							}
							push (@rpn, $lastop) if ( $next_prior < $prev_prior );			
						}
					}
				} 
			}
		elsif ( $value =~ /\d/ ) {
			push (@rpn, $value);
		} 
		elsif ( $value eq '(' ) {
			push (@stack, $value); 
		}			
		elsif ( $value eq ')' ) {
			$bracket = 0;
			while ($bracket == 0) {
				if ($stack[0]) {
					$expr = pop (@stack);
					if ( $expr eq '(' ) { $bracket = 1; } 
					else { push (@rpn, $expr); }
				}
				else { die "Bad: 'not exist ('"; }
			}
		}	
	}
	while ( $value = pop (@stack) ) {
		die "Bad:'not exist )'" if ( $value eq '(' );
		push (@rpn, $value);
	}
	return \@rpn;
}

1;
