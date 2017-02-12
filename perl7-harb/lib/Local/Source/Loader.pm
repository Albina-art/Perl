package Local::Source::Loader;
use parent 'Local::Source';

use strict;
use warnings;
use mro 'c3';

use Data::Dumper;
use HTML::TreeBuilder::XPath;
use LWP::UserAgent;

sub get_user {
	my ($self, $name) = @_;
	my %result;
	my $Data = $self->_get_data('users', $name);
	return undef unless($Data);

	$result{'username'} = $Data->findvalue('//a[@class = "author-info__nickname"]');

	$result{'karma'} = $Data->findvalue('//div[@class = "voting-wjt__counter-score js-karma_num"]');
	$result{'karma'} =~ s/,/./s;

	$result{'rating'} = $Data->findvalue('//div[@class = "statistic__value statistic__value_magenta"]');
	$result{'rating'} =~ s/,/./s;

	return \%result;
}

sub get_post {
	my ($self, $id) = @_;
	my %result;
	my @usernames;
	
	my $Data = $self->_get_data('post', $id);
	return undef unless($Data);

	$result{'id'} = $id;
	$result{'author'} = $Data->findvalue('//div[@class = "author-info "]//a[@class = "author-info__nickname"]');
	unless($result{'author'}) { 
		$result{'author'} = $Data->findvalue('//a[@class = "post-type__value post-type__value_author"]');
	}

	$result{'theme'} = ($Data->findvalues('//h1[@class = "post__title"]/span'))[1];
	$result{'count_view'} = $Data->findvalue('//div[@class = "views-count_post"]');
	$result{'count_star'} = $Data->findvalue('//span[@class = "favorite-wjt__counter js-favs_count"]');
	
	push @usernames, $_
	for ($Data->findvalues('//a[@class = "comment-item__username"]'));
	
	my %cnt; # будет содержать число повторений элементов
	@usernames = grep { ! $cnt{$_}++; } @usernames;
	$result{'comments'} = \@usernames;
	
	return \%result;
}

sub _get_data {
	my ($self, $url, $id) = @_;
	$url = "https://".$self->_site().".ru/$url/$id/";

	my $ua = LWP::UserAgent->new;
	my $decoded_content;
	my $response = $ua->get($url);
	
	die "error response" 
	unless $response->is_success; 
	
	$decoded_content = $response->decoded_content;

	$response = $ua->get($url); 
	$url = $response->request->uri;

	die 'error decoded_content' 
	unless $decoded_content;

	return HTML::TreeBuilder::XPath->new_from_content($decoded_content);
}

1;
