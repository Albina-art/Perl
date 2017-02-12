package Local::TCP::Calc::Client;

use 5.010;
use strict;
use IO::Socket;
use Local::TCP::Calc;
use DDP;

sub set_connect {
	# Прочитать заголовок, прежде чем прочитать сообщение	
	# Проверить на ошибку Local :: TCP :: Calc :: TYPE_CONN_ERR ();
	my ($pkg, $ip, $port) = @_;
	my $socket = new IO::Socket::INET (
	    PeerAddr => $ip,
	    PeerPort => $port,
	    Proto => 'tcp') 
	or die "Can't create server on port $port : $@ $/";
	$socket->recv(my $message, 1);
	die "error connect socket $!" 
	if $message == Local::TCP::Calc::TYPE_CONN_ERR();

	return $socket;
}

sub do_request {
	# Принимаем и возвращаем перловые структуры
	my $pkg = shift;
	my $server = shift;
	my $type = shift;
	my $message = shift;
	my $msg = Local::TCP::Calc::pack_message($message);
	Local::TCP::Calc::send_data($server, $msg, $type); 
	# Проверка, что записанное/прочитанное количество байт 
	# равно длинне сообщения/заголовка
	my $struct = Local::TCP::Calc::get_data($server);

	return @{ Local::TCP::Calc::unpack_message( $struct->{data} ) };
}


1;

