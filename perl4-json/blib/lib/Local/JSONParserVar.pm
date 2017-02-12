package Local::JSONParserVar; 
use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw/$string $structure/;
our $string = qr{
	(?|
   		(?<as_is>[^"\\]++) # что угодно, кроме кавычки и \
   		|
   		\\                 # или \, после которого идёт:
   		(?:
      		(?<as_is>["\\]) # простая подстановка заэкранированных
      		|
      		(?<escape>[ntb]) # один из этих символов -> \n, \t, \b ...
      		|
      		u(?<char>[\da-f]{4}) # символ \u
   		)
	)
}xi;
our $structure = qr{
	\s*(?: # учёт пробелов вначале 
       	'(?<error>)' #учитываем ошибку  
       	|
       	\[ (?<array>.*) \] # массив
  		|
  		\{(?<hash>.*)\}
  		|                
  		(?<str>"$string*") # строка
  		|
 		(?<numb>([+-]?\d*\.)*(\d+[eE])*[+-]?\d+) # число
	)\s* # учёт пробелов в конце
}xis;
1;