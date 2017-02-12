package Local::TCP::Calc;

use strict;
use warnings;
use IPC::Run3;
use CBOR::XS;
use IO::File;

sub TYPE_START_WORK {1}
sub TYPE_CHECK_WORK {2}
sub TYPE_CONN_ERR   {3}
sub TYPE_CONN_OK    {4}
sub HEAD_SIZE 		{32}

sub STATUS_NEW   {1}
sub STATUS_WORK  {2}
sub STATUS_DONE  {3}
sub STATUS_ERROR {4}

# recv SOCKET, SCALAR, LEN, FLAGS
# Функция осуществляет прием сообщения из гнезда. 
# Предпринимает попытку принять LENGTH байтов данных
# из гнезда SOCKET, а затем поместить их в переменную SCALAR. 
# Представляет собой оболочку для системного вызова recvfrom, 
# а поэтому может при необходимости возвращать адрес отправителя. 
# В случае ошибки возвращаемое значение не определено. 
# Размер памяти, занимаемой переменной SCALAR, 
# автоматически подстраивается под объем считанных данных. 
# Функция принимает тот же набор флагов, что и одноименный системный вызов.

# Для отправки сообщения через сокет служит функция send:
# send (SOCK, "То что шлем",	 0);

sub get_data {
	my $socket = shift;
	$socket->recv(my $head, HEAD_SIZE()); # получили сообщение
	my $header = unpack_header($head); # распознали
	if ($head) {
		die "error length head = 0" 
		if (length($head) == 0);
	}
	else { return ''} # ой пусто
	$socket->send(' ');	# отправили сообщение 
	$socket->recv(my $data, $header->{size}); 
	die "error get_data recv: $!" 
	if $header->{size} != length $data;
	my $message = {
		type => $header->{type}, 
		data => $data};
	return $message;
}

sub send_data {
	my ($socket, $message, $type) = @_;
	$socket->send(pack_header($type, length $message));
	$socket->recv(my $send, 1); # принели сообщение длины 1
	if($socket->send($message) != length $message) {
		die "error send_data: $!";
	}
}

sub pack_header {
	my $type = shift;
	my $size = shift;

	return pack('VV', $type, $size);
}

sub unpack_header {
	my $pkg = shift;
	my $header;
	( $header->{type}, $header->{size} ) = 
	unpack ('VV', $pkg);

	return $header;	
}

sub pack_message {
	my $message = shift;
	
	return CBOR::XS::encode_cbor($message);
}

sub unpack_message {
	my $message = shift;
	return undef if $message eq '';
	return CBOR::XS::decode_cbor($message);
}

sub calc {
	my $stdtask = shift;
	my $file = 'lib/Local/calculator/bin/calculator';
	$| = 1; 
	# Обычно данные, выводимые в файл функциями print или write, 
	# предварительно помещаются в буфер. Когда буфер заполняется, 
	# его содержимое записывается в файл. 
	# Буферизация повышает эффиктивность операций вывода. 
	# По умолчанию Perl использует буферизацию для каждого выходного файла, 
	# что ссответствует нулевому значению переменной $|. 
	# Чтобы ее отменить, следует выбрать файл при помощи функции select 
	# и установить значение переменной $| не равным 0.
	my ($stdout, $stderr);
	run3 ($file, \$stdtask, \$stdout, \$stderr);
	return $stdout;
}

1;