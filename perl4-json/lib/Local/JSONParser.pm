package Local::JSONParser;
use Local::JSONParserVar;
use DDP;
use feature qw(say);
use strict;
use warnings;
use utf8;
use Encode; 
use Exporter 'import';
our @EXPORT = qw/string_func rec parse_json/;
sub parse_json {
	$_ = shift;
    die if /^[{}[\]]$/; # { или } ,или [ ,или ] 
    return {} if /^{\s*}$/; # { }
    return [] if /^\[\s*]$/; # [ ]
    if ( m{^($structure)$} ) {
		die if $+{error};
		die if $+{numb};
	}
	return rec($_); # иначе реккурсивный разбор строки
}
sub string_func {
	my %convert_escape = (n => "\n", t => "\t", b => "\b" );
	$_ = shift;
	if (/
		^\s*" 
			(
				$string*  
			) 
		"\s*$
		/x) {
		$_ = $1;
		s/\G($string)/ 		
			defined $+{ as_is } ? decode('utf8',$+{ as_is }) :
			$+{ escape } ? $convert_escape{ $+{ escape} } :
			chr(hex($+{char}))
		/xige or die; 
	} 
	return $_;
}
sub rec {
	my $rt;
	my $elem;
	my @resa;
	my $hash_struc;
	my $arr_struc;  
	my $position; 
	my $special_variable; 
	$_ = shift;
	if ( m{^($structure)$} ) {
		my $fl = 0; # флаг, если fl = 1 - массив, 
					# если fl = 2 - хеш
		if ( $+{array} ) {
			$fl = 1;
			$special_variable = $+{array};
		}
		if ( $+{hash} ) {
			$fl = 2;
			$special_variable = $+{hash};
		}
		return string_func($+{str}) if $+{str};
		return 0 + $+{numb} if $+{numb};
		$_= $special_variable;
		while (/\G($structure)/gsc and pos($_) <= length($_)) {
			$elem = {} if /{\s*}/; # пустой массив
			$elem = [] if /\[\s*\]/; # пустой хеш
			die if ( /^[{}[\]]$/ ); 
    		die if ( /^\s*\[.*[^\]]\s*$/);
			$position = pos; # запомним позицию на которогой находится $_
			$special_variable = $_; # запомним $_
			$elem = 
				defined $+{str} ? # если структура строка
				# вызываем функцию преобразования строки
				string_func($+{str}) :
				defined $+{numb} ? # если структура число
				# прибавляем к нему 0, чтобы преобразовать число
				0 + $+{numb} : {};
    		if ($+{array}) { # учитываем сложные структуры
    			$arr_struc = $+{array};
				if($arr_struc =~ m{
						^(
							[^\[\]]+
						)
						\],\[
					}x) {
					$position = $position - length ($arr_struc) + length($1);
					$elem = rec('['.$1.']');
    			}
    			else {
    				$elem =rec('['.$+{array}.']');
    			}
    		}
    		if ($+{hash}) {
    			$hash_struc = $+{hash};
				if($hash_struc  =~ m{
						^(
							[^\{\}]+
						)
						\},\{
					}x) {
					$position = $position - length ($hash_struc) + length($1);
					$elem = rec('{'.$1.'}');
    			}
    			else {
    				$elem =rec('{'.$+{hash}.'}');
    			}
    		}
			$_= $special_variable; # вспомнили $_ 
			push @resa, $elem; # добавили элемент в результирующий массив
			pos = $position;
			if($fl == 1 and pos($_) < length ){
				die unless(/\G,/);
			}
			pos = $position + 1;
		}					
		return \@resa if $fl == 1;
		die unless($#resa & 1);
		my %resh = @resa;
		return \%resh;
	}
	else { die; }
}
1;