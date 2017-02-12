package Local::Source;
	use strict;
 	sub new {
 		my ($class, %params) = @_;
 		my $self = bless \%params, $class;
 		$self->start;
 		return $self;
 	}

 	sub next {
 		my $self = shift;
 		my $source = $self->{array} ? 'array':
		'text';
 		return $self->{$source}->[ $self->{counter}++ ];
 	}
	
 1;
