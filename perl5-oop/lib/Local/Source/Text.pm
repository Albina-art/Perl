package Local::Source::Text;
	use strict;
	use warnings;
	use parent 'Local::Source';

	sub start {
		my $self = shift;
		$self->{counter} = 0;
		my $delimiter = defined $self->{delimiter} ?
		$self->{delimiter} : "\n";
		$self->{text} = [split $delimiter, 
		$self->{text}];
		return $self;
	}

1;
