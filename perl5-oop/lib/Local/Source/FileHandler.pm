package Local::Source::FileHandler;
	use strict;
	use warnings;
	use DDP;
	use parent 'Local::Source';
sub new {
	print "sf";
    my ($class, %params) = @_;
    my $self = $class->SUPER::new(%params);
	$self->{counter}=0;
    # print $self->{fh};
    open(MYFILE,'<', $self->{fh}) || die;
    print $self->{fh}->[ $self->{counter}++ ] = <MYFILE>;
    return $self;
}

sub next {
	my $self = shift;
	# open(MYFILE,'+<', $self->{fh}) || die;
	print "nn";
	print $self->{fh} = <MYFILE>;
	chomp($self->{fh});
	print "$self->{counter} nn";
	return $self->{fh}->[ $self->{counter}++ ];
}

1;
	# sub start {
	# 	my $self = shift;
	# 	my @arr;
	# 	open(MYFILE, $self->{fh}) || die;
	# 	while(<MYFILE>){
	# 		chomp;
 #    		$self->{fh} .= $_;
	# 	}
	# 	$self->{counter} = 0;
	# 	# print $self->{source};
	# 	# print $self->{fh} =;
	# 	return $self;
	# }

	sub DESTROY {
		my ($self) = @_;
		close $self->{fh} if $self->{fh};
	}

1;
