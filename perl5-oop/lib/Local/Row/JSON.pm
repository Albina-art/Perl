package Local::Row::JSON;
	use strict;
	use warnings;
	use parent 'Local::Row';
	use JSON::XS;	
	# use DDP;
	sub _get {
		my $self = shift;
		my $tmp = JSON::XS->new->utf8->decode($self->{str});
		return $tmp;
	}

1;