package Local::TCP::Calc::Server::Queue;

use strict;
use warnings;

use 5.010;
use Mouse;
use POSIX;
use Thread::Queue;
use Local::TCP::Calc;
use DDP;
use Fcntl qw(:flock SEEK_END);

has f_handle       	=> (is => 'rw', isa => 'FileHandle');
has queue_filename 	=> (is => 'ro', isa => 'Str', default => '/tmp/local_queue.log'); #read-only 
has max_task       	=> (is => 'rw', isa => 'Int', default => 0);
has count    	=> (is => 'rw', isa => 'Int', default => 0);

sub init {
	# Подготавливаем очередь к первому использованию если это необходимо
	my $self = shift;
	open (my $fh, '>', $self->{queue_filename});# Очистка содержимого файла, Создание файла, если он не существует
    close $fh;
}

sub open {
	# Открваем файл с очередью, не забываем про локи, возвращаем содержимое (перловая структура)
	my $self = shift;
	my $open_type = shift;
	open($self->{f_handle}, '+<', $self->{queue_filename});
	my $fh = $self->{f_handle};
	flock($fh, LOCK_EX) # запрашивает блокировку для личного использования файла
	or do { close $fh; print "сannot lock $fh \n"; return ''};
	my $q = Thread::Queue->new; # Создает новую пустую очередь
	while ( <$fh> ) {
		chomp;
		$q->enqueue($_); # Добавляет список элементов в конец очереди
	}
	return $q;
}

sub close {
	# Перезаписываем файл с данными очереди (если требуется), снимаем лок, закрываем файл.
	my $self = shift;
	my $q = shift;
	my $fh = $self->{f_handle};
	seek( $fh, 0, 0); # переход в начало файла
	while(my $head = $q->dequeue_nb) { # dequeue_nb - Удаляет запрошенное количество элементов 
		# ( по умолчанию 1) из головы очереди, и возвращает их. 
		# Если очередь содержит меньше запрашиваемого количества элементов, 
		# то она немедленно (т.е. без блокировки) возвращает все элементы , 
		# в которых есть по очереди. Если очередь пуста, то undefвозвращается.
		print {$self->{f_handle}} $head . "\n";
	}
	flock($fh, LOCK_UN) # освобождает ранее запрошенную блокировку
	or do { print "сannot unlock $fh \n"};
	close $fh;
}

sub to_done {
	# Переводим задание в статус DONE, сохраняем имя файла с резуьтатом работы
	my $self = shift;
	my $task_id = shift;
	my $file_name = shift;
	my $q = $self->open;
	my $i = 0;
	my ($tmp, $elem);
	while ($elem = $q->peek($i++)) { 
		$tmp = Local::TCP::Calc::unpack_message($elem);
		last if $tmp->{id} and $tmp->{id} eq $task_id;
	}
	$q->extract($i - 1);
	$tmp->{status} = Local::TCP::Calc::STATUS_DONE;
	$q->insert($i - 1, Local::TCP::Calc::pack_message($tmp));

	$self->close($q);
}

sub get_status {
	# Возвращаем статус задания по id, и в случае DONE или ERROR имя файла с результатом
	my $self = shift;
	my $id = shift;
	my $q = $self->open;
	my $i = 0;
	my ($tmp, $elem);
	while($elem = $q->peek($i++)) {
		$tmp = Local::TCP::Calc::unpack_message($elem);
		last if $tmp->{id} and $tmp->{id} eq $id;
	}
	$self->close($q);
	
	return $tmp->{status};
}

sub delete {
	# Удаляем задание из очереди в соответствующем статусе
	my $self = shift;
	my $id = shift;
	my $status = shift;
	my $q = $self->open;
	my $i = 0;
	my ($tmp, $elem);
	while($elem = $q->peek($i++)) { # Возвращает элемент из очереди без извлечения из очереди.
		$tmp = Local::TCP::Calc::unpack_message($elem);
		if(	exists $tmp->{id} and $tmp->{id} eq $id and 
			exists $tmp->{status} and $tmp->{status} eq Local::TCP::Calc::STATUS_DONE()	) {
			last;
		}
	}
	return undef
	if $tmp->{status} and $tmp->{status} ne Local::TCP::Calc::STATUS_DONE;
	$self->{count}--;
	$q->extract($i);
	$self->close($q);
}

sub get {
	# Возвращаем задание, которое необходимо выполнить (id, tasks)
	my $self = shift;
	my $q = $self->open();
	my $i = 0;
	my ($tmp, $elem);
	while($elem = $q->peek($i++)) { # Возвращает элемент из очереди без извлечения из очереди.
		$tmp = Local::TCP::Calc::unpack_message($elem);
		last if $tmp->{status} and $tmp->{status} eq Local::TCP::Calc::STATUS_NEW;
	}
	return undef
	if $tmp and $tmp->{status} ne Local::TCP::Calc::STATUS_NEW;
	$q->extract($i - 1); # Удаляет и возвращает заданное количество элементов ( по умолчанию 1) 
	# из указанной позиции индекса в очереди (0 является руководителем очереди). 
	# При вызове без аргументов, extract действует так же , как dequeue_nb .
	$tmp->{status} = Local::TCP::Calc::STATUS_WORK();
	$tmp->{time} = time;
	$q->insert($i - 1, Local::TCP::Calc::pack_message($tmp)); # Вставка элементов в очереди позади i - 1
	$self->close($q);

	return $tmp->{id};
}

# Добавляем новое задание с проверкой, что очередь не переполнилась
sub add {
	my $self = shift;
	my $new_work = shift;
	my $id = $self->curr_id;
	return 0
	if $self->{count} > $self->{max_task};
	my $queue = $self->open();
	my $tmp = Local::TCP::Calc::pack_message({	
		id => $id, 
		status => Local::TCP::Calc::STATUS_NEW(),
		task => $new_work,
		time => time });
    $queue->enqueue($tmp);
	$self->close($queue);
    return $id;
}

sub curr_id {
	my $self = shift;
	my $q = $self->open;
	my ($id, $i) = (0, 0);
	my ($tmp, $elem);
	while($elem = $q->peek($i++)) { # Возвращает элемент из очереди без извлечения из очереди.
		$tmp = Local::TCP::Calc::unpack_message($elem);
		if(exists $tmp->{id} and $tmp->{id} > $id) {
			$id = $tmp->{id};
		}
	}
	$self->{count} = $i;
	$self->close($q);
	return $id + 1;
}

sub get_time {
	my $self = shift;
	my $id = shift;
	my $q = $self->open;
	my $i = 0;
	my ($tmp, $elem);
	while($elem = $q->peek($i++)) { # Возвращает элемент из очереди без извлечения из очереди.
		$tmp = Local::TCP::Calc::unpack_message($elem);
		last if $tmp->{id} and $tmp->{id} == $id;
	}
	$self->close($q);
	return time - $tmp->{time};
}

no Mouse;
__PACKAGE__->meta->make_immutable();

1;