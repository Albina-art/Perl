package Local::Source;

use strict;
use warnings;
use Path::Class qw( file );
use Config::IniFiles;
use Cwd;

use Class::XSAccessor {
	accessors => [qw/
		_site _connection
	/],
};

sub new {
	my ($class, %params) = @_;
	my $self = bless {}, $class;

	$self->_site($params{'site'});
	return $self;
}

sub connection {
	my $self = shift;

	unless($self->_connection){
		my $conf_file = cwd.'/bin/config.ini'; 
		my $conf = Config::IniFiles->new(-file => $conf_file);
		# Возвращает новый объект конфигурации
		die "configuration file has an error"
		unless $conf;
		$self->_connection($self->_connection_start($conf));
	}

	$self->_connection;
}


1;
