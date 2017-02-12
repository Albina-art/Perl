package Local::Source::Memcached;
use parent 'Local::Source';

use strict;
use warnings;
use strict;
use warnings;
use mro 'c3';

use Data::Dumper;
use Cache::Memcached::Fast;
use JSON::XS;

use Class::XSAccessor {
	accessors => [qw/
		_connection
	/],
};

sub get_user {
	my ($self, $name) = @_;
	my $data = $self->connection->get($self->_site.'_user_'.$name);

	return JSON::XS->new->utf8->decode($data) if $data;
	return undef;

}

sub get_self_commentors {
	my $self = shift;
	print $self->_site.'_self_commentors',"\n";
	my $data = $self->connection->get($self->_site.'_self_commentors');

	return JSON::XS->new->utf8->decode($data) if $data;
	return undef;
}

sub set_user {
	my ($self, $data) = @_;

	return $self->connection->set(
		$self->_site.'_user_'.$data->{'username'},
		JSON::XS->new->utf8->encode($data), 60
	) if $data->{'username'};
}

sub set_self_commentors {
	my ($self, $data) = @_;
	return $self->connection->set(
		$self->_site.'_self_commentors',
		JSON::XS->new->utf8->encode($data), 60
	) if $data;
}

sub del_self_commentors {
	my $self = shift;
	return $self->connection->delete($self->_site.'_self_commentors');
}

sub _connection_start {
	my ($self, $conf) = @_;

	return Cache::Memcached::Fast->new({
		servers => [
			$conf->val('MEMACHED','mem_host').':'.$conf->val('MEMACHED','mem_port')]
	}); 
	die "Can't connection to memcached"
}

1;
