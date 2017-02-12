																																																																																																																																																																																																																																																																														package Local::Habr;

use strict;
use warnings;
use Local::Source::Loader;
use Local::Source::MySQL;
use Local::Source::Memcached;
use Local::Format;

use Class::XSAccessor {
	accessors => [qw/
		_inquiry _format _refresh _params _site _loader _memcached _db
	/],
};

sub new {
	my ($class, %params) = @_;
	my $self = bless {}, $class;
	$self->_inquiry ( $params{'inquiry'} );
	$self->_refresh ( $params{'refresh'} );
	$self->_params ( $params{'params'} );
	my $site = 'habrahabr';

	$site = $params{'site'}
	if $params{'site'};
	
	$self->_site ($site);	
	$self->_format ( Local::Format->new($params{'format'}));
	$self->_loader ( Local::Source::Loader->new('site'=>$self->_site));
	$self->_db ( Local::Source::MySQL->new('site'=>$self->_site));
	$self->_memcached ( Local::Source::Memcached->new('site'=>$self->_site));

	return $self;
}

sub get {
	my ($self) = @_;
	return $self->_format->get($self->_get_data);
}

sub _get_data {
	my ($self) = @_;
	my $inquiry = $self->_inquiry;
	if ($inquiry eq 'user') {
		return $self->_get_user($self->_params->{'name'})
		if($self->_params->{'name'});

		return $self->_get_user_post($self->_params->{'post'})
		if($self->_params->{'post'});
	
		die 'error arguments';
	}
	if ($inquiry eq 'commenters') {
		return $self->_get_commenters($self->_params->{'post'})->{'comments'}
		if($self->_params->{'post'});

		die 'error arguments';
	}
	if ($inquiry eq 'post') {
		return $self->_get_posts($self->_params->{'id'})
		if($self->_params->{'id'});
			
		die 'error arguments';
	}
	if ($inquiry eq 'desert_posts') {
		return $self->_get_desert_posts($self->_params->{'n'})
		if($self->_params->{'n'});
			
		die 'error arguments';
	}
	return $self->_get_self_commentors
	if ($inquiry eq 'self_commentors');
	
	die 'error arguments';
}

sub _get_user {
	my ($self, $name) = @_;
	my $result;
	my $loader = sub {
		$result = $self->_loader->get_user($name);
		die "User not found $name" unless $result;
		return $result;
	};#хотим ссылаться на эту функцию

	my $mysql = sub {
		unless ($self->_refresh){
		$result = $self->_db->get_user($name);	
		}
		unless($result){
			$result = $loader->();
			#ссылаемся
			$self->_db->set_user($result);
		}
		return $result;
	};
	my $memcached = sub {
		$result = $self->_memcached->get_user($name) unless ($self->_refresh);
		unless($result){
			$result = $mysql->();
			$self->_memcached->set_user($result);
		}
		return $result;
	};
	
	return $memcached->();
}

sub _get_posts {
	my ($self, $ids) = @_;
	my @result;
	for (grep { $_ > 0 } map { $_ } split /,/, $ids){
		my $post = $self->_get_post($_);
		delete $post->{'id'};
		delete $post->{'comments'};
		push(@result, $post);
	}
	return \@result;
}

sub _get_post {
	my ($self, $id) = @_;
	my $result;

	my $loader = $self->_get_loader_post($id);

	my $mysql = sub {
		$result = $self->_db->get_post($id) unless($self->_refresh);
		unless($result){
			$result = $loader->();
			$self->_db->set_post($result);
		}
		return $result;
	};
	
	return $mysql->();
}

sub _get_commenters {
	my ($self, $id) = @_;
	my $result;

	my $loader = $self->_get_loader_post($id);

	my $mysql = sub {
		my $commenters = $self->_db->get_commenters($id) unless($self->_refresh);
		unless(@{$commenters}){
			$result = $loader->();
			$self->_db->set_post($result);
		} 
		else {
			$result->{'comments'} = $commenters;
		}
		return $result;
	};
	
	return $mysql->();
}

sub _get_user_post {
	my ($self, $post) = @_;
	my $author = $self->_get_post($post)->{'author'};
	return $self->_get_user($author);
}

sub _get_self_commentors {
	my $self = shift;

	my $mysql = sub{
		return $self->_db->get_self_commentors;
	};

	my $memcached = sub{
		my $result = $self->_memcached->get_self_commentors() unless($self->_refresh);
		unless($result){
			$result = $mysql->();
			$self->_memcached->set_self_commentors($result);
		}
		return $result;
	};
	
	return $memcached->();
}

sub _get_desert_posts {
	my ($self, $n) = @_;

	return $self->_db->get_desert_posts($n);
}

sub _get_loader_post {
	my ($self, $id) = @_;
	my $result;

	my $loader = sub {
		$result = $self->_loader->get_post($id);
		die "Post not found $id" unless $result;

		my @commenters;
		for my $name (@{$result->{'comments'}}) {
			my $user = $self->_get_user($name);
			if ($user) {
				push @commenters, $user;
				$self->_db->set_commenter($result, $user);
			}
		}
		$result->{'comments'} = \@commenters;
		$self->_memcached->del_self_commentors();
		return $result;
	};

	return $loader;
}

1;
