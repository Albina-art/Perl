package Local::Reducer::MinMaxAvg;
# считает минимум, максимум и среднее по полю, 
# указанному в параметре field. Результат (reduced) 
# отдается в виде объекта с методами get_max, get_min, get_avg.
use strict;
use warnings;
use parent 'Local::Reducer'; 
use List::Util qw(max min sum);

    sub new {
        my ($class, %params) = @_;
        my $self = $class->SUPER::new(%params);
        $self->{value} = [];
        return $self;
    }
    sub _reduce {
        my ($self, $row) = @_;
         push (@{$self->{value}}, 
        	$row->get($self->{field}));
        return $self->{reduced};
    }
    sub get_min {
        my $self = shift;
        return min(@{$self->{value}});
    }    
    sub get_max {
        my $self = shift;
        return max(@{$self->{value}});
    }
    sub get_avg {
        my $self = shift;
        return sum(@{$self->{value}}) / scalar(@{$self->{value}});
    }

1;
