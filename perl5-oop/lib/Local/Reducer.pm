package Local::Reducer;
	use strict;
	use warnings;
	our $VERSION = '1.00';

	sub new {
		my ($class, %params) = @_;
		my $self = bless \%params, $class;
		$self->start;
		return $self;
	}

	sub start {
		my $self = shift;
		$self->{reduced} = $self->{initial_value};
	}

	sub reduce_n {
		my ($self, $n) = @_;
		
		my $tmp = $self->{row_class}->new;
		while ( $n > 0 and $tmp->{str} = $self->{source}->next ) {
	 		$n--;
	 		$tmp->{pars} = undef;
	 		$self->_reduce($tmp);
		}
		return $self->{reduced};
	}

	sub reduce_all {
		my $self = shift;
	
		my $tmp = $self->{row_class}->new;
		while ( $tmp->{str} = $self->{source}->next ) {
			$tmp->{pars} = undef;
			$self->_reduce($tmp);
		}
	
		return $self->{reduced};
	}

	sub reduced {
		my $self = shift;
		return $self->{reduced};
	}

1;

