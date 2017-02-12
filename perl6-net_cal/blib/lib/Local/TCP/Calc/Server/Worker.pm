package Local::TCP::Calc::Server::Worker;

use 5.010;
use strict;
use warnings;
use POSIX;
use Mouse;
use Fcntl qw(:flock SEEK_END);

has cur_task_id => (is => 'ro', isa => 'Int');
has max_forks   => (is => 'ro', isa => 'Int', default => 1);
has cur_forks 	=> (is => 'ro', isa => 'Int', default => 0);
has forks       => (is => 'rw', isa => 'HashRef', default => sub {return {}});

# sub child_fork {
# 	# Обработка сигнала CHLD, не забываем проверить статус завершения процесс 
# 	# и при надобности убить оставшихся
# 	my $self = shift;
# 	$self->{cur_forks}--;
# }
# $SIG{CHLD} = \&child_fork;
sub child_fork {
	my $self = shift;
	my $file = "file_" . $self->cur_task_id . ".txt";
	while ( my $pid = waitpid(-1, WNOHANG) ) {
		last if $pid == -1;
		if( WIFEXITED($?) ) {
			my $status = $? >> 8;
			if ($status != 0) {
				for (values %{$self->{forks}}) {
					kill 9, $_;
				}
				unlink $file;
				$self->write_err("ANY ERROR");
				#TODO: print error;
				return "error_" . $self->cur_task_id . ".txt";
			}
		}
		else { 
			#print "Process $pid sleep $/" 
		} 
	}
	return $file;
	# Обработка сигнала CHLD, не забываем проверить статус завершения процесс и при надобности убить оставшихся
}

sub write_res {
	# Записываем результат выполнения задания
	my ($self, $task, $res) = @_;
	open (my $fh,"+>>", "exampl/$self->{cur_task_id}"); # присоединение, создание файла, при записи переход в конец файла
	flock($fh, LOCK_EX) # запрашивает блокировку для личного использования файла
	or do { close $fh; print "сannot lock $fh \n"; return ''};
	print $fh "$res\n";
	flock($fh, LOCK_UN) # освобождает ранее запрошенную блокировку
	or do { close $fh; print "сannot unlock $fh \n"};
	close $fh;
}


sub calc_res {
	# Начинаем выполнение задания. Форкаемся на нужное кол-во форков для обработки массива примеров
	# В форках записываем результат в файл, не забываем про локи, чтобы форки друг другу не портили результат
	my ($self, $tasks) = @_;
	if ( !fork ) {
		for (@$tasks) {
			my $res = Local::TCP::Calc::calc($_);
			$self->write_res($_, $res);
		}
	}

}
sub start {
	my ($self, $tasks) = @_;
	my @fork_tasks;
	push (@fork_tasks, $_)
	for (@$tasks);
	$self->calc_res(\@fork_tasks);
	while ( wait != -1) { } # Ожидает завершение порожденного процесса 
	# и возвращает идентификатор завершенного порожденного процесса 
	# или -1 в случае, если порожденных процессов не существует.
	# Вызов блокирующий, ждём  пока не завершатся все форки
}

# Начинаем выполнение задания. Форкаемся на нужное кол-во форков для обработки массива примеров
# Вызов блокирующий, ждём  пока не завершатся все форки
# В форках записываем результат в файл, не забываем про локи, чтобы форки друг другу не портили результат

no Mouse;
__PACKAGE__->meta->make_immutable();

1;

# sub start {
# # 	my ($self, $tasks) = @_;
# # 	my @fork_tasks;
# # 	push (@fork_tasks, $_)
# # 	for (@$tasks);
# # 	$self->calc_fork(\@fork_tasks);
# # 	while ( wait != -1) { } # Ожидает завершение порожденного процесса 
# # 	# и возвращает идентификатор завершенного порожденного процесса 
# # 	# или -1 в случае, если порожденных процессов не существует.
# # 	# Вызов блокирующий, ждём  пока не завершатся все форки
# 		my $self = shift;
# 	my $task = shift;
# 	my @tasks = @$task;
# 	my ($div, $mod) = (scalar(@tasks) / $self->{max_forks},
# 	 scalar(@tasks) % $self->{max_forks});
# 	for my $i (0..$self->{max_forks}) {
# 		my $len = $div + (($i < $mod) ? 1 : 0);
# 		next unless $len;
# 		my @per_task = ();
# 		push @per_task, shift (@tasks) for (0..$len);
# 		my $child = fork();
# 		if ($child) { 
# 			$self->forks->{"$i"}  = $child;
#             $SIG{CHLD} = \$self->child_fork();
# 		}
# 		if (defined $child) {
# 			for (@per_task) {
# 				my $res = Local::TCP::Calc::calc($_);
# 				$self->write_res($_, $res);
# 			}		
# 			exit;
# 		} else {
# 			die "Can't fork"; 
# 		}
# 	}
# 	return $self->child_fork();
# 	# Начинаем выполнение задания. Форкаемся на нужное кол-во форков для обработки массива примеров
# 	# Вызов блокирующий, ждём  пока не завершатся все форки
# 	# В форках записываем результат в файл, не забываем про локи, чтобы форки друг другу не портили результат
# 	#return file
# }

# no Mouse;
# __PACKAGE__->meta->make_immutable();

# 1;
