package Local::Source::MySQL;
use parent 'Local::Source';

use strict;
use warnings;

use strict;
use warnings;
use mro 'c3';
use DDP;

use Data::Dumper;
use DBI;
use Encode qw(encode);

use Class::XSAccessor {
	accessors => [qw/
		_connection
	/],
};

sub get_user{

	my ($self, $name) = @_;
	return $self->connection->selectrow_hashref(
		'SELECT uname as username, karma, rating FROM user WHERE uname = ?',
		{}, $name
	) if $name;
	# Он возвращает ссылку на содержащий ссылки на хэш для каждой строки
	# выбранных данных
	return undef;
}

sub get_post{
	my ($self, $id) = @_;

	return $self->connection->selectrow_hashref(
		'SELECT author, theme, count_view, count_star FROM post WHERE id_post = ?',
		{}, $id
	) if $id;
	# он возвращает ссылку на , содержащий ссылки на хэш для каждой строки
	# выбранных данных
	return undef;
}

sub get_commenters{
	my ($self, $id) = @_;

	return $self->connection->selectall_arrayref(
		'SELECT uname as username, karma, rating FROM user
		JOIN commenter USING(id_user) WHERE id_post = ?',
		{ slice => {} }, $id
	) if ($id);
	# Он возвращает ссылку на массив, содержащий ссылки на массивы для каждой строки
	# выбранных данных

	return undef;
}

sub get_self_commentors {
	my ($self) = @_;
	return $self->connection->selectall_arrayref(
		'SELECT uname as username, karma, user.rating FROM commenter 
			JOIN user USING(id_user)
			JOIN post USING(id_post)
			WHERE author = uname',
		{ slice => {} }
	);
}

sub get_desert_posts {
	my ($self, $n) = @_;

	return $self->connection->selectall_arrayref(
		'SELECT author, theme, count_view, count_star FROM commenter 
			JOIN user USING(id_user)
			JOIN post USING(id_post)
			GROUP BY id_post
			HAVING COUNT(*) < ?',
		{ slice => {} }, $n
	) if $n;

	return undef;
}
sub _utf {
	my $data = shift;
	$data = encode("utf-8","$data")
	if (utf8::is_utf8($data) == 1);
	$data =~ s/–/-/;
	return $data;
}

sub set_user {
	my ($self, $data) = @_;
	$data->{'karma'} = _utf($data->{'karma'});
	$data->{'rating'} = _utf($data->{'rating'});
	return $self->connection->prepare(
		'INSERT INTO user (uname, karma, rating, last_update) VALUES (?,?,?,NOW())
		ON DUPLICATE KEY UPDATE karma=?, rating=?, last_update=NOW()'
	)->execute(
		$data->{'username'}, 
		$data->{'karma'}, 
		$data->{'rating'},
		$data->{'karma'}, 
		$data->{'rating'}
	) 
	if $data->{'username'};
	# Подготавливает одну команду для выполнения ядром базы данных в будущем и возвращает
	# ссылку на объект дескриптора команды. 
}

sub set_post{
	my ($self, $data) = @_; 
	return $self->connection->prepare(
		'INSERT INTO post (id_post, author, theme, count_view, count_star, last_update) VALUES (?,?,?,?,?,NOW())
		ON DUPLICATE KEY UPDATE author=?, theme=?, count_view=?, count_star=?, last_update=NOW()'
	)->execute(
		$data->{'id'}, 
		$data->{'author'}, 
		$data->{'theme'}, 
		$data->{'count_view'}, 
		$data->{'count_star'},
		$data->{'author'}, 
		$data->{'theme'}, 
		$data->{'count_view'}, 
		$data->{'count_star'}
	) if($data->{'id'});
	# prepare - подготавливает
	# execute - приводит в действие
}

sub set_commenter{
	my ($self, $post, $user) = @_;

	return $self->connection->prepare(
		'INSERT IGNORE INTO commenter (id_post, id_user) VALUES (?, (SELECT id_user FROM user WHERE uname=?))'
	)->execute(
		$post->{'id'}, $user->{'username'}
	) if $post->{'id'} and $user->{'username'};
}

sub _connection_start{
	my ($self, $conf) = @_;

	return DBI->connect(
		'dbi:mysql:database='.$conf->val('DB','db_name'), $conf->val('DB','db_user'), $conf->val('DB','db_pass'),
		{ 	
			RaiseError => 1, 
			mysql_enable_utf8 => 1 
		}
	);
	die "Can't connection to database" ;
}

sub _initialization {
	my $self = shift;
	 $self->connection->do('CREATE TABLE IF NOT EXISTS `user` (
	  `id_user` int(11) NOT NULL AUTO_INCREMENT,
	  `uname` varchar(100) NOT NULL,
	  `karma` double(10,1) NOT NULL,
	  `rating` decimal(10,1) NOT NULL,
	  `last_update` datetime NOT NULL,
	  PRIMARY KEY (`id_user`),
	  UNIQUE KEY `uname` (`uname`)
	) ENGINE=InnoDB  DEFAULT CHARSET=utf8;')
}

1;

