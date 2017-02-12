package TrackAlbum::Track;
use Dancer2 appname => 'music_web';
use Dancer2;
use Dancer2::Plugin::Ajax;
use Digest::MD5 qw(md5_hex);
use Dancer2::Plugin::Database;
# quick_select
use Data::UUID;

use strict;
use warnings;
use utf8;
use Encode qw(decode_utf8);

our $VERSION = '0.1';

# join_type join table_name on condition ...
# Где join_type - результат,
# table_name - имя таблицы, которая присоединяется к результату, 
# condition - условие объединения таблиц.

sub error_404 {
	my $path = shift;
	status 404;
	return "page not exist: $path";
}
prefix undef; 

ajax '/delete/:id' => sub {
	my $track = database->selectrow_hashref(
							'SELECT track.* FROM track 
							 JOIN album ON album.id = track.album_id
							 WHERE track.id = ? AND album.user_id = ?', {},
							params->{id}, session('user')->{id});
	# запрос SELECT выдаст таблицу track такую, что трек id == альбому id 
	if ( $track ) {
		database->quick_delete('track', {'id' => $track->{id}});
		return $track->{id};
	} 
	else { return 'error 404'; }
};

get '/track/list/:id' => sub {
	my $album = database->quick_select('album', {'id' => params->{id}});
	my $user_id = params->{id} ? params->{id} : session('user')->{id};
	my $user = database->quick_select('user', {'id' => $user_id});
	if ( $album ) {
		template 'track_list', {
			'user' => $user,
			'tracks' => database->selectall_arrayref (
				'SELECT * FROM track WHERE album_id = ? ORDER BY `name`',
				{ Slice => {} },
				params->{id}
			),
			'album' => $album,
			'current_user' => session('user'),
		};
	} 
	else { error_404(request->path); }
};

any ['get', 'post'] => '/track/update/:album_id/:id?' => sub {
	my $track;
	my $album_name;
	my $err;
	if ( params->{id} ) {
		$track = database->selectrow_hashref(
			'SELECT track.*, album.album_name FROM track 
			 JOIN album ON album.id = track.album_id
			 WHERE track.album_id = ? AND track.id = ? AND album.user_id = ?',
			 {},
			params->{album_id}, 
			params->{id}, 
			session('user')->{id}
		);
		error_404(request->path) unless $track;
		$album_name = $track->{album_name};
	} 
	else {
		my $album = database->quick_select('album', { 
			id => params->{album_id}, 
			user_id => session('user')->{id} 
		});
		error_404(request->path) unless $album;
		$album_name = $album->{album_name};
	}
	if(request->method() eq "POST"){
		$track->{name} = params->{name};
		$track->{format} = params->{format};
		$track->{album_id} = params->{album_id};
		$track->{image_http} = params->{image_http};
		$track->{old_file} = $track->{file};
		$track->{file} = params->{file};

		$err = track_inspect($track);

		unless($err) {
			redirect '/track/list/'.$track->{album_id} if track_save($track);
		}
	}
	$err = "ok" unless $err;
	template 'track_update',{
		'id' => params->{id},
		'album_name' => $album_name,
		'err' => $err,
		'track' => $track,
		'images_dir' => '/'.config->{files}->{dir}.'/',
	};
};
get '/uploads/:name' => sub {
	my $types = join '|', values %{config->{files}->{types}};
	if (params->{name} =~ m{^[\d\w_]+\.($types)$}s){
		my $dir = get_dir_files();
		my $path = path($dir, params->{name});

		if (-e $path) {
			return send_file($path, system_path => 1);
		}
	}
};
sub get_dir_files{
	my $dir = path(config->{appdir}, config->{files}->{dir});

	if(not -e $dir){
		mkdir $dir or die "Directory $dir cannot be created: ".decode_utf8($!);
	}
	return $dir;
}
sub track_save{
	my ($data) = @_;

	if($data->{file}){
		my $dir = get_dir_files();
		$data->{file} = $data->{album_id}.'_'.generate_file_name().'.'.get_file_suffix(request->upload('file')->type);
		my $path = path($dir, $data->{file});
		request->upload('file')->copy_to($path);
		if($data->{old_file}){
			$path = path($dir, $data->{old_file});
			unlink($path) if -e $path;
		}
	}

	my $result;
	if($data->{id}) {
		$result = database->quick_update('track', { id => $data->{id} }, { 
			name => $data->{name}, 
			format => $data->{format}, 
			album_id => $data->{album_id}, 
			image_http => $data->{image_http}, 
			file => $data->{file} });
	} 
	else { 
		$result = database->quick_insert('track', { 
			name => $data->{name}, 
			format => $data->{format}, 
			album_id => $data->{album_id}, 
			image_http => $data->{image_http}, 
			file => $data->{file} });
	}

	return $result;
}
sub track_inspect{
	my $data = shift;
	my %validated;
	my @cells = ("id", "name", "format", "image_http", "image");
	for  (@cells) {
		my $value = $data->{$_};
		if ($_ eq 'name' or $_ eq 'format'){
			unless ($value){
				return "Поле $_ не заполнено";
			}
		}
		if($_ eq 'image_http'){
			if ($value eq undef) {
				return "Поле $_ не заполнено";
			}
			else {
				unless($value =~ m{^$|^https?:\/\/[^&?]+\.(png|jpg|jpeg|svg|svgz|gif|tif|tiff|bmp|ico|wbmp|webp)$}s){
					return  "$_ не является корректной http(s) ссылкой";
				}
			}
		}
		if($_ eq 'file') {
			return "Невалидный формат" 
			unless ($value =~/mp3|m4r|wav|wma|ogg|aac|ape|flac/);
		}
	}

	return undef;
}
sub get_file_suffix{
	my $type = shift;
	return config->{files}->{types}->{$type};
}

sub generate_file_name{
	return md5_hex(Data::UUID->new->create_str());
}

true;