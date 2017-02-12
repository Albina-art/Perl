package Local::Row;
	use strict;
	use warnings;
	use strict;

	sub new {
		my ($class, %params) = @_;
		my $self = bless \%params, $class;
		return $self;
	}
	sub get {
		my ($self, $key) = @_;
		$self->{pars} = $self->_get unless $self->{pars};
		return $self->{pars}->{$key};
	}
1;