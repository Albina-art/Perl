package Local::Reducer::Sum;
# суммирует значение поля, указанного в параметре field конструктора, 
# каждой строки лога 
	use strict;
	use warnings;
	use parent 'Local::Reducer';

	sub _reduce {
		my ($self, $row) = @_;

		$self->{reduced} += $row->get($self->{field});
	}

1;