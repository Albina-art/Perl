package Local::Format;

use strict;
use warnings;

use JSON::XS;
use XML::Parser; 

our $VERSION = '1.00';

use Class::XSAccessor {
	accessors => [qw/
		_view_output
	/],
};

sub new {
	my ($class, $view_output) = @_;
	my $self = bless {}, $class;

	$self->_view_output($view_output);
	return $self;
}

sub get {
	my ($self, $data) = @_;
	
	return $self->_json ( $data )
	if ($self->_view_output eq 'json');
	
	return $self->_jsonl ( $data )
	if ($self->_view_output eq 'jsonl');
	
	die 'error view format';
}

sub _json {
	my ($self, $data) = @_;

	return JSON::XS->new->utf8->encode ( $data );
}

sub _jsonl {
	my ($self, $data) = @_;
	return _json($self, $data)
	if ref $data eq 'HASH';
	
	my @array = @$data;

	die 'not data'
	unless $array[0];

 	my $res = JSON::XS->new->utf8->encode ( shift @array) ;
 	map { $res .= "\n".JSON::XS->new->utf8->encode ($_)} @array ;
	return $res;
}

1;