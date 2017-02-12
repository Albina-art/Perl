package TrackAlbum::Album;
use Dancer2 appname => 'music_web';

use Dancer2::Plugin::Database;

use strict;
use warnings;
use utf8;

use Digest::MD5 qw(md5_hex);
use Data::UUID;

our $VERSION = '0.1';
# get возваращает какие-то данные
# post загрузить картинку, создание нового контента
sub error_404 {
	my $path = shift;
	status 404;
	return "page not exist: $path";
}
sub album_inspect{
	my $data = shift;
	my $empty;
	my @cells = ("album_name", "year", "band_name");	
	for  (@cells) {
		my $value = $data->{$_};
		if ($value eq undef) {
			$empty .= "Название " if ($_ eq "album_name");
			$empty .= "Группа " if ($_ eq "band_name");
			$empty .= "Год " if($_ eq 'year');
		}
		elsif( $_ eq 'year') {
			unless ($value =~ /(19[0-9][1-9]|20[0-1][0-7])/) {
				return "Год выходит из диапозона 1901-2017";
			}
		}
	}
	return "$empty- отсутствует" if $empty;
}

sub album_save {
	my $data = shift;
	my $result;
	if( $data->{id} ) {
		$result = database->quick_update('album', { id => $data->{id} }, { 
			album_name => $data->{album_name}, 
			year => $data->{year}, 	
			band_name => $data->{band_name} 
		});
	} 
	else { 
		$result = database->quick_insert('album', { 
			album_name => $data->{album_name}, 
			year => $data->{year}, 
			band_name => $data->{band_name}, 
			user_id => session('user')->{id} 
		});
	}
	return $result;
}
prefix undef;

any ['get', 'post'] => '/album/update/:id?' => sub {
	my $album;
	my $err;
	if( params->{id} ){
		$album = database->quick_select('album', { 
			id => params->{id},
			user_id => session('user')->{id} 
		});
		error_404(request->path) unless $album;
	}
	if (request->method() eq "POST") {
		$album->{album_name} = params->{album_name};
		$album->{year} = params->{year};
		$album->{band_name} = params->{band_name};
		$err  = album_inspect($album);
		unless ($err) {
			redirect '/' if album_save( $album );
		}
	}
	$err = "ok" unless $err;
	template 'album_update',{
		'err' => $err,
		'album' => $album,
	};
};

any ['get', 'post'] => '/album/parse' => sub {
	my $err;
	my $album_id;
	if(request->method() eq "POST" and params->{text}){
		my $i = 0;
		for my $row (split("\n", params->{text})) {
			if ($i == 1){
				my @pars = split '\|', $row;
				my ($band, $year, $album_name, $track_name, $format) = @pars[1..5];
				database->begin_work;
				my $album = database->quick_select('album', {
					'year' => $year, 'album_name' => $album_name, 'band_name' => $band, 'user_id' => session('user')->{id}
				});
				unless($album){
					$album = database->quick_insert('album', {
						'year' => $year, 'album_name' => $album_name, 'band_name' => $band, 'user_id' => session('user')->{id}
					});
					$album_id = database->last_insert_id(undef, undef, 'album', 'id');
				} else{
					$album_id = $album->{id};
				}
				my $track = database->quick_select('track', {
					'name' => $track_name, 'format' => $format, 'album_id' => $album_id
				});
				unless($track){
					$track = database->quick_insert('track', {
						'name' => $track_name, 'format' => $format, 'album_id' => $album_id
					});
				}
				database->commit;
				$i = 0;
			}
			else { $i = 1; }
		}
	}
	elsif(params->{text} eq '' and request->method() eq "POST" ){ $err = " Поле текст пусто !!!"; }

	$err = "ok" unless ($err);
	template 'album_parse',{
		'err' => $err,
	};
};

true;