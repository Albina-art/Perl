package Local::Row::Simple;
	use strict;
	use warnings;
	use parent 'Local::Row';

	sub get {
		my ($self, $key) = @_;
		my @arr = split ',', $self->{str};
		for (@arr) {
			return $2
			if ( /^\s*(.+)\s*:\s*(.+)\s*$/ and $1 eq $key );
		}
		die "error Simple : ,";
	}

1;
