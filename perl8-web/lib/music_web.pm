package music_web;
use TrackAlbum::Album;
use TrackAlbum::Track;

use Dancer2;
use Dancer2::Plugin::Database;

use strict;
use warnings;
use utf8;

use Digest::MD5 qw(md5_hex);
use Data::UUID;

our $VERSION = '0.1';
# get возваращает какие-то данные
# post загрузить картинку, создание нового контента
get '/' => sub {
	my $user_id = params->{id} || session('user')->{id};
	my $user = database->quick_select('user', {'id' => $user_id});
	if($user){
		template 'album_list', {
			'albums' => database->selectall_arrayref(
				'SELECT * FROM album WHERE user_id = ? ORDER BY `album_name`',
				{ Slice => {} },
				$user_id
			),
			'user' => $user,
			'current_user' => session('user'),
		};
	} 
};

hook before => sub{
	if (!session('user') && request->dispatch_path !~ m{^/(login|registration)$}){
		forward '/login', {path => request->path};
	}
};

any ['get', 'post'] => '/login' => sub {
	my $err = "ok";

	if(request->method() eq "POST"){
		if(params->{login} && params->{password}){
			my $user = database->quick_select('user', 
				{ login => params->{login}, password => passw(params->{password}) });
			set_user_and_redirect($user, params->{path}) if($user);
			$err = 'Ошибка в логине или пароле';
		} else
		{
			$err = 'Логин или пароль пусты';
		}
	}
	template 'login', {
		'meth' => request->method(),
		'err' => $err,
		'path' => params->{path},
		'login' => params->{login}
	};
};

any ['get', 'post'] => '/registration' => sub {
	my $err;

	if(request->method() eq "POST"){
		my $h_errors = {
			'Логин или пароль пусты' => sub{
				params->{login} && params->{password}
			},
			'Пароль не совпадает' => sub{
				params->{password} eq params->{password2}
			},
			'Пароль должен быть больше 4х символов' => sub{
				length(params->{password}) > 4
			},
		};

		$err = form_inspect( $h_errors );
		unless($err){
			my $user = database->quick_select('user', 
				{ login => params->{login}});
			unless($user){
				my $result = database->quick_insert('user', 
					{ login => params->{login}, password => passw(params->{password}), name => params->{name} });
				if($result){
					$user = database->quick_select('user', 
						{ login => params->{login}, password => passw(params->{password})});
					set_user_and_redirect($user, params->{path}) if $user;
				} 
				else {
					$err = 'Не удалось зарегистрировать!!!';
				}
				$err = 'Не удалось войти!!!';
			}

			$err = 'А такой логин уже есть';
			params->{login} = '';
		}
	}
	unless ($err) { $err = "ok"; }
	template 'registration', {
		'err' => $err,
		'path' => params->{path},
		'login' => params->{login},
		'name' => params->{name},
	};
};

get '/logout' => sub {
	app->destroy_session;
	redirect '/login';
};

get '/user_list' => sub {
	template 'user_list', {
		'users' => database->selectall_arrayref(
						'SELECT id, login FROM user',
						{ Slice => {} }
					)
	};
};

any ['get', 'post'] => '/user_delete' => sub {
	if(request->method() eq "POST"){
		if(session('token') && session('token') eq params->{token}){
			database->quick_delete('user', {'id' => session('user')->{id}});
			app->destroy_session;
			redirect '/login';
		}
	}

	my $token;
	if(session('token')){
		$token = session('token');
	} else{
		$token = generate_token();
		session token => $token;
	}

	template 'user_delete',{
		'token' => $token
	};
};

get '/user/:id' => sub{
	forward '/', {id => params->{id}, path => request->path};
};

sub passw {
	my $password = shift;
	return md5_hex(config->{password_salt}.$password);
};

sub set_user_and_redirect{
	my ($user, $path) = @_;

	session user => $user;

	redirect $path if ($path && $path ne '/logout');
	redirect '/';
};

sub generate_token{
	return Data::UUID->new->create_str();
}

sub form_inspect {
	my $h_errors = shift;

	for (keys %$h_errors) {
		if($_){
			return ( undef, $_ ) unless ($h_errors->{$_}->());
		}
	}
	return undef ;
}

true;

