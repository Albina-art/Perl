package Local::Source::Array; 
	use strict;
	use warnings;
	use parent 'Local::Source';

	sub start {
		my $self = shift;
		$self->{counter} = 0;
		return $self;
	}

1;