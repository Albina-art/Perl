package Local::TCP::Calc::Server;

use warnings;
use strict;
use 5.010;
use Local::TCP::Calc;
use Local::TCP::Calc::Server::Queue;
use Local::TCP::Calc::Server::Worker;
use IO::Socket::INET;
use PerlIO::via::gzip;
use POSIX qw(:sys_wait_h);
use DDP;

my $max_worker;
my $in_process = 0;

my $pids_master = {};
my $work_count = 0;
my $receiver_count = 0;
my $max_forks_per_task = 0;

# Функция для обработки сигнала CHLD
sub REAPER {
	while(my $pid = waitpid(0, WNOHANG)){
		last if $pid == -1;
		$receiver_count--;
		$work_count--;
		if( WIFEXITED($?) ){
			my $status = $? >> 8;
			print "$pid eeexit with status $status $/";
		}
		else { print "Process $pid sleep $/" }
	}
};
$work_count = 0;
$SIG{CHLD} = \&REAPER;

# Начинаем accept-тить подключения
# Проверяем, что количество принимающих форков не вышло за пределы допустимого ($max_receiver)
# Если все нормально отвечаем клиенту TYPE_CONN_OK() в противном случае TYPE_CONN_ERR()
# В каждом форке читаем сообщение от клиента, анализируем его тип (TYPE_START_WORK(), TYPE_CHECK_WORK()) 
# Не забываем проверять количество прочитанных/записанных байт из/в сеть
# Если необходимо добавляем задание в очередь (проверяем получилось или нет) 
# Если пришли с проверкой статуса, получаем статус из очереди и отдаём клиенту
# В случае если статус DONE или ERROR возвращаем на клиент содержимое файла с результатом выполнения
# После того, как результат передан на клиент зачищаем файл с результатом
sub start_server {
	my ($pkg, $port, %opts) = @_;
	$max_worker         = $opts{max_worker} // die "max_worker required"; 
	my $max_queue_task 	= $opts{max_queue_task} // die "max_worker required"; 
	$max_forks_per_task = $opts{max_forks_per_task} // die "max_forks_per_task required";
	my $max_receiver    = $opts{max_receiver} // die "max_receiver required"; 
	unlink glob "exampl/* exampl/.*"; 
	rmdir("exampl");
	mkdir("exampl");
	# auto-flush on socket
	$| = 1;
	# Инициализируем сервер my $server = IO::Socket::INET->new(...);
	my $socket = new IO::Socket::INET (
		LocalHost => '127.0.0.1',
		LocalPort => $port,
		Proto => 'tcp',
		Listen => 5,
		Reuse => 1
	);
	die "cannot create socket $!\n" unless $socket;
	# Инициализируем очередь my $q = Local::TCP::Calc::Server::Queue->new(...);
	my $q = Local::TCP::Calc::Server::Queue->new(max_task => $max_queue_task);
	$q->init();
	# print "dsd","\n";
	# Начинаем accept-тить подключения
	while(1) {
		next unless defined (my $client_socket = $socket->accept ) ;
		# получаем информацию о новом подключении клиента
		my $client_address = $client_socket->peerhost;
		my $client_port = $client_socket->peerport;
		# Проверяем, что количество принимающих форков не вышло за пределы допустимого ($max_receiver)
		if($receiver_count >= $max_receiver) {
			my $type = Local::TCP::Calc::TYPE_CONN_ERR();
			$client_socket->send($type);
			$client_socket->close;
			next;
		}
		$receiver_count++;
		if (!fork) {
			$SIG{CHLD} = \&REAPER;
			my $exampl_client;
			my $type = Local::TCP::Calc::TYPE_CONN_OK;
			$client_socket->send($type);
			my $message = Local::TCP::Calc::get_data($client_socket);
			if ($message) {
				if($message->{type} == Local::TCP::Calc::TYPE_START_WORK) {
					my $id_add = $q->add($message->{data});
					push (@$exampl_client, $id_add);
					check_queue_workers($q, Local::TCP::Calc::unpack_message($message->{data})) if $id_add;
				} 
				if($message->{type} == Local::TCP::Calc::TYPE_CHECK_WORK) {
					my $id = Local::TCP::Calc::unpack_message($message->{data})->[0];
					my $status = $q->get_status($id);
					push @$exampl_client, $status;
					push (@$exampl_client, $q->get_time($id)) 
					if $status == Local::TCP::Calc::STATUS_NEW or $status == Local::TCP::Calc::STATUS_WORK;
					if($status == Local::TCP::Calc::STATUS_DONE or $status == Local::TCP::Calc::STATUS_ERROR) {
						# open( my$fh, "<:via(gzip)", 'stdout.gz' );
						open(my $fh, '<', "exampl/$id");
						while (<$fh>) {
							chomp;
							push @$exampl_client, $_;
						}
						close $fh;
						unlink "exampl/$id" or die "Can't unlink exampl/$id $!"; #получает список имен файлов и возвращает количество успешно удаленных файлов
						$q->delete($id);
					}
			 	}
				Local::TCP::Calc::send_data($client_socket, Local::TCP::Calc::pack_message($exampl_client), 1);
				$client_socket->close;
			}
			exit;
		}
	}
	$socket->close;
}

sub check_queue_workers {
	# Функция в которой стартует обработчик задания
	# Должна следить за тем, что бы кол-во обработчиков не превышало мексимально разрешённого ($max_worker)
	# Но и простаивать обработчики не должны
	# my $worker = Local::TCP::Calc::Server::Worker->new(...);
	# $worker->start(...);
	# $q->to_done ...
	my $q = shift;
	my $tasks = shift;
	my $id;
	if($work_count <= $max_worker and defined ($id = $q->get)) {
		$work_count++;
		if(!fork) {
			my $worker = Local::TCP::Calc::Server::Worker->new(
				cur_task_id => $id, 
				max_forks => $max_forks_per_task);
			$worker->start($tasks);
			$q->to_done($id, 'filename');
			exit;
		}
	}
}

1;