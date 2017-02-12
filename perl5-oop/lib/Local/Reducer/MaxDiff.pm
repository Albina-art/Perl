package Local::Reducer::MaxDiff;
# выясняет максимальную разницу между полями, 
# указанными в параметрах top и bottom конструктора, 
# среди всех строк лога
	use strict;
	use warnings;
	use parent 'Local::Reducer';
	use DDP;
	sub _reduce {
		my ($self, $row) = @_;		
		my $top = $row->get($self->{top});
		my $bottom = $row->get($self->{bottom});

		$self->{reduced} = $top - $bottom
		if ($top - $bottom > $self->{reduced});
	}

1;